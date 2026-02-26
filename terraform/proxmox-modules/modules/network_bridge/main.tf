resource "proxmox_virtual_environment_network_linux_bridge" "bridge" {
  node_name = var.node_name
  
  # Bridge config
  bridge     = var.bridge_name
  comment    = var.comment
  disabled   = var.disabled

  addresses = var.addresses

  dynamic "route" {
    for_each = var.routes
    content {
      address = route.value.address
      gateway = route.value.gateway
    }
  }
}
