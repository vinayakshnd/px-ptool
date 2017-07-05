output "do_droplets" {
  value = ["${digitalocean_droplet.px-node-droplet.*.name}"]
}

output "do_volumes" {
  value = ["${digitalocean_volume.do-vol.*.name}"]
}