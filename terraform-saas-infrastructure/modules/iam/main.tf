# IAM Role for EC2 Instances
resource "aws_iam_role" "ec2_role" {
  name = "saas-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "saas-${var.environment}-ec2-role"
  }
}

# Attach AWS Managed Policy for Systems Manager (Allows secure shell without SSH keys)
resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach AWS Managed Policy for CloudWatch Agent
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom Policy for S3 and Secrets Manager Access
resource "aws_iam_policy" "app_policy" {
  name        = "saas-${var.environment}-app-policy"
  description = "Application permissions for S3 and Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        # In a strict production environment, this should be restricted to the exact Secret ARN.
        Resource = "*" 
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.app_policy.arn
}

# IAM Instance Profile (Required to attach the role to an EC2 instance)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "saas-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
