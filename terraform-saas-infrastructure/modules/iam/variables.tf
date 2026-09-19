variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
}

variable "s3_bucket_arn" {
  description = "The ARN of the application S3 bucket to grant access to"
  type        = string
}
