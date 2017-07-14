resource "digitalocean_droplet" "px-node-droplet"{
  count = "${var.px_node_count}"
  name = "px-${var.user_prefix}-node-${count.index + 1}"
  image = "${var.px_image}"
  region = "${var.px_region}"
  size = "${var.px_vm_size}"
  ssh_keys = ["${var.public_key_fp}"]

}
