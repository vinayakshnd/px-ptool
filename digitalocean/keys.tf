resource "digitalocean_ssh_key" "default" {
  name       = "px-ssh-key"
  public_key = "${file("${var.public_key_file}")}"
}
