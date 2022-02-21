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

resource "aws_key_pair" "vpn_ssh_key" {
  key_name   = "jrh-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJBpO6q3N1piA8l99ikZE71G55PoDKZNjO8kq2ja0vW jrhdev"
}

resource "aws_vpc" "vpn_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "VPNVPC"
  }
}

resource "aws_internet_gateway" "vpn_gw" {
  vpc_id = aws_vpc.vpn_vpc.id
  tags = {
    Name = "VPNInternetGateway"
  }
}

resource "aws_subnet" "vpn_subnet" {
  vpc_id              = aws_vpc.vpn_vpc.id
  cidr_block          = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "VPNSubnet"
  }
}

resource "aws_route_table" "vpn_route_table" {
  vpc_id = aws_vpc.vpn_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpn_gw.id
  }
  tags = {
    Name = "VPNRoute"
  }
}

resource "aws_route_table_association" "vpn_subnet_route_assoc" {
  subnet_id      = aws_subnet.vpn_subnet.id
  route_table_id = aws_route_table.vpn_route_table.id
}

resource "aws_security_group" "vpn_sg" {
  name        = "vpn_sg"
  vpc_id      = aws_vpc.vpn_vpc.id

  ingress {
    description      = "SSH Clients to VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

#  ingress {
#    description      = "Wireguard Clients to VPC"
#    from_port        = 51820
#    to_port          = 51820
#    protocol         = "tcp"
#    cidr_blocks      = ["0.0.0.0/0"]
#  }

#  egress {
#    description     = "VPC to SSH Clients"
#    from_port       = 22
#    to_port         = 22
#    protocol        = "tcp"
#    cidr_blocks     = ["0.0.0.0/0"]
#  }

#  egress {
#    description     = "VPC to Wireguard Clients"
#    from_port       = 51820
#    to_port         = 51820
#    protocol        = "tcp"
#    cidr_blocks     = ["0.0.0.0/0"]
#  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "VPNSecurityGroup"
  }
}

resource "aws_instance" "vpn_server" {
  ami           = "ami-01f87c43e618bf8f0"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.vpn_subnet.id
  vpc_security_group_ids = [ aws_security_group.vpn_sg.id ]
  key_name = aws_key_pair.vpn_ssh_key.key_name
  depends_on = [
    aws_internet_gateway.vpn_gw
  ]
  tags = {
    Name = "VPNServer"
  }
}