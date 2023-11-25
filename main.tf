# setting
terraform {
  required_version = "~> 1.4.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.22.0"
    }
  }
}

# aws provider
provider "aws" {
  region = "ap-northeast-1"
}

# VPC
resource "aws_vpc" "sample" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "sample-vpc"
  }
}

# IGW
resource "aws_internet_gateway" "sample" {
  vpc_id = aws_vpc.sample.id
  tags = {
    "Name" = "sample-igw"
  }
}

# public subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.sample.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "sample-public"
  }
}

# route table
resource "aws_route_table" "sample_route_table" {
  vpc_id = aws_vpc.sample.id
}

# route → toute table
resource "aws_route" "route_to_igw" {
  route_table_id = aws_route_table.sample_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.sample.id
  depends_on = [aws_route_table.sample_route_table]
}

# route table → public subnet
resource "aws_route_table_association" "with_public_subnet" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.sample_route_table.id
}

# security group
resource "aws_security_group" "sample" {
  name = "allow-http"
  vpc_id = aws_vpc.sample.id
}

# security group rule
resource "aws_security_group_rule" "allow_http_from_anywhere" {
  type = "ingress"
  protocol = "tcp"
  from_port = 80
  to_port = 80
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sample.id
}

resource "aws_security_group_rule" "allow_all_to_internet" {
  type = "egress"
  protocol = "-1"
  to_port = 0
  from_port = 0
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sample.id
}

# EC2 instance
resource "aws_instance" "sample" {
  ami = "ami-088da9557aae42f39"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sample.id]
  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y nginx
              EOF
}
