# AWS Region
variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

# ------------------------------------------------------------------------------
# VPC VARIABLES
# ------------------------------------------------------------------------------
variable "vpc_cidr" { type = string }
variable "public_subnets_cidr" { type = list(string) }
variable "private_app_subnets_cidr" { type = list(string) }
variable "private_db_subnets_cidr" { type = list(string) }
variable "availability_zones" { type = list(string) }
variable "enable_nat_gateway" { type = bool }
variable "single_nat_gateway" { type = bool }

# ------------------------------------------------------------------------------
# APPLICATION VARIABLES
# ------------------------------------------------------------------------------
variable "app_port" { type = number }
variable "ec2_instance_type" { type = string }
variable "asg_min_size" { type = number }
variable "asg_max_size" { type = number }
variable "asg_desired_capacity" { type = number }

# ------------------------------------------------------------------------------
# DATABASE VARIABLES
# ------------------------------------------------------------------------------
variable "db_port" { type = number }
variable "db_instance_class" { type = string }
variable "db_allocated_storage" { type = number }
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_multi_az" { type = bool }
variable "db_deletion_protection" { type = bool }
variable "db_backup_retention_period" { type = number }

# ------------------------------------------------------------------------------
# STORAGE & MONITORING VARIABLES
# ------------------------------------------------------------------------------
variable "s3_bucket_name_prefix" { type = string }
variable "alert_email" { type = string }
