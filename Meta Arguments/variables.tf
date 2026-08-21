variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)

  default = {
    Environment = "staging"
    Project     = "Terraform"
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

# variable "bucket_name" {
#   description = "Base S3 bucket name"
#   type        = string
#   default     = "my-terraform-bucket"
# }

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  
}

variable "monitoring_enabled" {
  description = "Enable detailed monitoring for the instance"
  type        = bool
  default     = true
}

variable "associate_public_ip" {
  description = "Associate a public IP address with the instance"
  type        = bool
  default     = true
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = list(string)
  default     = ["10.0.0.0/16","192.168.0.0/16"]
}

variable "allowed_vm_type" {
  description = "List of allowed VM names"
  type        = list(string)
  default     = ["t2.micro", "t2.small", "t2.medium"]
}

variable "allowed_region" {
  description = "List of allowed AWS regions"
  type        = set(string)
  default     = ["us-east-1", "us-west-1", "eu-west-1"]
}

variable "bucket_name" {
  description = "Base S3 bucket name"
  type        = list(string)
  default     = ["my-terraform-bucket", "my-terraform-bucket-2", "my-terraform-bucket-3"]
}