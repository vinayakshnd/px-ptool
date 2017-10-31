output "public_ips" {
  value = "${concat(aws_instance.px-node.*.public_ip, aws_instance.px-ecs-node.*.public_ip)}"
}

output "private_ips" {
  value = "${concat(aws_instance.px-node.*.private_ip, aws_instance.px-ecs-node.*.private_ip)}"
}

output "admuser" {
  value = "${var.vm_admin_user}"
}

output "admpassword" {
  value = "${var.vm_admin_password}"
}