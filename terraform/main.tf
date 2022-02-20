terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-west-1"
}

resource "aws_vpc" "vpn_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "VPNVPC"
  }
}

resource "aws_instance" "vpn_server" {
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"
  associate_public_ip_address = true

  tags = {
    Name = "VPNServer"
  }
}
