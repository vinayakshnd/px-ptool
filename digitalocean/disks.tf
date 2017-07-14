resource "digitalocean_volume" "do-swap-vol" {
  count = "${var.px_node_count}"
  region      = "${var.px_region}"
  name        = "${format("do-%s-swap-vol-%d", var.user_prefix, count.index + 1)}"
  size        = "8"
  description = "px digitalocean swap volume"
}

resource "digitalocean_volume" "do-docker-vol" {
  count = "${var.px_node_count}"
  region      = "${var.px_region}"
  name        = "${format("do-%s-docker-vol-%d", var.user_prefix, count.index + 1)}"
  size        = "64"
  description = "px digitalocean docker volume"
}

resource "digitalocean_volume" "do-disk1-vol" {
  count = "${var.px_node_count}"
  region      = "${var.px_region}"
  name        = "${format("do-%s-disk1-%d", var.user_prefix, count.index + 1)}"
  size        = "128"
  description = "px digitalocean docker volume"
}

resource "digitalocean_volume" "do-disk2-vol" {
  count = "${var.px_node_count}"
  region      = "${var.px_region}"
  name        = "${format("do-%s-disk2-%d", var.user_prefix, count.index + 1)}"
  size        = "64"
  description = "px digitalocean docker volume"
}

