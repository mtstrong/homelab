#!/usr/bin/env bash
# Creates a Proxmox cloud-image based Ubuntu 24.04 template.
#
# Usage:
#   ./create_proxmox_ubuntu24_template.sh <node> <storage> <vmid> <template-name> [cores] [memory_mb] [disk_gb] [hostname] [username] [password]
#
# Positional arguments:
#   node          - Proxmox node name (default: um773a)
#   storage       - Proxmox storage to import the disk into (default: local-lvm)
#   vmid          - VM ID to create for the template (must be unused) (default: 9000)
#   template-name - Friendly name for the template (default: ubuntu-24-cloud)
#
# Optional arguments (defaults shown):
#   cores         - Number of CPU cores (default: 8)
#   memory_mb     - Memory in MB (default: 8192)
#   disk_gb       - Disk size in GB (default: 64)
#   hostname      - VM hostname and name used for the VM (default: same as template-name)
#   username      - Cloud-init username to create (default: ubuntu)
#   password      - Cloud-init password for the user (default: empty, not recommended)
#
# Example:
#   ./create_proxmox_ubuntu24_template.sh um773a local-lvm 9000 ubuntu-24-cloud 8 8192 64 my-hostname myuser 'S3cretP@ss'
#
# Notes and security:
# - The script must be run on the Proxmox host (or a machine with `qm` access to the node).
# - Passing passwords on the command line can expose them via process lists and shell history. Prefer using SSH keys or leaving the password empty and configuring credentials later.
# - The script will attempt to use ~/.ssh/id_rsa.pub as the SSH key for cloud-init if present.
# - Adjust storage names to match your Proxmox environment (e.g., local, local-lvm, or nfs storage names).
set -euo pipefail

NODE=${1:-um773a}
STORAGE=${2:-local-lvm}
VMID=${3:-9000}
NAME=${4:-ubuntu-24-cloud}
# Optional parameters
CORES=${5:-8}
MEMORY_MB=${6:-8192}
DISK_SIZE_GB=${7:-64}
HOSTNAME=${8:-$NAME}
USERNAME=${9:-ubuntu}
PASSWORD=${10:-}
IMAGE_URL=${IMAGE_URL:-"https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"}
TMPDIR=$(mktemp -d)
IMG_NAME="ubuntu-24.04-server-cloudimg-amd64.img"

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

echo "Creating Ubuntu 24.04 cloud-image template on node=$NODE storage=$STORAGE vmid=$VMID name=$NAME"
echo "  cores=$CORES memory=${MEMORY_MB}MB disk=${DISK_SIZE_GB}G hostname=$HOSTNAME"
cd "$TMPDIR"

echo "Downloading cloud image..."
wget -q -O "$IMG_NAME" "$IMAGE_URL"

# Import disk to storage (qm importdisk requires target storage name accessible on node)
# This will place the disk on the storage as vm-<vmid>-disk-0
echo "Creating VM $VMID"
qm create "$VMID" --name "$HOSTNAME" --memory "$MEMORY_MB" --cores "$CORES" --net0 virtio,bridge=vmbr0 --agent 1

echo "Importing disk to storage $STORAGE"
qm importdisk "$VMID" "$IMG_NAME" "$STORAGE" --node "$NODE"

# The imported disk will have a generated name; attach it as scsi0 using the expected name
DISK_NAME=$(ls -1 /var/lib/vz/images | grep -m1 "vm-$VMID" || true)
# Fallback: set scsi0 to storage:vm-$VMID-disk-0 style
# Attach scsi0 and create cloudinit drive
echo "Configuring disks and cloud-init"
qm set "$VMID" --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:vm-${VMID}-disk-0 --ide2 ${STORAGE}:cloudinit --boot order=scsi0 --serial0 socket --vga serial0

# Resize disk to requested size (qm resize requires disk id scsi0 and size with unit)
echo "Resizing scsi0 to ${DISK_SIZE_GB}G"
qm resize "$VMID" scsi0 ${DISK_SIZE_GB}G || true

# Configure basic cloud-init settings
echo "Setting cloud-init defaults and enabling guest agent"
CI_CMD=(--ciuser "$USERNAME" --ipconfig0 ip=dhcp --sshkey "$(cat ~/.ssh/id_rsa.pub 2>/dev/null || true)" --name "$HOSTNAME")
if [[ -n "$PASSWORD" ]]; then
  CI_CMD+=(--cipassword "$PASSWORD")
fi
qm set "$VMID" "${CI_CMD[@]}"

# Start VM briefly to let cloud-init run initial config if desired (optional)
# qm start "$VMID"
# sleep 10
# qm shutdown "$VMID"

# Convert to template
echo "Shutting down VM and converting to template"
qm shutdown "$VMID" || true
# wait for shutdown
for i in {1..30}; do
  state=$(qm status "$VMID" 2>/dev/null || true)
  if [[ "$state" == "status: stopped" || "$state" == "status: shutdown" ]]; then
    break
  fi
  sleep 1
done
qm template "$VMID"

echo "Template $NAME (vmid $VMID) created on node $NODE storage $STORAGE"

exit 0
