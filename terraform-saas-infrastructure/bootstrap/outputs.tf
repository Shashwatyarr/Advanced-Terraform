output "s3_bucket_name" {
  description = "The name of the S3 bucket to use in the backend configuration."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table to use in the backend configuration."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "aws_region" {
  description = "The region where the backend resources are deployed."
  value       = var.aws_region
}
