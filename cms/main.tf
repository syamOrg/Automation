provider "aws" {
  region = "${var.aws_region}"
}

data "terraform_remote_state" "backend_vpc" {
  backend = "s3"

  config {
    bucket = "sams3backend"
    key    = "vpc/terraform.tfsate"
    region = "us-east-1"
  }
}

resource "aws_key_pair" "aws_auth" {
  key_name   = "${var.aws_default_user}"
  public_key = "${file(format("./../files/userkeys/%s_rsa.pub",var.aws_default_user))}"
}

resource "aws_security_group" "cms_agg_sg" {
  name        = "cms_app_sg"
  description = "cms application security group"
  vpc_id      = "${data.terraform_remote_state.backend_vpc.vpc_id}"
}

resource "aws_security_group_rule" "ingress_1" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${concat(data.aws_subnet.privatecidrs.*.cidr_block,data.aws_subnet.publiccidrs.*.cidr_block)}"]
  security_group_id = "${aws_security_group.cms_agg_sg.id}"
}

resource "aws_security_group_rule" "ingress_2" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["${concat(data.aws_subnet.privatecidrs.*.cidr_block,data.aws_subnet.publiccidrs.*.cidr_block)}"]
  security_group_id = "${aws_security_group.cms_agg_sg.id}"
}

resource "aws_security_group_rule" "ingress_3" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.cms_agg_sg.id}"
}

resource "aws_security_group_rule" "ingress_4" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.cms_agg_sg.id}"
}

resource "aws_security_group_rule" "egress_1" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${concat(data.aws_subnet.privatecidrs.*.cidr_block,data.aws_subnet.publiccidrs.*.cidr_block)}"]
  security_group_id = "${aws_security_group.cms_agg_sg.id}"
}

resource "aws_security_group_rule" "egress_2" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["${concat(data.aws_subnet.privatecidrs.*.cidr_block,data.aws_subnet.publiccidrs.*.cidr_block)}"]
  security_group_id = "${aws_security_group.cms_agg_sg.id}"
}

resource "aws_security_group_rule" "egress_3" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.cms_agg_sg.id}"
}

resource "aws_security_group_rule" "egress_4" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.cms_agg_sg.id}"
}

data "template_file" "install_cms" {
  template = "${(file("./../files/templates/init_cms.tpl"))}"
  count    = "${length(var.aws_instance_hostnames)}"

  vars {
    elk_useradd       = "${join("\n",data.template_file.add_users.*.rendered)}"
    instance_hostname = "${element(var.aws_instance_hostnames,count.index)}"
    tomcat_url        = "${var.tomcat_url}"
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

resource "aws_eip" "temp_eip" {
  count      = "${length(var.aws_instance_hostnames)}"
  instance   = "${element(aws_instance.awsinstances.*.id,count.index)}"
  vpc        = true
  depends_on = ["aws_instance.awsinstances"]
}

output "instanceips" {
  value = "${join(",",aws_eip.temp_eip.*.public_ip)}"
}

locals {
  cms_privateips = "${aws_instance.awsinstances.*.private_ip}"
  cms_publicips  = "${join(",",aws_eip.temp_eip.*.public_ip)}"
}

resource "aws_instance" "awsinstances" {
  count           = "${length(var.aws_instance_hostnames)}"
  ami             = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type   = "${var.aws_instance_type}"
  key_name        = "${aws_key_pair.aws_auth.key_name}"
  security_groups = ["${aws_security_group.cms_agg_sg.id}"]
  subnet_id       = "${element(data.terraform_remote_state.backend_vpc.public_subnet_ids,count.index)}"

  #https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html
  ebs_block_device = {
    device_name = "/dev/xvdb"
    volume_type = "gp2"
    volume_size = "20"
    iops        = "500"
  }

  lifecycle {
    ignore_changes = ["ebs_block_device", "security_groups"]
  }

  user_data   = "${element(data.template_file.install_cms.*.rendered,count.index)}"
  volume_tags = "${var.aws_instancetags}"
  tags        = "${var.aws_instancetags}"
}

resource "null_resource" "configuration" {
  triggers = {
    trigger_a = "${sha1(file("../files/ansible_plays/cms/main.yml"))}"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ${local.cms_publicips}, ../files/ansible_plays/cms/main.yml -e tomcat_url=${var.tomcat_url} -e ansible_python_interpreter=/usr/bin/python -e app_env=${var.app_env}"

    environment = {
      ANSIBLE_HOST_KEY_CHECKING   = "False"
      ANSIBLE_PYTHON_INTERPRETER  = "/usr/bin/python"
      ANSIBLE_BECOME              = "True"
      ANSIBLE_REMOTE_USER         = "centos"
      ANSIBLE_PRIVATE_KEY_FILE    = "/home/nero/.ssh/id_rsa"
      ANSIBLE_RETRY_FILES_ENABLED = "False"
    }
  }
}
