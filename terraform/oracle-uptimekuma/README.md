# Oracle Cloud (Always Free) Uptime Kuma

This module provisions an Always Free OCI compute instance and opens TCP 3001 for Uptime Kuma. It generates an Ansible inventory file for the playbook under ansible/uptimekuma-oracle.

## What matches the Azure DevOps setup
- Same container image: louislam/uptime-kuma:1
- Same exposed port: 3001
- Same persistent data path: /app/data (mapped to /opt/uptime-kuma/data on the host)

## Prerequisites
- OCI account and API signing key
- OpenTofu or Terraform
- Ansible 2.14+

## Files
- main.tf, variables.tf, outputs.tf
- terraform.tfvars.example (copy to terraform.tfvars)

## Flow
1. Copy terraform.tfvars.example to terraform.tfvars and fill in your OCI values.
2. Apply the Terraform/OpenTofu plan.
3. Run the Ansible playbook in ansible/uptimekuma-oracle to install Docker and start Uptime Kuma.

## Notes
- Use an Ubuntu image OCID to keep the Ansible tasks simple.
- For Arm A1 Flex shapes, set flex_shape = true and choose flex_ocpus/flex_memory_gbs.
- The generated inventory is written to ansible/uptimekuma-oracle/inventory.ini.
- To migrate existing Uptime Kuma data, copy a backup of /app/data into /opt/uptime-kuma/data before starting the container.
