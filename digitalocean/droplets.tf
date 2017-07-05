resource "digitalocean_droplet" "px-node-droplet"{
  count = "${var.px_node_count}"
  name = "px-${var.user_prefix}-node${count.index + 1}"
  image = "${var.do-image}"
  region = "${var.do-region}"
  size = "${var.px-node-size}"
  ssh_keys = ["${digitalocean_ssh_key.default.fingerprint}"]

}