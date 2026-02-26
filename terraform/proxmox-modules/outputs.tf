output "control_vm_info" {
  description = "Control VM information"
  value = try({
    vm_id      = module.control[0].vm_id
    vm_name    = module.control[0].vm_name
    status     = module.control[0].vm_status
    ip_address = module.control[0].default_ipv4_address
  }, null)
}

output "worker_vms_info" {
  description = "Worker VMs information"
  value = {
    for key, vm in module.workers : key => {
      vm_id      = vm.vm_id
      vm_name    = vm.vm_name
      status     = vm.vm_status
      ip_address = vm.default_ipv4_address
    }
  }
}

output "longhorn_vms_info" {
  description = "Longhorn storage VMs information"
  value = {
    for key, vm in module.longhorn_nodes : key => {
      vm_id      = vm.vm_id
      vm_name    = vm.vm_name
      status     = vm.vm_status
      ip_address = vm.default_ipv4_address
    }
  }
}

output "cluster_info" {
  description = "Complete cluster information"
  value = {
    control = try({
      name = module.control[0].vm_name
      id   = module.control[0].vm_id
      ip   = module.control[0].default_ipv4_address
    }, null)
    workers = {
      for key, vm in module.workers : vm.vm_name => {
        id = vm.vm_id
        ip = vm.default_ipv4_address
      }
    }
    longhorn = {
      for key, vm in module.longhorn_nodes : vm.vm_name => {
        id = vm.vm_id
        ip = vm.default_ipv4_address
      }
    }
  }
}
