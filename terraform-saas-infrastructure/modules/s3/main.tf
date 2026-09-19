# Create a random suffix to ensure global bucket name uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# The actual S3 Bucket
resource "aws_s3_bucket" "this" {
  bucket = "${var.bucket_name_prefix}-${var.environment}-${random_id.bucket_suffix.hex}"
  
  # Allow Terraform to destroy the bucket in dev/test even if it contains objects
  force_destroy = var.environment == "prod" ? false : true

  tags = {
    Name = "${var.bucket_name_prefix}-${var.environment}"
  }
}

# Enable Versioning to keep multiple variants of an object in the same bucket
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access at the bucket level
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration to save costs on old object versions
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "archive_and_expire_old_versions"
    status = "Enabled"

    # Move old versions to cheaper Infrequent Access storage after 30 days
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    # Permanently delete old versions after 90 days to save costs
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
