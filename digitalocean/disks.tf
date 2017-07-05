resource "digitalocean_volume" "do-vol" {
  count = "${var.px_node_count * var.px_disk_count}"
  region      = "${var.do-region}"
  name        = "${format("do-vol-%s-%02d", var.user_prefix, (((count.index)/var.px_disk_count) + 1) *10 + 1 + (count.index % var.px_disk_count))}"
  size        = "${var.px-disk-size}"

  description = "px digital ocean volume"
}