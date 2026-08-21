terraform {
    backend "s3" {
    bucket = "shashwatsrivastava-terraform-state" //an s3 bucket that you have to create before hand with the same name
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "first_bucket" {
  bucket = "s3bucketwithterraform03972554"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

