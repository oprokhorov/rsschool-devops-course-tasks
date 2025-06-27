output "bastion_instance_public_ip" {
  description = "Public IP address of the Bastion EC2 instance"
  value       = module.bastion.instance_public_ip
}

output "bastion_instance_private_ip" {
  description = "Private IP address of the Bastion EC2 instance"
  value       = module.bastion.instance_private_ip
}

output "control_node_private_ip" {
  description = "Private IP address of the ControlNode EC2 instance"
  value       = module.control_node.instance_private_ip
}

output "worker_node_private_ip" {
  description = "Private IP address of the WorkerNode EC2 instance"
  value       = module.worker_node.instance_private_ip
}

output "public_vm_private_ip" {
  description = "Private IP address of the PublicVM EC2 instance"
  value       = module.public_vm.instance_private_ip
}

output "public_vm_public_ip" {
  description = "Public IP address of the PublicVM EC2 instance"
  value       = module.public_vm.instance_public_ip
}