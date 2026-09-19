variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where security groups will be created"
  type        = string
}

variable "app_port" {
  description = "Port the application servers listen on"
  type        = number
  default     = 80
}

variable "db_port" {
  description = "Port the database listens on"
  type        = number
  default     = 5432 # Defaulting to PostgreSQL port
}
