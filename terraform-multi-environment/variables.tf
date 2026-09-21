variable "aws_region" {
  description = "The AWS region to deploy infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The project name used for tagging and resource naming"
  type        = string
  default     = "multi-env-eval"
}

variable "environment_override" {
  description = "Optional override for environment. Typically, terraform.workspace is used."
  type        = string
  default     = ""
}

variable "ssh_cidr" {
  description = "The CIDR block allowed to connect via SSH"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.ssh_cidr))
    error_message = "Must be a valid IPv4 CIDR block format."
  }
}

variable "bucket_prefix" {
  description = "Prefix for the S3 bucket to ensure global uniqueness"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type override (optional). If empty, workspace defaults from locals will be used."
  type        = string
  default     = ""
}

variable "instance_count" {
  description = "EC2 instance count override (optional). If 0, workspace defaults from locals will be used."
  type        = number
  default     = 0
}
