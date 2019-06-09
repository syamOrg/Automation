terraform {
  backend "s3" {
    bucket = "sams3backend"
    key    = "vpc/terraform.tfsate"
    region = "us-east-1"
  }
}