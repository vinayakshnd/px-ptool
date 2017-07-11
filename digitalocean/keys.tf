resource "digitalocean_ssh_key" "default" {
  name       = "px-ssh-key-${var.user_prefix}"
  public_key = "${file("${var.public_key_file}")}"
}
