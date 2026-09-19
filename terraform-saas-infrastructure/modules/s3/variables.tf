variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
}

variable "bucket_name_prefix" {
  description = "Prefix for the S3 bucket name. The environment and a random hash will be appended."
  type        = string
  default     = "saas-app-data"
}
