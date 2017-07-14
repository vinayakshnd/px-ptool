output "do_droplets" {
  value = ["${digitalocean_droplet.px-node-droplet.*.name}"]
}

output "do_swap_volumes" {
  value = ["${digitalocean_volume.do-swap-vol.*.name}"]
}

output "do_docker_volumes" {
  value = ["${digitalocean_volume.do-docker-vol.*.name}"]
}

output "do_disk1_volumes" {
  value = ["${digitalocean_volume.do-disk1-vol.*.name}"]
}

output "do_disk2_volumes" {
  value = ["${digitalocean_volume.do-disk2-vol.*.name}"]
}