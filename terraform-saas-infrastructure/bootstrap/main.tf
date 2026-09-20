provider "aws" {
  region = var.aws_region
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket        = var.backend_bucket_name
  force_destroy = false

  tags = {
    Name        = "Terraform State Backend"
    Project     = var.project_name
    Environment = "Management"
    ManagedBy   = "Terraform"
  }
}

# Enable Versioning 
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable Server-Side Encryption 
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Project     = var.project_name
    Environment = "Management"
    ManagedBy   = "Terraform"
  }
}
