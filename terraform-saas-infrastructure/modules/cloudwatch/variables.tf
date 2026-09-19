variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group to monitor"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB for monitoring"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the Target Group for monitoring"
  type        = string
}

variable "alert_email" {
  description = "Email address to send CloudWatch SNS alerts to"
  type        = string
  default     = "admin@example.com"
}
