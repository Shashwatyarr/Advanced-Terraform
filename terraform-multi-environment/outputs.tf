output "active_workspace" {
  description = "The currently active Terraform workspace"
  value       = terraform.workspace
}

output "active_environment" {
  description = "The resolved environment name used for provisioning"
  value       = local.environment
}

output "aws_region" {
  description = "The selected AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "The ID of the default VPC used"
  value       = data.aws_vpc.default.id
}

output "selected_subnet_id" {
  description = "The Subnet ID where the instances are deployed"
  value       = data.aws_subnets.default.ids[0]
}

output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.app_server[*].id
}

output "instance_public_ips" {
  description = "List of EC2 instance public IP addresses"
  value       = aws_instance.app_server[*].public_ip
}

output "instance_type_used" {
  description = "The EC2 instance type that was provisioned"
  value       = local.final_instance_type
}

output "s3_bucket_name" {
  description = "The name of the created S3 bucket"
  value       = aws_s3_bucket.storage.id
}
