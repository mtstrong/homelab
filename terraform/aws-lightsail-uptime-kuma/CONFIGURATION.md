# Uptime Kuma Configuration Management for Lightsail

Since Lightsail containers use ephemeral storage, configuration management is even more critical.

## Approaches for Lightsail

### 1. Custom Docker Image (Recommended)

Create a custom image with your pre-configured database:

```dockerfile
FROM louislam/uptime-kuma:latest

# Copy pre-configured database
COPY kuma.db /app/data/kuma.db

# Set proper ownership
USER root
RUN chown -R node:node /app/data
USER node
```

Build and push to a registry (Docker Hub, ECR, etc.):

```bash
# Build the image
docker build -t your-username/uptime-kuma-configured:latest .

# Push to Docker Hub
docker login
docker push your-username/uptime-kuma-configured:latest

# Or push to AWS ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
docker tag your-username/uptime-kuma-configured:latest <account>.dkr.ecr.us-east-1.amazonaws.com/uptime-kuma:configured
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/uptime-kuma:configured
```

Update your `terraform.tfvars`:

```hcl
uptime_kuma_image = "your-username/uptime-kuma-configured:latest"
# or
uptime_kuma_image = "<account>.dkr.ecr.us-east-1.amazonaws.com/uptime-kuma:configured"
```

### 2. Environment Variables

Uptime Kuma has limited environment variable support, but you can use them for basic settings:

Update `main.tf`:

```hcl
environment = {
  UPTIME_KUMA_PORT           = "3001"
  UPTIME_KUMA_DISABLE_FRAME_SAMEORIGIN = "false"
  # Add other supported env vars
}
```

### 3. External Database

Use Lightsail managed database (MySQL/PostgreSQL) for persistent storage:

1. Create a Lightsail managed database
2. Configure Uptime Kuma to use external database (requires code modification)
3. Store connection details in environment variables

Add to `main.tf`:

```hcl
# Create Lightsail managed database
resource "aws_lightsail_database" "uptime_kuma" {
  relational_database_name = "uptime-kuma-db"
  relational_database_blueprint_id = "mysql_8_0"
  relational_database_bundle_id = "micro_1_0"
  master_database_name = "uptimekuma"
  master_username = "admin"
  master_password = var.db_password  # Use Secrets Manager in production
}

# Update container environment
environment = {
  DB_TYPE     = "mysql"
  DB_HOST     = aws_lightsail_database.uptime_kuma.master_endpoint_address
  DB_PORT     = aws_lightsail_database.uptime_kuma.master_endpoint_port
  DB_NAME     = "uptimekuma"
  DB_USER     = "admin"
  DB_PASSWORD = var.db_password  # Use Secrets Manager in production
}
```

**Note**: This requires a modified Uptime Kuma that supports external databases.

### 4. Post-Deployment Configuration Script

Run a configuration script after deployment:

```bash
#!/bin/bash
# configure-lightsail.sh

LIGHTSAIL_URL=$(terraform output -raw uptime_kuma_url)

# Wait for service to be ready
echo "Waiting for Uptime Kuma to be ready..."
until curl -sf "$LIGHTSAIL_URL" > /dev/null; do
  sleep 10
done

# Configure via API (similar to ECS script)
export UPTIME_KUMA_URL="$LIGHTSAIL_URL"
export ADMIN_USERNAME="admin"
export ADMIN_PASSWORD="your-secure-password"

# Run configuration
bash configure-uptime-kuma.sh
```

## Configuration Workflow

### Initial Setup

1. **Create base configuration locally**:
   ```bash
   docker run -d -p 3001:3001 -v uptime-kuma:/app/data --name uptime-kuma louislam/uptime-kuma:latest
   ```

2. **Configure via web UI**:
   - Create admin account
   - Add monitors
   - Configure notifications
   - Set up status pages

3. **Export database**:
   ```bash
   docker cp uptime-kuma:/app/data/kuma.db ./kuma.db
   ```

4. **Build custom image**:
   ```bash
   cat > Dockerfile <<EOF
   FROM louislam/uptime-kuma:latest
   COPY kuma.db /app/data/kuma.db
   USER root
   RUN chown -R node:node /app/data
   USER node
   EOF
   
   docker build -t your-username/uptime-kuma-configured:latest .
   docker push your-username/uptime-kuma-configured:latest
   ```

5. **Deploy to Lightsail**:
   ```bash
   # Update terraform.tfvars
   uptime_kuma_image = "your-username/uptime-kuma-configured:latest"
   
   terraform apply
   ```

### Updating Configuration

Since Lightsail is ephemeral:

1. Pull current configuration (if needed)
2. Make changes locally
3. Rebuild custom image
4. Update Terraform and redeploy

Or use the API approach for minor changes.

## Configuration Files

### monitors.json

```json
[
  {
    "name": "My Website",
    "type": "http",
    "url": "https://example.com",
    "interval": 60
  }
]
```

### Dockerfile for Custom Image

```dockerfile
FROM louislam/uptime-kuma:latest

# Copy pre-configured database
COPY kuma.db /app/data/kuma.db

# Optional: Copy additional files
# COPY custom-logo.png /app/data/upload/

# Set proper ownership
USER root
RUN chown -R node:node /app/data
USER node

# Health check
HEALTHCHECK --interval=60s --timeout=5s --start-period=60s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3001/ || exit 1
```

## Limitations

- **No persistent storage**: Configuration lost on restart/redeploy
- **Custom image required**: Most reliable approach needs Docker image maintenance
- **Limited env var support**: Not all settings configurable via environment
- **API access needed**: For programmatic configuration updates

## Best Practices

1. **Version Control**: Keep your kuma.db in private Git repo (encrypted)
2. **Image Registry**: Use private ECR or Docker Hub private repo
3. **Secrets**: Never commit passwords; use AWS Secrets Manager
4. **Backup Strategy**: Regularly export and version your database
5. **Documentation**: Keep track of manual configurations

## Alternative: Use ECS Instead

If you need true persistent configuration, consider using the ECS setup with EFS, which provides:
- Persistent storage across restarts
- No need for custom images
- Easier updates and maintenance

The cost difference ($100/month) may be worth it for production use cases.
