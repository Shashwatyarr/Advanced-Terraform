data "aws_caller_identity" "name"{}

output "account_id" {
  value = data.aws_caller_identity.name
}

