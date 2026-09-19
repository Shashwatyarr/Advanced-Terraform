output "ec2_instance_profile_name" {
  description = "The name of the IAM instance profile to attach to EC2 instances"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_role_arn" {
  description = "The ARN of the EC2 IAM Role"
  value       = aws_iam_role.ec2_role.arn
}
