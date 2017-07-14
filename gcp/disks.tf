resource "google_compute_disk" "gcp-swap-pd" {
  count = "${var.px_node_count}"
  name = "${format("px-gcp-%s-swap-%d", var.user_prefix, count.index + 1)}"
  zone = "${var.px_region_zone}"
  size = "8"
}

resource "google_compute_disk" "gcp-docker-pd" {
  count = "${var.px_node_count}"
  name = "${format("px-gcp-%s-docker-%d", var.user_prefix, count.index + 1)}"
  zone = "${var.px_region_zone}"
  size = "64"
}

resource "google_compute_disk" "gcp-disk1-pd" {
  count = "${var.px_node_count}"
  name = "${format("px-gcp-%s-disk1-%d", var.user_prefix, count.index + 1)}"
  zone = "${var.px_region_zone}"
  size = "128"
}

resource "google_compute_disk" "gcp-disk2-pd" {
  count = "${var.px_node_count}"
  name = "${format("px-gcp-%s-disk2-%d", var.user_prefix, count.index + 1)}"
  zone = "${var.px_region_zone}"
  size = "64"
}
