output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "The DNS name of the ALB to access the application"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "The ARN of the Target Group to attach the Auto Scaling Group to"
  value       = aws_lb_target_group.this.arn
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer (used for Route53 Alias records)"
  value       = aws_lb.this.zone_id
}

output "alb_arn_suffix" {
  description = "The ARN suffix of the ALB, useful with CloudWatch Metrics"
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "The ARN suffix of the Target Group, useful with CloudWatch Metrics"
  value       = aws_lb_target_group.this.arn_suffix
}
