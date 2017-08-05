resource "digitalocean_droplet" "px-node-droplet"{
  count = "${var.px_node_count}"
  name = "px-${var.user_prefix}-node-${count.index + 1}"
  image = "${var.px_image}"
  region = "${var.px_region}"
  size = "${var.px_vm_size}"
  private_networking = "true"
  ssh_keys = ["${var.public_key_fp}"]
  connection {
    type = "ssh"
    user = "${var.default_user}"
    private_key = "${file("${var.private_key_file}")}"
    timeout = "5m"
    agent = false
  }

  provisioner "file" {
    source = "scripts/post_install.sh"
    destination = "/tmp/post_install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/post_install.sh",
      "/tmp/post_install.sh ${var.vm_admin_user} ${var.vm_admin_password} ${var.px_ent_uuid}"
    ]
  }
}
