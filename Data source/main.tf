# variable "aws_vpc"{
#   # description = "VPC name to use for the EC2 instance"
#   # type        = string
#   # default     = "default"
# }

provider "aws" {
  region = "ap-south-1"
}

data "aws_vpc" "vpc_name" {
  filter {
    name   = "tag:Name"
    values = ["default"]
  }
}

data aws_subnet "shared"{
  filter {
    name   = "tag:Name"
    values = ["subneta"]
  }
  vpc_id= data.aws_vpc.vpc_name.id
}

data "aws_ami" "linux2" {
  owners =["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter{
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.linux2.id
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnet.shared.id
  tags = var.resource_tags
}

