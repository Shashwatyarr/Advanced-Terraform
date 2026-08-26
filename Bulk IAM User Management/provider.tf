# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  //required_version = ">= 1.0"
}
provider "aws" {
  alias  = "primary"
  region = var.primary
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary
}



