provider "aws" {
  region = "${var.region}"
}

data "terraform_remote_state" "backend_vpc" {
  backend = "s3"

  config {
    bucket = "sams3backend1"
    key    = "vpc/terraform.tfsate"
    region = "us-east-1"
  }
}

resource "aws_route53_zone" "kakfa_zone" {
  name = "${var.route53_hosted_zone_name}"

  tags {
    project = "${var.project}"
  }
}

resource "aws_route53_record" "default-ns" {
  zone_id = "${aws_route53_zone.kakfa_zone.id}"
  name    = "${var.project}.${var.route53_hosted_zone_name}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.kakfa_zone.name_servers.0}",
    "${aws_route53_zone.kakfa_zone.name_servers.1}",
    "${aws_route53_zone.kakfa_zone.name_servers.2}",
    "${aws_route53_zone.kakfa_zone.name_servers.3}",
  ]
}

data "aws_iam_policy_document" "kafka_policy" {
  statement {
    actions = [
      "route53:*",
    ]

    effect = "Allow"

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "kafka_policy_role" {
  name   = "${var.kafka_iam_role_prefix}-policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.kafka_policy.json}"
}

resource "aws_iam_role" "kafka_role" {
  name                  = "${var.kafka_iam_role_prefix}-role"
  force_detach_policies = "true"

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

resource "aws_iam_role_policy_attachment" "kafka_role_attach" {
  role       = "${aws_iam_role.kafka_role.name}"
  policy_arn = "${aws_iam_policy.kafka_policy_role.arn}"
}

resource "aws_iam_instance_profile" "kafka_profile" {
  name = "${var.kafka_iam_role_prefix}-profile"
  role = "${aws_iam_role.kafka_role.name}"
}

resource "aws_key_pair" "kafka_user" {
  key_name   = "${var.aws_default_user}"
  public_key = "${file(format("./../files/userkeys/%s_rsa.pub",var.aws_default_user))}"
}
