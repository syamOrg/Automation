variable "aws_region" {
  description = "AWS regione where launch servers"
  default     = "us-east-1"
}

variable "aws_amis" {
  default = {
    us-east-1 = "ami-02eac2c0129f6376b"
  }
}

variable "aws_instance_hostnames" {
  type = "list"
}

variable "aws_instance_type" {
  default = "t2.medium"
}

variable "aws_default_user" {
  description = "Name of the AWS key pair"
}

variable "additional_users" {
  description = "List of additional users to add along with default user"
  default     = []
  type        = "list"
}

variable "aws_instancetags" {
  type = "map"
}

variable "tomcat_url" {}

variable "app_env" {
  description = "Environment of the app"
}
