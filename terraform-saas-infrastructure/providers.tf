provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "SaaS-Infrastructure"
      Environment = terraform.workspace
      ManagedBy   = "Terraform"
    }
  }
}
