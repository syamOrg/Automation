data "aws_subnet" "privatecidrs" {
  count = "${length(data.terraform_remote_state.backend_vpc.private_subnet_ids)}"
  id    = "${element(data.terraform_remote_state.backend_vpc.private_subnet_ids,count.index)}"
}

data "aws_subnet" "publiccidrs" {
  count = "${length(data.terraform_remote_state.backend_vpc.public_subnet_ids)}"
  id    = "${element(data.terraform_remote_state.backend_vpc.public_subnet_ids,count.index)}"
}
