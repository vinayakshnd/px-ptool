resource "google_compute_instance" "px-gcp-node" {
  count = "${var.px_node_count}"
  name = "px-gcp-node-${var.user_prefix}-${count.index + 1}"
  machine_type = "${var.px_vm_size}"
  zone         = "${var.px_region_zone}"
  tags         = ["px-dev"]
  disk {
    image = "${var.px_image}" // the operative system (and Linux flavour) that your machine will run
    size  = 15
  }
  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
    }
  }
    metadata {
    ssh-keys = "root:${file("${var.public_key_path}")}"
  }

}
