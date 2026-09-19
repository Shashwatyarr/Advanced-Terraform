provider "aws" {
  region = var.aws_region

  # Default tags applied to all resources created by this provider
  default_tags {
    tags = {
      Project     = "SaaS-Infrastructure"
      Environment = terraform.workspace
      ManagedBy   = "Terraform"
    }
  }
}
