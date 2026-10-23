# Uptime Kuma on AWS Lightsail with Terraform

This Terraform configuration deploys Uptime Kuma on AWS Lightsail Container Service - a simple, cost-effective alternative to ECS.

## Architecture

- **Lightsail Container Service**: Managed container service with fixed pricing
- **Built-in Load Balancer**: Automatic HTTPS with managed certificates
- **Public Endpoint**: Direct public access via Lightsail subdomain
- **Optional Custom Domain**: Easy DNS configuration

## Why Lightsail?

| Feature | Lightsail | ECS (Full) |
|---------|-----------|------------|
| **Monthly Cost** | $7-10 | $105-125 |
| **Setup Complexity** | Simple (1 main resource) | Complex (VPC, ALB, NAT, etc.) |
| **HTTPS** | Included & automatic | Requires ACM + ALB config |
| **Persistent Storage** | ⚠️ Ephemeral (data lost on restart) | ✅ EFS (persistent) |
| **Scaling** | Manual (1-20 instances) | Automatic with target tracking |
| **Best For** | Dev, personal projects, simple apps | Production, high-traffic apps |

### Lightsail Limitations

⚠️ **IMPORTANT**: Lightsail containers use **ephemeral storage**. Your Uptime Kuma data (monitors, notifications, settings) will be lost if:
- The container restarts
- You redeploy
- Lightsail performs maintenance

**For production use with persistent data, use the ECS setup instead.**

## Pricing

Fixed monthly pricing based on container power:

| Power | vCPU | RAM | Monthly Cost |
|-------|------|-----|--------------|
| **nano** | 0.25 | 512 MB | **$7** |
| **micro** | 0.5 | 1 GB | **$10** |
| **small** | 1 | 2 GB | **$20** |
| **medium** | 2 | 4 GB | **$40** |
| **large** | 4 | 8 GB | **$80** |
| **xlarge** | 8 | 16 GB | **$160** |

**Recommended**: `nano` ($7/month) or `micro` ($10/month) for personal use

Includes:
- ✅ Compute resources
- ✅ Load balancer with HTTPS
- ✅ Data transfer (up to limits)
- ✅ No additional networking costs

## Prerequisites

Before deploying, ensure you have:

1. **AWS CLI** installed and configured with appropriate credentials
2. **Terraform** (>= 1.0) installed
3. AWS account with Lightsail permissions

## Quick Start

### 1. Initialize Terraform

```bash
cd terraform/aws-lightsail-uptime-kuma
terraform init
```

### 2. Review and Customize Variables

Create a `terraform.tfvars` file:

```hcl
aws_region        = "us-east-1"
service_name      = "uptime-kuma"
uptime_kuma_image = "louislam/uptime-kuma:latest"
container_power   = "nano"   # $7/month
container_scale   = 1
```

### 3. Plan the Deployment

```bash
terraform plan
```

### 4. Deploy

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### 5. Access Uptime Kuma

After deployment (takes 5-10 minutes), get the URL:

```bash
terraform output uptime_kuma_url
```

Visit the URL in your browser. On first access, you'll be prompted to create an admin account.

**Note**: The deployment process may take several minutes as Lightsail pulls the Docker image and starts the container.

## Configuration Options

### Container Power Sizing

Choose based on monitoring needs:

- **nano** ($7/mo): 5-20 monitors, basic checks
- **micro** ($10/mo): 20-50 monitors, recommended for most users
- **small** ($20/mo): 50-100 monitors, complex checks
- **medium+**: High-frequency checks, many monitors

### Scaling

Set `container_scale` to run multiple instances (1-20):

```hcl
container_scale = 2  # Run 2 instances for redundancy
```

Cost scales linearly: 2 nano instances = $14/month

### Custom Domain

To use your own domain (e.g., `uptime.yourdomain.com`):

1. Add your domain to Lightsail or ensure it's registered
2. Configure variables:

```hcl
domain_name = "yourdomain.com"
subdomain   = "uptime"
```

3. Update your domain's nameservers to AWS Route53 (if not already)

Lightsail will automatically provision an SSL certificate.

## Persistent Storage Workaround

Since Lightsail containers are ephemeral, here are options for data persistence:

### Option 1: External Database (Recommended for Production)

Configure Uptime Kuma to use an external database:
- Use Lightsail managed database (MySQL/PostgreSQL)
- Use AWS RDS
- Use Amazon DynamoDB

This requires Uptime Kuma configuration changes (not included in basic setup).

### Option 2: Regular Exports

- Regularly export your monitor configurations
- Keep backups of the configuration
- Re-import after container restarts

### Option 3: Use the ECS Setup Instead

For true persistent storage, use the [ECS configuration](../aws-ecs-uptime-kuma/) which includes EFS.

## Maintenance

### Update Uptime Kuma Version

Update the image version in your `terraform.tfvars`:

```hcl
uptime_kuma_image = "louislam/uptime-kuma:1.23.13"
```

Then apply:

```bash
terraform apply
```

⚠️ **Warning**: This will restart the container and lose any data.

### Scale Up/Down

Modify `container_power` or `container_scale` and apply:

```hcl
container_power = "micro"  # Upgrade from nano to micro
```

```bash
terraform apply
```

### View Logs

Using AWS CLI:

```bash
aws lightsail get-container-log \
  --service-name uptime-kuma \
  --container-name uptime-kuma \
  --region us-east-1
```

Or view in the AWS Console: Lightsail → Container Services → uptime-kuma → Metrics & Logs

## Monitoring & Health Checks

Lightsail automatically monitors the container:
- Health checks every 30 seconds on path `/`
- Restarts unhealthy containers automatically
- View metrics in AWS Console (CPU, memory, network)

## Cleanup

To destroy all resources and stop billing:

```bash
terraform destroy
```

Type `yes` when prompted.

⚠️ **Warning**: This will delete the service and all data immediately.

## Troubleshooting

### Service Shows "Deploying" for a Long Time

Lightsail container deployments can take 5-10 minutes. Check:

```bash
aws lightsail get-container-services --service-name uptime-kuma
```

### Container Won't Start

1. Check logs:
   ```bash
   aws lightsail get-container-log \
     --service-name uptime-kuma \
     --container-name uptime-kuma
   ```

2. Verify the image is publicly accessible
3. Check container power is sufficient (try `micro` instead of `nano`)

### Can't Access the URL

1. Wait for deployment to complete (check AWS Console)
2. Verify HTTPS is used (Lightsail requires HTTPS)
3. Check service state: `terraform show | grep state`

### Data Loss After Restart

This is expected with Lightsail containers. Options:
- Accept data loss for testing/dev environments
- Implement external database for persistence
- Use the ECS setup with EFS instead

## Comparison: Lightsail vs ECS

### Use Lightsail When:
- ✅ Development or personal use
- ✅ Budget is primary concern ($7-10/month)
- ✅ Simplicity is important
- ✅ Data loss is acceptable or mitigated externally
- ✅ Traffic is low to moderate

### Use ECS When:
- ✅ Production environment
- ✅ Data persistence is critical
- ✅ Need auto-scaling
- ✅ Complex networking requirements
- ✅ Integration with other AWS services (RDS, ElastiCache, etc.)

## Migration from Lightsail to ECS

If you start with Lightsail and need to migrate to ECS later:

1. Export your Uptime Kuma configuration
2. Deploy the ECS infrastructure
3. Import configuration into ECS instance
4. Update DNS to point to new ALB
5. Destroy Lightsail service

## Security Considerations

1. **HTTPS**: Enabled by default with AWS-managed certificates
2. **Public Access**: Lightsail containers are publicly accessible by default
3. **Access Control**: Implement within Uptime Kuma (authentication required)
4. **Updates**: Keep the Docker image updated to latest stable version

## Support

For Uptime Kuma specific issues, visit:
- [Uptime Kuma GitHub](https://github.com/louislam/uptime-kuma)
- [Uptime Kuma Documentation](https://github.com/louislam/uptime-kuma/wiki)

For AWS Lightsail issues, refer to:
- [AWS Lightsail Documentation](https://docs.aws.amazon.com/lightsail/)
- [Lightsail Container Services](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-container-services.html)

## Additional Resources

- [Lightsail Pricing](https://aws.amazon.com/lightsail/pricing/)
- [Lightsail Container Service Limits](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-service-quotas.html)
