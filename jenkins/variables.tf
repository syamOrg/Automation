variable "aws_region" {
  description = "AWS regione where launch servers"
  default     = "us-east-1"
}

variable "aws_amis" {
  default = {
    eu-west-1 = "ami-6d48500b"
    us-west-2 = "ami-835b4efa"
    us-east-1 = "ami-01d9d5f6cecc31f85"
  }
}

variable "aws_instance_type" {
  default = "t2.medium"
}

variable "aws_default_user" {
  description = "Name of the AWS key pair"
}

variable "instance_count" {}

variable "additional_users" {
  description = "List of additional users to add along with default user"
  default     = []
  type        = "list"
}

variable "aws_instancetags" {
  type = "map"
}
