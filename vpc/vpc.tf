variable "vpc_region" {}

provider "aws" {
  region = "${var.vpc_region}"
}

module "test_vpc" {
  source = "../modules/vpc"

  aws_tags = {
    Name = "test"
  }

  vpc_cidr = "10.97.0.0/16"
}

module "test_subnets" {
  source = "../modules/subnets"

  aws_tags = {
    Name = "test"
  }

  vpc_public_subnets    = ["10.97.25.0/26", "10.97.25.64/26"]
  vpc_private_subnets   = ["10.97.25.128/26", "10.97.25.192/26"]
  vpc_subnet_az         = ["us-east-1a", "us-east-1b"]
  vpc_id                = "${module.test_vpc.vpc_id}"
  private_routetable_id = "${module.test_vpc.private_routetable_id}"
  public_routetable_id  = "${module.test_vpc.public_routetable_id}"
}

resource "aws_route" "public_route1" {
  route_table_id         = "${module.test_vpc.public_routetable_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${module.test_vpc.igw_id}"
}

resource "aws_route" "private_route1" {
  route_table_id         = "${module.test_vpc.private_routetable_id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.vpc_ngw.id}"
}

resource "aws_eip" "vpc_nat" {
  vpc = true
}

resource "aws_nat_gateway" "vpc_ngw" {
  allocation_id = "${aws_eip.vpc_nat.id}"
  subnet_id     = "${element(module.test_subnets.public_subnet_ids,0)}"
}

output "vpc_id" {
  value = "${module.test_vpc.vpc_id}"
}

output "public_subnet_ids" {
  value = "${module.test_subnets.public_subnet_ids}"
}

output "private_subnet_ids" {
  value = "${module.test_subnets.private_subnet_ids}"
}

output "public_routetable_ids" {
  value = "${module.test_vpc.public_routetable_id}"
}

output "private_routetable_ids" {
  value = "${module.test_vpc.private_routetable_id}"
}

output "vpc_natgw_id" {
  value = "${aws_nat_gateway.vpc_ngw.id}"
}
