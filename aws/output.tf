output "public_ips" {
  value = "${aws_instance.px-node.*.public_ip}"
}

output "private_ips" {
  value = "${aws_instance.px-node.*.private_ip}"
}

output "admuser" {
  value = "${var.vm_admin_user}"
}

output "admpassword" {
  value = "${var.vm_admin_password}"
}