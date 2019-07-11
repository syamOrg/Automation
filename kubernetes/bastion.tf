variable "aws_amis" {
  default = {
    eu-west-1 = "ami-6d48500b"
    us-west-2 = "ami-835b4efa"
    us-east-1 = "ami-09ef280df1a6a5330"
  }
}

variable "aws_instance_type" {
  default = "t2.medium"
}

variable "aws_default_user" {
  description = "Name of the AWS key pair"
  default     = "ubuntu"
}

resource "aws_key_pair" "bastion_auth" {
  key_name   = "${var.aws_default_user}"
  public_key = "${file(format("./../files/userkeys/%s_rsa.pub",var.aws_default_user))}"
}

resource "aws_eip" "bastion_eip" {
  instance = "${aws_instance.aws_instances.id}"
  vpc      = true
}

resource "aws_instance" "aws_instances" {
  ami               = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type     = "${var.aws_instance_type}"
  key_name          = "${aws_key_pair.bastion_auth.key_name}"
  security_groups   = ["${aws_security_group.bastion_sg.id}"]
  subnet_id         = "${element(data.terraform_remote_state.backend_vpc.public_subnet_ids,0)}"
  get_password_data = "true"

  lifecycle {
    ignore_changes = ["ebs_block_device", "security_groups"]
  }

  tags = {
    "Name" = "Bastion Windows"
  }
}

output "bastion_passwordata" {
  value = "${aws_instance.aws_instances.password_data}"
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "bastion security group"
  vpc_id      = "${data.terraform_remote_state.backend_vpc.vpc_id}"
}

resource "aws_security_group_rule" "ingress_bastion1" {
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.bastion_sg.id}"
}

resource "aws_security_group_rule" "egress_bastion1" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${concat(data.aws_subnet.privatecidrs.*.cidr_block)}"]
  security_group_id = "${aws_security_group.bastion_sg.id}"
}

resource "aws_security_group_rule" "egress_bastion2" {
  type              = "egress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.bastion_sg.id}"
}

resource "aws_security_group_rule" "egress_bastion3" {
  type              = "egress"
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.bastion_sg.id}"
}
