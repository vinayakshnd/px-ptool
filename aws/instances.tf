provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

resource "aws_instance" "px-node" {
  ami = "${var.px_image}"
  count = "${var.setup_ecs ? 0 : var.px_node_count}"
  instance_type = "${var.px_vm_size}"
  key_name = "${var.px_key_name}"
  availability_zone = "${var.availability_zone}"
  tags {
    Name = "px-node-${var.user_prefix}-${count.index}"
  }
}

resource "null_resource" "post_install" {
  count = "${var.setup_ecs ? 0 : var.px_node_count}"

  provisioner "local-exec" {
      command = "sleep 180"
  }

  provisioner "local-exec" {
      command = "scp -i ${var.private_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null scripts/post_install.sh ${var.default_user}@${element(aws_instance.px-node.*.public_ip, count.index)}:/tmp/post_install.sh"
  }

  provisioner "local-exec" {
      command = "ssh -i ${var.private_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${var.default_user}@${element(aws_instance.px-node.*.public_ip, count.index)} 'sudo chmod +x /tmp/post_install.sh;sudo /tmp/post_install.sh ${var.vm_admin_user} ${var.vm_admin_password} ${var.px_ent_uuid} ${var.docker_image} ${element(aws_instance.px-node.*.private_ip, count.index)} ${var.docker_image}'"
  }
}


