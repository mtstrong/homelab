output "web_node_info" {
  description = "K3S web node information"
  value = try({
    vm_id    = module.vms_web[0].vm_id
    vm_name  = module.vms_web[0].vm_name
    status   = module.vms_web[0].vm_status
    ip_address = module.vms_web[0].vm_default_ipv4_address
  }, null)
}

output "worker_nodes_info" {
  description = "K3S worker nodes information"
  value = {
    for key, vm in module.vms_worker : key => {
      vm_id      = vm.vm_id
      vm_name    = vm.vm_name
      status     = vm.vm_status
      ip_address = vm.vm_default_ipv4_address
    }
  }
}
