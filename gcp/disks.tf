resource "google_compute_disk" "gcp-pd" {
  count = "${var.px_node_count * var.px_disk_count}"
  name = "${format("px-gcp-vol-%s-%02d", var.user_prefix, (((count.index)/var.px_disk_count) + 1) *10 + 1 + (count.index % var.px_disk_count))}"
  zone = "${var.region_zone}"
  size = "${var.px-disk-size}"
}