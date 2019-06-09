variable "vpc_cidr" {}

variable "aws_tags" {
  type = "map"
}

resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc_cidr}"
  instance_tenancy     = "default"         # shared hardware
  enable_dns_support   = "true"            #Indicates whether the DNS resolution is supported.
  enable_dns_hostnames = "true"           #Indicates whether instances with public IP addresses get corresponding public DNS hostnames.
  tags                 = "${var.aws_tags}"
}

resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = "${aws_vpc.main.id}"
  tags   = "${var.aws_tags}"
}

resource "aws_route_table" "vpc_routetable_public" {
  vpc_id = "${aws_vpc.main.id}"
  tags   = "${merge(var.aws_tags,map("network","public"))}"
}

resource "aws_route_table" "vpc_routetable_private" {
  vpc_id = "${aws_vpc.main.id}"
  tags   = "${merge(var.aws_tags,map("network","private"))}"
}

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "private_routetable_id" {
  value = "${aws_route_table.vpc_routetable_private.id}"
}

output "public_routetable_id" {
  value = "${aws_route_table.vpc_routetable_public.id}"
}

output "igw_id" {
  value = "${aws_internet_gateway.vpc_igw.id}"
}
