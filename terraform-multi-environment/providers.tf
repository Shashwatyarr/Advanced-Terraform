provider "aws" {
  region = var.aws_region
}

# 1. Data Block: Discover available Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# 2. Data Block: Discover the Default VPC
data "aws_vpc" "default" {
  default = true
}

# 3. Data Block: Discover subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] 

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
