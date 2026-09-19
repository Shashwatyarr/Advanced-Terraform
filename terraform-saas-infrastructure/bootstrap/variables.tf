variable "aws_region" {
  description = "AWS region to deploy the backend resources."
  type        = string
  default     = "us-east-1"
}

variable "backend_bucket_name" {
  description = "Name of the S3 bucket for Terraform state (must be globally unique)."
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking."
  type        = string
  default     = "saas-terraform-state-locks"
}

variable "project_name" {
  description = "Name of the project."
  type        = string
  default     = "SaaS-Infrastructure"
}
