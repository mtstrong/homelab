# Cloudflare DNS — Terraform IaC

Manages all `tehmatt.com` DNS records in Cloudflare via Terraform.

## Architecture

| Record Type | Count | Pattern |
|-------------|-------|---------|
| A           | 3     | Root (`@`), `www`, `tinyauth` → public IP |
| CNAME       | 36    | All service subdomains → `tehmatt.com` |
| TXT         | 0*    | ACME challenges managed by cert-manager |

> \* TXT records for ACME challenges are created/destroyed dynamically by cert-manager and are **not** managed here to avoid conflicts.

## Quick Start

```bash
cd terraform/cloudflare-dns

# 1. Create your tfvars from the example
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set your API token and public IP

# 2. Initialize Terraform
terraform init

# 3. Import existing records into state
bash import.sh

# 4. Verify — should show no changes
terraform plan

# 5. Going forward, add/remove subdomains in variables.tf and apply
terraform apply
```

## Adding a New Subdomain

1. Add the subdomain key to `cname_records` in `variables.tf`:
   ```hcl
   variable "cname_records" {
     default = {
       # existing entries...
       "newservice" = {}
     }
   }
   ```
2. Run `terraform apply`
3. That's it — no manual Cloudflare dashboard clicks needed.

## Removing a Subdomain

1. Remove the key from the map in `variables.tf`
2. Run `terraform apply` — the DNS record will be deleted

## Changing the Public IP

Update `public_ip` in `terraform.tfvars` and run `terraform apply`. All A records update automatically.

## Files

| File | Purpose |
|------|---------|
| `versions.tf` | Provider version constraints |
| `main.tf` | Provider config, DNS record resources |
| `variables.tf` | Input variable definitions with record maps |
| `outputs.tf` | Useful outputs (record FQDNs, counts) |
| `terraform.tfvars.example` | Template for secrets — copy to `terraform.tfvars` |
| `import.sh` | One-time script to import existing records into state |
| `.gitignore` | Keeps state files and secrets out of git |

## Security

- `terraform.tfvars` is gitignored — **never commit API tokens**
- The Cloudflare API token needs only `Zone:DNS:Edit` permission for the `tehmatt.com` zone
- State file contains record IDs (not secrets), but is still gitignored as best practice
