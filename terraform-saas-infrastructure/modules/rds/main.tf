# Generate a strong random password for the database
resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create a random suffix to prevent naming collisions if recreated quickly
resource "random_id" "suffix" {
  byte_length = 4
}

# AWS Secrets Manager Secret to securely store the DB credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "saas-${var.environment}-db-credentials-${random_id.suffix.hex}"
  description             = "Database connection credentials for ${var.environment}"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0 # 0 allows immediate deletion in dev/test
}

# Store the JSON object with connection details in Secrets Manager
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "postgres"
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
}

# RDS Database Instance
resource "aws_db_instance" "this" {
  identifier = "saas-${var.environment}-db"

  engine               = "postgres"
  engine_version       = "15.7"
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  storage_type         = "gp3" 

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.db_security_group_id]
  publicly_accessible    = false

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  
  skip_final_snapshot = var.environment == "prod" ? false : true

  tags = {
    Name = "saas-${var.environment}-db"
  }
}
