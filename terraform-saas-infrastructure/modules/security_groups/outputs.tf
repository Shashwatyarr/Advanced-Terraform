output "alb_sg_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "app_sg_id" {
  description = "The ID of the App security group"
  value       = aws_security_group.app.id
}

output "db_sg_id" {
  description = "The ID of the Database security group"
  value       = aws_security_group.db.id
}
