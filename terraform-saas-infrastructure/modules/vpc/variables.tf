variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets_cidr" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_app_subnets_cidr" {
  description = "List of CIDR blocks for private application subnets"
  type        = list(string)
}

variable "private_db_subnets_cidr" {
  description = "List of CIDR blocks for private database subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for your private networks"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all private networks. False will create one NAT per AZ."
  type        = bool
  default     = false
}
