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
  region = var.primary_region
  alias="primary"
}

provider "aws" {
  region = var.secondary_region
  alias= "secondary"
}


