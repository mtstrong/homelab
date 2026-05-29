# Uptime Kuma Configuration Management

This directory contains scripts and configuration files for managing Uptime Kuma settings.

## Configuration Approaches

### 1. Database Import (Recommended for ECS)

The most reliable way to configure Uptime Kuma is to import a pre-configured database.

#### Export existing configuration:

```bash
# If you have an existing Uptime Kuma instance
docker exec uptime-kuma cat /app/data/kuma.db > kuma.db.backup
```

#### Import into ECS:

```bash
# Get EFS file system ID
EFS_ID=$(terraform output -raw efs_id)

# Mount EFS locally (requires EC2 instance or Cloud9)
# Then copy your kuma.db to: /mnt/efs/uptime-kuma/kuma.db

# Or use AWS DataSync or S3 transfer
```

### 2. API-based Configuration

Use the provided script to configure via API after deployment.

#### Setup:

```bash
# Edit the script with your configuration
vim scripts/configure-uptime-kuma.sh

# Export environment variables
export UPTIME_KUMA_URL="http://your-alb-url"
export ADMIN_USERNAME="admin"
export ADMIN_PASSWORD="your-secure-password"

# Run configuration script
bash scripts/configure-uptime-kuma.sh
```

### 3. Custom Docker Image

Create a custom image with pre-configured database:

```dockerfile
FROM louislam/uptime-kuma:latest

# Copy pre-configured database
COPY kuma.db /app/data/kuma.db

# Set ownership
RUN chown -R node:node /app/data
```

Build and push to ECR:

```bash
docker build -t uptime-kuma-configured .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
docker tag uptime-kuma-configured:latest <account>.dkr.ecr.us-east-1.amazonaws.com/uptime-kuma:configured
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/uptime-kuma:configured
```

Update `variables.tf`:
```hcl
uptime_kuma_image = "<account>.dkr.ecr.us-east-1.amazonaws.com/uptime-kuma:configured"
```

### 4. Init Container Pattern

Add an init container to the ECS task definition that runs configuration before the main container starts.

See `task-definition-with-init.json` for an example.

## Configuration Files

### monitors.json

Define your monitors in JSON format:

```json
[
  {
    "name": "Production Website",
    "type": "http",
    "url": "https://example.com",
    "interval": 60,
    "retryInterval": 60,
    "maxretries": 3,
    "notificationIDList": []
  },
  {
    "name": "API Health Check",
    "type": "http",
    "url": "https://api.example.com/health",
    "interval": 30,
    "method": "GET",
    "expectedStatus": "200"
  }
]
```

### notifications.json

Define notification channels:

```json
[
  {
    "name": "Slack Alerts",
    "type": "slack",
    "config": {
      "webhookURL": "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
    }
  },
  {
    "name": "Email Alerts",
    "type": "smtp",
    "config": {
      "hostname": "smtp.gmail.com",
      "port": 587,
      "username": "your-email@gmail.com",
      "password": "your-app-password",
      "from": "uptime-kuma@example.com",
      "to": "alerts@example.com"
    }
  }
]
```

## Automated Configuration with Terraform

### Using Null Resource

Add to your `main.tf`:

```hcl
resource "null_resource" "configure_uptime_kuma" {
  depends_on = [aws_ecs_service.uptime_kuma]

  provisioner "local-exec" {
    command = <<-EOT
      export UPTIME_KUMA_URL="http://${aws_lb.uptime_kuma.dns_name}"
      export ADMIN_USERNAME="${var.admin_username}"
      export ADMIN_PASSWORD="${var.admin_password}"
      bash ${path.module}/scripts/configure-uptime-kuma.sh
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}
```

Add variables:

```hcl
variable "admin_username" {
  description = "Uptime Kuma admin username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "admin_password" {
  description = "Uptime Kuma admin password"
  type        = string
  sensitive   = true
}
```

## Best Practices

1. **Secrets Management**: Store credentials in AWS Secrets Manager
2. **Configuration as Code**: Keep monitor definitions in version control
3. **Backup Strategy**: Regularly export and backup the database
4. **Version Pinning**: Use specific image tags, not `latest`
5. **Health Checks**: Configure appropriate health check intervals

## Backup and Restore

### Backup Database

```bash
# From running ECS task
aws ecs execute-command \
  --cluster uptime-kuma-cluster \
  --task <task-id> \
  --container uptime-kuma \
  --command "cat /app/data/kuma.db" \
  --interactive > kuma.db.backup
```

### Restore Database

```bash
# Copy to EFS mount point
# Then restart ECS service
aws ecs update-service \
  --cluster uptime-kuma-cluster \
  --service uptime-kuma \
  --force-new-deployment
```

## Troubleshooting

### API Connection Issues

- Ensure ALB security group allows your IP
- Check service is healthy: `aws ecs describe-services --cluster uptime-kuma-cluster --services uptime-kuma`
- Verify ALB target health

### Database Lock Issues

- Only one container instance can access the SQLite database at a time
- Keep `desired_count = 1` unless using external database

### Configuration Not Applied

- Check CloudWatch logs: `/ecs/uptime-kuma`
- Verify init script completed successfully
- Ensure proper file permissions on EFS
