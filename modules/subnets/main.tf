variable "vpc_public_subnets" {
  type = "list"
}

variable "vpc_private_subnets" {
  type = "list"
}

variable "vpc_subnet_az" {
  type = "list"
}
variable "aws_tags" {
  type = "map"
}


variable "vpc_id" {}

variable "private_routetable_id" {}
variable "public_routetable_id" {}

resource "aws_subnet" "subnet_public" {
  count             = "${length(var.vpc_public_subnets)}"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${element(var.vpc_public_subnets,count.index)}"
  availability_zone = "${element(var.vpc_subnet_az,count.index)}"
  tags              = "${merge(var.aws_tags,map("network","public"))}"
}

resource "aws_subnet" "subnet_private" {
  count             = "${length(var.vpc_private_subnets)}"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${element(var.vpc_private_subnets,count.index)}"
  availability_zone = "${element(var.vpc_subnet_az,count.index)}"
  tags              = "${merge(var.aws_tags,map("network","private"))}"
}

resource "aws_route_table_association" "public_subnet_associate" {
  count             = "${length(var.vpc_public_subnets)}"
  subnet_id      = "${element(aws_subnet.subnet_public.*.id,count.index)}"
  route_table_id = "${var.public_routetable_id}"
}

resource "aws_route_table_association" "private_subnet_associate" {
  count             = "${length(var.vpc_private_subnets)}"
  subnet_id      = "${element(aws_subnet.subnet_private.*.id,count.index)}"
  route_table_id = "${var.private_routetable_id}"
}

output "public_subnet_ids" {
  value = "${aws_subnet.subnet_public.*.id}"
}

output "private_subnet_ids" {
  value = "${aws_subnet.subnet_private.*.id}"
}
