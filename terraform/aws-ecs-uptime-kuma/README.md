# Uptime Kuma on AWS ECS with Terraform

This Terraform configuration deploys Uptime Kuma on AWS ECS (Fargate) with persistent storage using EFS.

## Architecture

- **VPC**: Custom VPC with public and private subnets across multiple availability zones
- **ECS Cluster**: Fargate-based ECS cluster for running Uptime Kuma
- **Application Load Balancer**: Public-facing ALB for HTTP/HTTPS access
- **EFS**: Elastic File System for persistent data storage
- **Security Groups**: Network security for ALB, ECS tasks, and EFS
- **IAM Roles**: Proper permissions for ECS task execution and runtime

## Features

- ✅ High availability across multiple availability zones
- ✅ Persistent storage with EFS
- ✅ Auto-scaling capable (configured for single instance by default)
- ✅ CloudWatch logging
- ✅ Health checks
- ✅ NAT Gateway for private subnet internet access
- ✅ Security groups with least privilege access

## Prerequisites

Before deploying, ensure you have:

1. **AWS CLI** installed and configured with appropriate credentials
2. **Terraform** (>= 1.0) installed
3. AWS account with appropriate permissions to create:
   - VPC and networking components
   - ECS clusters and services
   - EFS file systems
   - Application Load Balancers
   - IAM roles and policies
   - CloudWatch log groups

## Quick Start

### 1. Initialize Terraform

```bash
cd terraform/aws-ecs-uptime-kuma
terraform init
```

### 2. Review and Customize Variables

Edit `variables.tf` or create a `terraform.tfvars` file:

```hcl
aws_region         = "us-east-1"
project_name       = "uptime-kuma"
environment        = "prod"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
task_cpu           = "512"
task_memory        = "1024"
desired_count      = 1
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

After deployment completes, get the ALB URL:

```bash
terraform output uptime_kuma_url
```

Visit the URL in your browser to access Uptime Kuma. On first access, you'll be prompted to create an admin account.

## Configuration Options

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for deployment | `us-east-1` |
| `project_name` | Name prefix for resources | `uptime-kuma` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `availability_zones` | AZs for deployment | `["us-east-1a", "us-east-1b"]` |
| `task_cpu` | CPU units for container | `512` |
| `task_memory` | Memory in MB | `1024` |
| `desired_count` | Number of tasks to run | `1` |
| `uptime_kuma_image` | Docker image | `louislam/uptime-kuma:latest` |
| `enable_nat_gateway` | Enable NAT for private subnets | `true` |
| `log_retention_days` | CloudWatch log retention | `7` |

### HTTPS Configuration

To enable HTTPS:

1. Request or import an SSL certificate in AWS Certificate Manager (ACM)
2. Uncomment the HTTPS listener section in `alb.tf`
3. Add the certificate ARN to your variables:

```hcl
certificate_arn = "arn:aws:acm:region:account-id:certificate/certificate-id"
```

4. Optionally uncomment the HTTP to HTTPS redirect

## Resource Costs

Estimated monthly costs (us-east-1, as of 2026):

- **ECS Fargate**: ~$15-30/month (0.5 vCPU, 1GB RAM)
- **Application Load Balancer**: ~$20/month
- **NAT Gateway**: ~$35/month per AZ (~$70 for 2 AZs)
- **EFS**: ~$0.30/GB-month (depends on data size)
- **Data Transfer**: Variable based on usage

**Total**: Approximately $105-125/month

### Cost Optimization Tips

1. **Disable NAT Gateway** if ECS tasks don't need internet access:
   ```hcl
   enable_nat_gateway = false
   ```

2. **Use single AZ** for non-production:
   ```hcl
   availability_zones = ["us-east-1a"]
   ```

3. **Use Fargate Spot** for additional savings (edit capacity provider strategy in `main.tf`)

## Maintenance

### Update Uptime Kuma Version

Update the image version in `variables.tf` or your `terraform.tfvars`:

```hcl
uptime_kuma_image = "louislam/uptime-kuma:1.23.13"
```

Then apply:

```bash
terraform apply
```

### Scale the Service

Modify `desired_count` and apply:

```hcl
desired_count = 2
```

### View Logs

```bash
aws logs tail /ecs/uptime-kuma --follow --region us-east-1
```

## Backup and Recovery

### EFS Backup

AWS Backup can be configured for EFS (not included in this config). Alternatively:

```bash
# Create manual backup
aws efs create-backup \
  --file-system-id $(terraform output -raw efs_id) \
  --region us-east-1
```

### Data Location

Uptime Kuma data is stored in EFS at `/uptime-kuma/` directory.

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted. This will:
- Delete the ECS service and tasks
- Remove the ALB and target groups
- Delete the EFS file system (including all data)
- Remove the VPC and all networking components
- Delete IAM roles and policies
- Remove CloudWatch log groups

**⚠️ Warning**: This operation is irreversible and will delete all Uptime Kuma data.

## Troubleshooting

### Service Won't Start

1. Check ECS task logs:
   ```bash
   aws logs tail /ecs/uptime-kuma --follow
   ```

2. Verify security group rules allow communication between ALB and ECS tasks

3. Check EFS mount targets are in healthy state

### Can't Access via ALB

1. Verify ALB is in "active" state
2. Check security group allows inbound traffic on port 80/443
3. Verify target group health checks are passing

### EFS Mount Issues

1. Ensure EFS security group allows NFS (port 2049) from ECS tasks
2. Verify EFS mount targets exist in all private subnets
3. Check IAM role has EFS access permissions

## Security Considerations

1. **CIDR Restrictions**: Update `allowed_cidr_blocks` to restrict ALB access
2. **Enable HTTPS**: Use ACM certificates for encrypted traffic
3. **Private Deployment**: Modify ALB to be internal-facing if needed
4. **IAM Policies**: Follow least privilege principle
5. **Enable Deletion Protection**: Set to `true` for production

## Support

For Uptime Kuma specific issues, visit:
- [Uptime Kuma GitHub](https://github.com/louislam/uptime-kuma)
- [Uptime Kuma Documentation](https://github.com/louislam/uptime-kuma/wiki)

For AWS/Terraform issues, refer to:
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
