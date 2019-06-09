variable "vpc_id" {
  type = "string"
}

variable "private_subnet_ids" {
  type    = "list"
  default = []
}

variable "public_subnet_ids" {
  type    = "list"
  default = []
}
