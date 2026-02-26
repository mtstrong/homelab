output "bridge_name" {
  description = "Bridge interface name"
  value       = proxmox_virtual_environment_network_linux_bridge.bridge.bridge
}
