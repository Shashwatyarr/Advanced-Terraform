variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (e.g., t3.micro for dev, t3.large for prod)"
  type        = string
}

variable "min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
}

variable "desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
}

variable "vpc_zone_identifier" {
  description = "List of subnet IDs to launch resources in (Private App subnets)"
  type        = list(string)
}

variable "target_group_arns" {
  description = "List of Target Group ARNs to register the instances with"
  type        = list(string)
}

variable "app_security_group_id" {
  description = "The ID of the Application Security Group"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "The name of the IAM Instance Profile to attach to instances"
  type        = string
}
