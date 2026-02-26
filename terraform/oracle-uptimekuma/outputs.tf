output "instance_id" {
  description = "OCID of the Uptime Kuma instance"
  value       = oci_core_instance.uptimekuma.id
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = data.oci_core_vnic.uptimekuma.public_ip_address
}

output "uptimekuma_url" {
  description = "URL to access Uptime Kuma"
  value       = "http://${data.oci_core_vnic.uptimekuma.public_ip_address}:3001"
}

output "ansible_inventory_path" {
  description = "Generated Ansible inventory path"
  value       = abspath(local_file.ansible_inventory.filename)
}
