terraform {
  backend "s3" {
    bucket = "sams3backend1"
    key    = "bastion/terraform.tfsate"
    region = "us-east-1"
  }
}