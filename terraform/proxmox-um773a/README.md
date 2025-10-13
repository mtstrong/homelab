This folder contains Terraform configuration to create an Ubuntu VM on Proxmox PVE `um773a`.

Files
- `main.tf` - provider and VM resource
- `variables.tf` - variables and defaults
- `outputs.tf` - useful outputs

Before you run
1. Install Terraform (>= 1.0) and ensure network access to `um773a`.
2. Ensure a Proxmox template or cloud-init enabled VM named in `var.template` exists on the cluster (default: `ubuntu-22-template`).
3. Populate credentials in a `terraform.tfvars` file or export environment variables.

Example `terraform.tfvars`

proxmox_url = "https://um773a.tehmatt.com:8006"
proxmox_user = "root@pam"
proxmox_password = "YOUR_PASSWORD"
node = "um773a"
vm_id = 773
ssh_authorized_key = "ssh-rsa AAAA... your public key"

Run

terraform init
terraform plan
terraform apply

Notes
- This config uses the Telmate Proxmox provider. If Terraform cannot find the provider plugin, run `terraform init` to install it.
- The disk clone assumes `storage_pool` can accept LVM volumes. Adjust `storage` and `storage_type` if using directory-based storage (e.g., `local`).
- If you prefer token-based auth, set `pm_api_token_id` and `pm_api_token_secret` in provider block and variables instead of `pm_password`.
