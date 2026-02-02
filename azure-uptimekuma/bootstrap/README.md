# Bootstrap - Storage Backend Setup

This directory contains OpenTofu configuration to create the Azure Storage infrastructure needed to store remote state for the main Uptime Kuma deployment.

## Purpose

The bootstrap configuration creates:
- Azure Resource Group for state storage
- Azure Storage Account
- Blob Container for state files
- Auto-generates `backend-config.tfvars` for the main deployment

## Why Separate Bootstrap?

This bootstrap project uses **local state** to create the storage account that will hold **remote state** for other projects. This is a common pattern to avoid the "chicken and egg" problem of storing state before you have a place to store it.

## Usage

### 1. Configure

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set a **globally unique** storage account name:
```hcl
storage_account_name = "youruniquename123"  # 3-24 lowercase alphanumeric
```

### 2. Deploy Bootstrap

```bash
tofu init
tofu plan
tofu apply
```

This will:
- Create the storage account and container
- Generate `../backend-config.tfvars` for the main deployment
- Generate `../backend.tf` with backend configuration

### 3. Use in Main Deployment

```bash
cd ..
tofu init -backend-config=backend-config.tfvars
```

## Important Notes

⚠️ **The bootstrap state is stored locally** in this directory. Keep these files safe:
- `terraform.tfstate` - Tracks the storage account
- `terraform.tfvars` - Your configuration

If you lose the bootstrap state, you can import the existing resources:
```bash
tofu import azurerm_resource_group.state /subscriptions/SUB_ID/resourceGroups/rg-tofu-state
tofu import azurerm_storage_account.state /subscriptions/SUB_ID/resourceGroups/rg-tofu-state/providers/Microsoft.Storage/storageAccounts/ACCOUNT_NAME
```

## Cost

~$0.02/month for state storage

## Files Generated

After `tofu apply`, these files are created in the parent directory:
- `backend-config.tfvars` - Backend connection details
- `backend.tf` - Backend configuration block

## Cleanup

⚠️ **Do not destroy** the bootstrap resources if you have active deployments using the remote state!

To destroy (only if no longer needed):
```bash
tofu destroy
```
