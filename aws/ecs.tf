resource "aws_ecs_cluster" "px-cluster" {
  name = "px-cluster-${var.user_prefix}"
  count = "${var.setup_ecs ? 1 : 0}"
}

resource "aws_iam_role" "ecs_roll" {
    name = "ecs_roll_${var.user_prefix}"
    count = "${var.setup_ecs ? 1 : 0}"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "ecs_for_ec2" {
    count = "${var.setup_ecs ? 1 : 0}"
    name = "ecs_for_ec2_${var.user_prefix}"
    roles = ["${aws_iam_role.ecs_roll.id}"]
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs-profile" {
  count = "${var.setup_ecs ? 1 : 0}"
  name = "ecs_profile_${var.user_prefix}"
  role = "${aws_iam_role.ecs_roll.name}"
}

resource "aws_instance" "px-ecs-node" {
  ami = "${var.px_image}"
  count = "${var.setup_ecs ? var.px_node_count : 0}"
  instance_type = "${var.px_vm_size}"
  key_name = "${var.px_key_name}"
  availability_zone = "${var.availability_zone}"
  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER="px-cluster-${var.user_prefix} >> /etc/ecs/ecs.config
EOF
  iam_instance_profile = "${aws_iam_instance_profile.ecs-profile.name}"
  tags {
    Name = "px-node-${var.user_prefix}-${count.index}"
  }
}

resource "null_resource" "post_install_ecs" {
  count = "${var.setup_ecs ? var.px_node_count : 0}"

  provisioner "local-exec" {
      command = "sleep 180"
  }

  provisioner "local-exec" {
      command = "scp -i ${var.private_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null scripts/post_install.sh ${var.default_user}@${element(aws_instance.px-ecs-node.*.public_ip, count.index)}:/tmp/post_install.sh"
  }

  provisioner "local-exec" {
      command = "ssh -i ${var.private_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${var.default_user}@${element(aws_instance.px-ecs-node.*.public_ip, count.index)} 'sudo chmod +x /tmp/post_install.sh;sudo /tmp/post_install.sh ${var.vm_admin_user} ${var.vm_admin_password} ${var.px_ent_uuid} ${var.docker_image} ${element(aws_instance.px-ecs-node.*.private_ip, count.index)} ${var.docker_image}'"
  }
}


