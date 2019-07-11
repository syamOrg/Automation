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

data "aws_iam_policy_document" "kubernetes_master_policy_doc" {
  statement {
    actions = [
      "ec2:AttachVolume",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
      "ec2:RevokeSecurityGroupIngress",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/KubernetesCluster"
      values   = ["${var.kubernetes_clustername}"]
    }
  }

  statement {
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/KubernetesCluster"
      values   = ["${var.kubernetes_clustername}"]
    }
  }

  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:GetHostedZone",
    ]

    resources = ["arn:aws:route53:::hostedzone/${aws_route53_zone.kopsdev_private.zone_id}"]
  }

  statement {
    actions = [
      "route53:GetChange",
    ]

    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:GetEncryptionConfiguration",
      "s3:ListBucket",
      "s3:Get*",
    ]

    resources = ["${aws_s3_bucket.kops_state.arn}*"]
  }

  statement {
    actions = [
      "iam:ListServerCertificates",
      "iam:GetServerCertificate",
      "route53:ListHostedZones",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DescribeVolumesModifications",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyVolume",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:AttachLoadBalancerToSubnets",
      "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancerPolicy",
      "elasticloadbalancing:CreateLoadBalancerListeners",
      "elasticloadbalancing:ConfigureHealthCheck",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancerListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DetachLoadBalancerFromSubnets",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
      "ec2:DescribeVpcs",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerPolicies",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchGetImage",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "kubernetes_node_policy_doc" {
  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:GetEncryptionConfiguration",
      "s3:ListBucket",
      "s3:Get*",
    ]

    resources = ["${aws_s3_bucket.kops_state.arn}*"]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchGetImage",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "kubernetes_node_policy" {
  name   = "${var.kubernetes_node_iam_role_name}"
  policy = "${data.aws_iam_policy_document.kubernetes_node_policy_doc.json}"
}

resource "aws_iam_policy" "kubernetes_master_policy" {
  name   = "${var.kubernetes_master_iam_role_name}"
  policy = "${data.aws_iam_policy_document.kubernetes_master_policy_doc.json}"
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "kubernetes_node_role" {
  name               = "${var.kubernetes_node_iam_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.instance-assume-role-policy.json}"
  force_detach_policies  = "true"
}

resource "aws_iam_role" "kubernetes_master_role" {
  name               = "${var.kubernetes_master_iam_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.instance-assume-role-policy.json}"
  force_detach_policies  = "true"
}

resource "aws_iam_role_policy_attachment" "kubernetes_master_attach" {
  role       = "${aws_iam_role.kubernetes_master_role.name}"
  policy_arn = "${aws_iam_policy.kubernetes_master_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "kubernetes_node_attach" {
  role       = "${aws_iam_role.kubernetes_node_role.name}"
  policy_arn = "${aws_iam_policy.kubernetes_node_policy.arn}"
}


resource "aws_iam_instance_profile" "kubernetes_master_ip" {
  name = "${var.kubernetes_master_iam_role_name}"
  role       = "${aws_iam_role.kubernetes_master_role.name}"
}


resource "aws_iam_instance_profile" "kubernetes_node_ip" {
  name = "${var.kubernetes_node_iam_role_name}"
  role       = "${aws_iam_role.kubernetes_node_role.name}"
}

data "aws_vpc" "kubernetesvpc" {
  id = "${data.terraform_remote_state.backend_vpc.vpc_id}"
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
  force_destroy = true

  versioning {
    enabled = true
  }

  tags = {
    Application = "kops"
  }
}

resource "aws_security_group" "kops_app_sg" {
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
  security_group_id = "${aws_security_group.kops_app_sg.id}"
}

resource "aws_security_group_rule" "ingress_2" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["${concat(data.aws_subnet.privatecidrs.*.cidr_block,data.aws_subnet.publiccidrs.*.cidr_block)}"]
  security_group_id = "${aws_security_group.kops_app_sg.id}"
}

resource "aws_security_group_rule" "ingress_3" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kops_app_sg.id}"
}

resource "aws_security_group_rule" "ingress_4" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kops_app_sg.id}"
}

resource "aws_security_group_rule" "ingress_5" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kops_app_sg.id}"
}

resource "aws_security_group_rule" "ingress_6" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${concat(data.aws_subnet.privatecidrs.*.cidr_block,data.aws_subnet.publiccidrs.*.cidr_block)}"]
  security_group_id = "${aws_security_group.kops_app_sg.id}"
}

resource "aws_security_group_rule" "ingress_7" {
  type              = "ingress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
    cidr_blocks       = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.kops_app_sg.id}"
  #self              = "true"
}

resource "aws_security_group_rule" "egress_1" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${concat(data.aws_subnet.privatecidrs.*.cidr_block,data.aws_subnet.publiccidrs.*.cidr_block)}"]
  security_group_id = "${aws_security_group.kops_app_sg.id}"
}

resource "aws_security_group_rule" "egress_2" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["${concat(data.aws_subnet.privatecidrs.*.cidr_block,data.aws_subnet.publiccidrs.*.cidr_block)}"]
  security_group_id = "${aws_security_group.kops_app_sg.id}"
}

resource "aws_security_group_rule" "egress_3" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kops_app_sg.id}"
}

resource "aws_security_group_rule" "egress_4" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kops_app_sg.id}"
}

resource "aws_security_group_rule" "egress_5" {
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kops_app_sg.id}"
  #self              = "true"
}



resource "aws_security_group" "kops_elb_sg" {
  name        = "kops_elb_sg"
  description = "kops elb security group"
  vpc_id      = "${data.terraform_remote_state.backend_vpc.vpc_id}"
}

resource "aws_security_group_rule" "elb_ingress_1" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kops_elb_sg.id}"
}

resource "aws_security_group_rule" "elb_ingress_2" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kops_elb_sg.id}"
}
resource "aws_security_group_rule" "elb_ingress_3" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kops_elb_sg.id}"
}

resource "aws_security_group_rule" "elb_egress_1" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.kops_elb_sg.id}"
  source_security_group_id = "${aws_security_group.kops_app_sg.id}"
}

resource "aws_security_group_rule" "elb_egress_2" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.kops_elb_sg.id}"
  source_security_group_id = "${aws_security_group.kops_app_sg.id}"
}

resource "aws_security_group_rule" "elb_egress_3" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.kops_elb_sg.id}"
  source_security_group_id = "${aws_security_group.bastion_sg.id}"
}
resource "aws_security_group_rule" "elb_egress_4" {
  type                     = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id        = "${aws_security_group.kops_elb_sg.id}"
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
