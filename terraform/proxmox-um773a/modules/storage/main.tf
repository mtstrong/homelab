resource "proxmox_storage_pool" "pool" {
  name   = var.pool_name
  type   = var.storage_type
  nodes  = var.nodes
  
  dynamic "content" {
    for_each = var.content_types
    content {
      type = content.value
    }
  }

  disable = var.disabled

  # LVM storage
  dynamic "lvmthin" {
    for_each = var.storage_type == "lvmthin" ? [1] : []
    content {
      volume_group = var.volume_group
      thinpool     = var.thinpool
    }
  }

  # Directory storage
  dynamic "dir" {
    for_each = var.storage_type == "dir" ? [1] : []
    content {
      path     = var.path
      maxfiles = var.maxfiles
    }
  }
}
