output "do_region" {
  value = "${var.px_region}"
}

output "private_key_file" {
  value = "${var.private_key_file}"
}

output "do_node_public_ips" {
  value = ["${digitalocean_droplet.px-node-droplet.*.ipv4_address}"]
}

output "vm_admin_user" {
  value = "${var.vm_admin_user}"
}

output "vm_admin_password" {
  value = "${var.vm_admin_password}"
}
