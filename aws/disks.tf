resource "aws_ebs_volume" "px_swap_vol" {
    availability_zone = "${var.availability_zone}"
    size = "${var.swap_vol_size}"
    count = "${var.px_node_count}"
    tags {
      Name = "px_swap_vol-${var.user_prefix}_${count.index}"
    }
}

resource "aws_ebs_volume" "px_docker_vol" {
    availability_zone = "${var.availability_zone}"
    size = "${var.docker_vol_size}"
    count = "${var.px_node_count}"
    tags {
      Name = "px_docker_vol_${var.user_prefix}_${count.index}"
    }
}

resource "aws_ebs_volume" "px_disk1_vol" {
    availability_zone = "${var.availability_zone}"
    size = "${var.disk1_vol_size}"
    count = "${var.px_node_count}"
    tags {
      Name = "px_disk1_vol_${var.user_prefix}_${count.index}"
    }
}

resource "aws_ebs_volume" "px_disk2_vol" {
    availability_zone = "${var.availability_zone}"
    size = "${var.disk2_vol_size}"
    count = "${var.px_node_count}"
    tags {
      Name = "px_disk2_vol_${var.user_prefix}_${count.index}"
    }
}

resource "aws_volume_attachment" "swap_vol_attach" {
  device_name = "/dev/sdd"
  count = "${var.px_node_count}"
  volume_id   = "${element(aws_ebs_volume.px_swap_vol.*.id, count.index)}"
  instance_id = "${element(aws_instance.px-node.*.id, count.index)}"
  force_detach = true
}

resource "aws_volume_attachment" "docker_vol_attach" {
  device_name = "/dev/sdc"
  count = "${var.px_node_count}"
  volume_id   = "${element(aws_ebs_volume.px_docker_vol.*.id, count.index)}"
  instance_id = "${element(aws_instance.px-node.*.id, count.index)}"
  force_detach = true
}

resource "aws_volume_attachment" "disk1_vol_attach" {
  device_name = "/dev/sde"
  count = "${var.px_node_count}"
  volume_id   = "${element(aws_ebs_volume.px_disk1_vol.*.id, count.index)}"
  instance_id = "${element(aws_instance.px-node.*.id, count.index)}"
  force_detach = true
}

resource "aws_volume_attachment" "disk2_vol_attach" {
  device_name = "/dev/sdf"
  count = "${var.px_node_count}"
  volume_id   = "${element(aws_ebs_volume.px_disk2_vol.*.id, count.index)}"
  instance_id = "${element(aws_instance.px-node.*.id, count.index)}"
  force_detach = true
}