provider "aws" {
  region = "${var.aws_region}"
}

data "terraform_remote_state" "backend_vpc" {
  backend = "s3"

  config {
    bucket = "sams3backend1"
    key    = "vpc/terraform.tfsate"
    region = "us-east-1"
  }
}

resource "aws_key_pair" "bastion_auth" {
  key_name   = "${var.aws_default_user}"
  public_key = "${file(format("./../files/userkeys/%s_rsa.pub",var.aws_default_user))}"
}

data "template_file" "install_bastion" {
  template = "${(file("./../files/templates/init_bastion.tpl"))}"

  vars {
    useradd = "${join("\n",data.template_file.add_users.*.rendered)}"
  }
}

data "template_file" "add_users" {
  count    = "${length(var.additional_users)}"
  template = "${(file("./../files/templates/user_add.tpl"))}"

  vars {
    user_name      = "${element(var.additional_users, count.index)}"
    user_publickey = "${file(format("./../files/userkeys/%s_rsa.pub",element(var.additional_users, count.index)))}"
  }
}

resource "aws_eip" "bastion_eip" {
  count      = "${var.instance_count}"
  instance   = "${element(aws_instance.aws_instances.*.id,count.index)}"
  vpc        = true
  depends_on = ["aws_instance.aws_instances"]
}

output "instanceips" {
  value = "${join(",",aws_eip.bastion_eip.*.public_ip)}"
}

locals {
  bastion_privateips = "${aws_instance.bastioninstances.*.private_ip}"
  bastion_publicips  = "${join(",",aws_eip.bastion_eip.*.public_ip)}"
}


resource "aws_instance" "aws_instances" {
  count = "${var.instance_count}"
  ami             = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type   = "${var.aws_instance_type}"
  key_name        = "${aws_key_pair.bastion_auth.key_name}"
  security_groups = ["${aws_security_group.bastion_sg.id}"]
  subnet_id       = "${element(data.terraform_remote_state.backend_vpc.public_subnet_ids,count.index)}"
  
  lifecycle {
    ignore_changes = ["ebs_block_device", "security_groups"]
  }

  user_data   = "${data.template_file.install_bastion.rendered}"
  volume_tags = "${var.aws_instancetags}"
  tags        = "${var.aws_instancetags}"
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "bastion security group"
  vpc_id      = "${data.terraform_remote_state.backend_vpc.vpc_id}"
}

resource "aws_security_group_rule" "ingress_1" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.bastion_sg.id}"
}


resource "aws_security_group_rule" "egress_1" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks = ["${concat(data.aws_subnet.privatecidrs.*.cidr_block)}"]
  security_group_id = "${aws_security_group.bastion_sg.id}"
}


resource "aws_security_group_rule" "egress_2" {
  type            = "egress"
  from_port       = "443"
  to_port         = "443"
  protocol        = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.bastion_sg.id}"
}

resource "aws_security_group_rule" "egress_3" {
  type            = "egress"
  from_port       = "80"
  to_port         = "80"
  protocol        = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.bastion_sg.id}"
}
