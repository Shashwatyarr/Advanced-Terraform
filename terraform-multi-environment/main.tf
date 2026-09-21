# ---------------------------------------------------------
# Security Group
# ---------------------------------------------------------
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-${local.environment}-sg"
  description = "Security group for ${local.environment} environment allowing SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow SSH from configured CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# ---------------------------------------------------------
# EC2 Instances
# ---------------------------------------------------------
resource "aws_instance" "app_server" {
  count = local.final_instance_count

  ami           = data.aws_ami.ubuntu.id
  instance_type = local.final_instance_type

  # Deploy into the first available subnet from our data source
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Tagging with instance index for uniqueness
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${local.environment}-instance-${count.index + 1}"
  })
}

# ---------------------------------------------------------
# S3 Bucket
# ---------------------------------------------------------
resource "aws_s3_bucket" "storage" {
  # Name must be globally unique, incorporating environment and a random prefix
  bucket = "${var.bucket_prefix}-${var.project_name}-${local.environment}"

  tags = local.common_tags
}

# Enable Server-Side Encryption for the S3 Bucket (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "storage_crypto" {
  bucket = aws_s3_bucket.storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Public Access Block (Security best practice)
resource "aws_s3_bucket_public_access_block" "storage_pab" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
