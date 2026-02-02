# Azure Uptime Kuma Deployment with OpenTofu

Deploy Uptime Kuma to Azure Container Instances using OpenTofu for monitoring your homelab from outside your network.

## Cost Estimate
- **~$1-2/month** with default settings
- 0.5 vCPU, 1GB RAM
- 1GB storage for data persistence

## Prerequisites

1. **Azure CLI** installed and authenticated:
   ```bash
   az login
   ```

2. **OpenTofu** installed:
   ```bash
   # Install via package manager or download from opentofu.org
   ```

3. **Azure Subscription** with appropriate permissions

## Quick Start

### 1. Set Up State Backend (Recommended)

First, configure Azure Storage to store your OpenTofu state:

```bash
./setup-backend.sh
```

This will:
- Create a resource group for state storage
- Create a storage account (globally unique name)
- Create a blob container for state files
- Generate `backend-config.tfvars` with connection details
- Cost: ~$0.02/month

### 2. Configure Variables

Copy the example file and customize:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and change these **REQUIRED** values to be globally unique:
- `storage_account_name` (3-24 lowercase alphanumeric chars)
- `dns_name_label` (your preferred subdomain)

### 3. Initialize OpenTofu

**With backend (recommended):**
```bash
tofu init -backend-config=backend-config.tfvars
```

**Without backend (local state only):**
```bash
tofu init
```

### 4. Plan the Deployment

```bash
tofu plan
```

Review the planned changes to ensure everything looks correct.

### 5. Deploy

```bash
tofu apply
```

Type `yes` when prompted to confirm.

### 6. Access Uptime Kuma

After deployment completes, OpenTofu will output the URL:
```
uptimekuma_url = "http://your-dns-name.eastus.azurecontainer.io:3001"
```

Visit this URL to set up your Uptime Kuma instance.

## Configuration

### Resource Sizing

Adjust in `terraform.tfvars`:
```hcl
cpu_cores    = "0.5"  # Minimum 0.5, increment by 0.5
memory_in_gb = "1.0"  # Minimum 1.0
```

### Location (Region)

Change `location` to a region closer to you or cheaper:
```hcl
location = "eastus"  # Options: eastus, westus2, centralus, etc.
```

## Data Persistence

Uptime Kuma data is stored in Azure Files and persists across container restarts. Your monitors, settings, and history are preserved.

## State Management

OpenTofu state is stored in Azure Blob Storage (if you ran `setup-backend.sh`), providing:
- **State locking** - Prevents concurrent modifications
- **Versioning** - Automatic history of state changes
- **Backup** - Azure handles redundancy
- **Collaboration** - Team members can share state

The state file tracks all your Azure resources and is critical for updates and deletions.

## Monitoring Your Homelab

Once deployed:
1. Access the Uptime Kuma web interface
2. Create a new monitor for each service you want to track
3. Add your public homelab URLs/IPs
4. Configure notifications (email, Discord, Slack, etc.)

## Maintenance

### View Current State
```bash
tofu show
```

### Update Configuration
1. Modify `terraform.tfvars`
2. Run `tofu plan` to preview changes
3. Run `tofu apply` to apply changes

### Destroy Resources
```bash
tofu destroy
```

**Warning:** This will delete all resources including stored data!

## Cost Optimization Tips

1. **Use the cheapest region** (typically eastus or southcentralus)
2. **Start with minimum resources** (0.5 CPU, 1GB RAM)
3. **Monitor actual usage** and adjust if needed
4. **Consider Azure Free Tier** credits for first month

## Troubleshooting

### Container not starting
Check logs in Azure Portal or:
```bash
az container logs --resource-group rg-uptimekuma-monitoring --name uptimekuma
```

### Storage account name already exists
The name must be globally unique. Change `storage_account_name` in `terraform.tfvars`.

### DNS name already taken
The DNS label must be unique in the region. Change `dns_name_label` in `terraform.tfvars`.

## Security Considerations

1. **No authentication by default** - Set up Uptime Kuma authentication immediately
2. **HTTP only** - Consider adding HTTPS via Azure Front Door or Application Gateway (additional cost)
3. **Public IP** - Container is publicly accessible
4. **Network Security** - Consider Azure Virtual Network integration for production use

## Advanced: Add HTTPS (Optional)

For production use with HTTPS, consider:
- Azure Application Gateway (~$18/month minimum)
- Azure Front Door (~$35/month minimum)
- Caddy reverse proxy in the same container (free, requires modifications)

## Files

- `main.tf` - Main infrastructure definition
- `variables.tf` - Variable definitions
- `outputs.tf` - Output values after deployment
- `terraform.tfvars.example` - Example configuration
- `terraform.tfvars` - Your actual configuration (git-ignored)

## Support

For issues:
- OpenTofu: https://opentofu.org/docs
- Azure Provider: https://registry.terraform.io/providers/hashicorp/azurerm
- Uptime Kuma: https://github.com/louislam/uptime-kuma

## License

MIT
