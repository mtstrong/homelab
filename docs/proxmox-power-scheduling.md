# Proxmox Host Power Scheduling

This runbook is for Proxmox hosts that do not need to run 24/7.

## Recommended model

- Use full shutdown, not sleep or hibernate.
- Use BIOS or UEFI RTC power-on for fixed daily or weekly start times.
- Use Wake-on-LAN for manual or ad-hoc wake-ups.
- Let the host shut itself down cleanly after the backup or maintenance window.

For this homelab, the cleanest split is:

- Unused Proxmox host: leave powered off and wake on demand.
- Proxmox Backup Server host: power on shortly before backups start, then shut down after backup, prune, verify, and sync tasks finish.

## Why BIOS RTC is the best scheduled power-on

Wake-on-LAN is useful, but a fully powered off host can only wake if the motherboard, NIC, and firmware all behave correctly from the S5 state.

BIOS or UEFI RTC power-on is simpler for fixed schedules because the host powers itself on without depending on the network, firewall rules, or a second automation controller.

Use Wake-on-LAN when:

- you want manual wake-ups from pfSense
- you need variable wake times
- the hardware wakes reliably from full shutdown

Use BIOS or UEFI RTC when:

- the wake time is predictable
- the host only needs to run for a backup window
- you want the most reliable powered-off to powered-on path

## Host requirements

On each Proxmox host, enable these settings before relying on automation:

- BIOS or UEFI: enable Wake-on-LAN and, if available, RTC scheduled power-on
- BIOS or UEFI: set Restore on AC Power Loss to Last State or Power On only if you plan to use a smart plug fallback
- Proxmox host NIC: confirm Wake-on-LAN is enabled and survives reboot

Example check on the Proxmox host:

```bash
ethtool enp3s0 | grep Wake-on
```

If needed, make WOL persistent with the network stack or a boot-time command.

## Ansible assets in this repo

- Playbook: [ansible/playbook-proxmox-power.yml](/c:/Users/stron/Documents/homelab/ansible/playbook-proxmox-power.yml)
- Example inventory: [ansible/proxmox-power/inventory.ini.example](/c:/Users/stron/Documents/homelab/ansible/proxmox-power/inventory.ini.example)
- Example vars: [ansible/proxmox-power/targets.example.yml](/c:/Users/stron/Documents/homelab/ansible/proxmox-power/targets.example.yml)

The playbook supports three flows:

- `wake`: send Wake-on-LAN packets and optionally wait for SSH
- `shutdown`: schedule an immediate or delayed graceful power-off on the host
- `timer`: deploy a systemd timer that powers off the host on a fixed schedule

## Inventory example

Copy the example inventory and replace the IPs, names, and user.

```ini
[proxmox_power_managed]
pbs ansible_host=192.168.1.117 ansible_user=root
spare-pve ansible_host=192.168.1.118 ansible_user=root
```

## Target vars example

Copy the example vars file and replace the MAC addresses and host IPs.

```yaml
proxmox_power_targets:
  - name: pbs
    mac: aa:bb:cc:dd:ee:ff
    host: 192.168.1.117
    broadcast: 192.168.1.255
  - name: spare-pve
    mac: aa:bb:cc:dd:ee:00
    host: 192.168.1.118
    broadcast: 192.168.1.255

proxmox_poweroff_on_calendar: "*-*-* 23:30:00"
proxmox_shutdown_delay_minutes: 15
```

## Common commands

Wake both hosts and wait for SSH:

```bash
ansible-playbook -i ansible/proxmox-power/inventory.ini ansible/playbook-proxmox-power.yml \
  --tags wake \
  -e @ansible/proxmox-power/targets.yml
```

Gracefully shut down the backup server in 15 minutes:

```bash
ansible-playbook -i ansible/proxmox-power/inventory.ini ansible/playbook-proxmox-power.yml \
  --tags shutdown \
  --limit pbs \
  -e proxmox_shutdown_delay_minutes=15
```

Deploy a nightly power-off timer at 23:30:

```bash
ansible-playbook -i ansible/proxmox-power/inventory.ini ansible/playbook-proxmox-power.yml \
  --tags timer \
  --limit pbs \
  -e proxmox_poweroff_on_calendar="*-*-* 23:30:00"
```

## Practical schedules

### Unused Proxmox host

- Default state: off
- Power on: pfSense Wake-on-LAN when needed
- Power off: `--tags shutdown --limit spare-pve`

### Proxmox Backup Server host

- Power on: BIOS or UEFI RTC 10 to 15 minutes before the backup window
- Power off: deploy the timer after the last expected backup, prune, verify, and sync job

If you prefer a variable schedule, keep BIOS RTC disabled and wake the host from an always-on controller with the `wake` tag.

## pfSense role

pfSense is a good manual wake source because it stays online and can send Wake-on-LAN packets from the LAN interface.

Use pfSense for:

- manual wake-ups
- occasional maintenance windows
- emergency remote power-on

Use BIOS or UEFI RTC for:

- predictable daily or weekly power-on windows
- the Proxmox Backup Server host

## Safety notes

- Do not power off a clustered Proxmox node if it will break quorum or shared services.
- Do not use sleep for a Proxmox host unless you have tested VM, storage, and NIC behavior after resume.
- Keep the shutdown timer later than the last backup-related task, not just the backup start time.