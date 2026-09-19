output "active_environment" {
  description = "The active Terraform workspace environment (dev, test, or prod)"
  value       = local.environment
}

output "vpc_id" {
  description = "The ID of the VPC created for this environment"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "The URL to access the SaaS application"
  value       = "http://${module.alb.alb_dns_name}"
}

output "database_endpoint" {
  description = "The private connection endpoint of the RDS database"
  value       = module.rds.db_endpoint
}

output "database_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret holding the database credentials"
  value       = module.rds.db_secret_arn
}

output "app_data_s3_bucket" {
  description = "The name of the S3 bucket created for application data"
  value       = module.s3.bucket_id
}
