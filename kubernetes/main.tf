provider "aws" {
  region = "${var.aws_region}"
}

data "terraform_remote_state" "backend_vpc" {
  backend = "s3"

  config {
    bucket = "sams3backend1"
    key    = "vpc/terraform.tfsate"
    region = "${var.aws_region}"
  }
}

locals {
  private_subnetids = "${join(" ",data.terraform_remote_state.backend_vpc.private_subnet_ids)}"
  public_subnetids  = "${join(" ",data.terraform_remote_state.backend_vpc.public_subnet_ids)}"
}

## Add tags to the existing subnets for public and Private ELB

# profile might be needed depending on the environment configuration
resource "null_resource" "kubernetes_tags_update" {
  triggers = {
    trigger_a = "${local.private_subnetids}"
    trigger_b = "${local.public_subnetids}"
  }

  provisioner "local-exec" {
    command = "aws ec2 create-tags --resources ${local.private_subnetids} --tags 'Key=kubernetes.io/role/internal-elb,Value=1' --region ${var.aws_region}"
  }

  provisioner "local-exec" {
    command = "aws ec2 create-tags --resources ${local.public_subnetids}  --tags 'Key=kubernetes.io/role/elb,Value=1' --region ${var.aws_region}"
  }
}

resource "aws_route53_zone" "kopsdev_private" {
  name = "kopsdev.com"

  vpc {
    vpc_id = "${data.terraform_remote_state.backend_vpc.vpc_id}"
  }
}

resource "aws_s3_bucket" "kops_state" {
  bucket = "kopsstate123445"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Application = "kops"
  }
}

data "template_file" "kopsyaml_template" {
  template = "${(file("./../files/templates/kops.yaml.tpl"))}"

  vars {
  }
}

resource "local_file" "kopsyaml_renderted" {
    content     = "${data.template_file.kopsyaml_template.rendered}"
    filename = "kops.yaml"
}

resource "aws_security_group" "kops_agg_sg" {
  name        = "kops_app_sg"
  description = "kops application security group"
  vpc_id      = "${data.terraform_remote_state.backend_vpc.vpc_id}"
}

resource "aws_security_group_rule" "ingress_1" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${concat(data.aws_subnet.privatecidrs.*.cidr_block,data.aws_subnet.publiccidrs.*.cidr_block)}"]
  security_group_id = "${aws_security_group.kops_agg_sg.id}"
}

resource "aws_security_group_rule" "ingress_2" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["${concat(data.aws_subnet.privatecidrs.*.cidr_block,data.aws_subnet.publiccidrs.*.cidr_block)}"]
  security_group_id = "${aws_security_group.kops_agg_sg.id}"
}

resource "aws_security_group_rule" "ingress_3" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kops_agg_sg.id}"
}

resource "aws_security_group_rule" "ingress_4" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kops_agg_sg.id}"
}

resource "aws_security_group_rule" "ingress_5" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kops_agg_sg.id}"
}

resource "aws_security_group_rule" "ingress_6" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${concat(data.aws_subnet.privatecidrs.*.cidr_block,data.aws_subnet.publiccidrs.*.cidr_block)}"]
  security_group_id = "${aws_security_group.kops_agg_sg.id}"
}

resource "aws_security_group_rule" "ingress_7" {
  type                     = "ingress"
  protocol                 = "tcp"
  from_port         = 0
  to_port           = 0
  security_group_id        = "${aws_security_group.kops_agg_sg.id}"
  self = "true"
}

resource "aws_security_group_rule" "egress_1" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${concat(data.aws_subnet.privatecidrs.*.cidr_block,data.aws_subnet.publiccidrs.*.cidr_block)}"]
  security_group_id = "${aws_security_group.kops_agg_sg.id}"
}

resource "aws_security_group_rule" "egress_2" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["${concat(data.aws_subnet.privatecidrs.*.cidr_block,data.aws_subnet.publiccidrs.*.cidr_block)}"]
  security_group_id = "${aws_security_group.kops_agg_sg.id}"
}

resource "aws_security_group_rule" "egress_3" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kops_agg_sg.id}"
}

resource "aws_security_group_rule" "egress_4" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kops_agg_sg.id}"
}

resource "aws_security_group_rule" "egress_5" {
  type                     = "egress"
  protocol                 = "tcp"
  from_port         = 0
  to_port           = 0
  security_group_id        = "${aws_security_group.kops_agg_sg.id}"
  self = "true"
  }

#https://kubernetes.io/docs/setup/production-environment/tools/kops/
#https://www.terraform.io/docs/providers/aws/r/route53_zone.html
#https://www.terraform.io/docs/providers/aws/r/route53_record.html

output "kopsdev_nameservers" {
  value = "${aws_route53_zone.kopsdev_private.name_servers}"
}

output "privatezone_id" {
  value = "${aws_route53_zone.kopsdev_private.zone_id}"
}
