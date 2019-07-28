output "hosted_zone_name" {
  value = "${aws_route53_zone.kakfa_zone.name}"
}
