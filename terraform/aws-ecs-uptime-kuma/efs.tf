# EFS File System for persistent storage
resource "aws_efs_file_system" "uptime_kuma" {
  creation_token = "${var.project_name}-efs"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name = "${var.project_name}-efs"
  }
}

# EFS Mount Targets
resource "aws_efs_mount_target" "uptime_kuma" {
  count           = length(var.availability_zones)
  file_system_id  = aws_efs_file_system.uptime_kuma.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}

# EFS Access Point
resource "aws_efs_access_point" "uptime_kuma" {
  file_system_id = aws_efs_file_system.uptime_kuma.id

  root_directory {
    path = "/uptime-kuma"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  posix_user {
    gid = 1000
    uid = 1000
  }

  tags = {
    Name = "${var.project_name}-efs-access-point"
  }
}
