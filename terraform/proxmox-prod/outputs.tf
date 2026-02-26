output "cluster_topology" {
  description = "Complete cluster topology and node information"
  value = {
    control_planes = {
      for key, vm in module.control : vm.vm_name => {
        vmid = vm.vm_id
        ip   = vm.default_ipv4_address
      }
    }
    workers = {
      for key, vm in module.workers : vm.vm_name => {
        vmid = vm.vm_id
        ip   = vm.default_ipv4_address
      }
    }
    longhorn = {
      for key, vm in module.longhorn : vm.vm_name => {
        vmid = vm.vm_id
        ip   = vm.default_ipv4_address
      }
    }
  }
}

output "summary" {
  description = "Cluster summary"
  value = {
    control_count  = length(module.control)
    worker_count   = length(module.workers)
    longhorn_count = length(module.longhorn)
    total_vms      = length(module.control) + length(module.workers) + length(module.longhorn)
  }
}
