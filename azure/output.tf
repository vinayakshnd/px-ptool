output "public_ips" {
  value = "${azurerm_public_ip.apubip.*.ip_address}"
}
output "admuser" {
  value = "${var.vm_admin_user}"
}

output "admpassword" {
  value = "${var.vm_admin_password}"
}