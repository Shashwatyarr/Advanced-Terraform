variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group created in the VPC module"
  type        = string
}

variable "db_security_group_id" {
  description = "The ID of the Database security group"
  type        = string
}

variable "db_instance_class" {
  description = "The instance type of the RDS instance (e.g., db.t3.micro)"
  type        = string
}

variable "db_allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "The name of the database to create"
  type        = string
  default     = "saasdb"
}

variable "db_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "postgresadmin"
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ (True for prod, False for dev/test)"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7
}
