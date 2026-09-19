# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "saas-${var.environment}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "saas-${var.environment}-alb-sg"
  }
}

# Application Security Group
resource "aws_security_group" "app" {
  name        = "saas-${var.environment}-app-sg"
  description = "Security group for the Application servers"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow inbound traffic from ALB only"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "saas-${var.environment}-app-sg"
  }
}

# Database Security Group
resource "aws_security_group" "db" {
  name        = "saas-${var.environment}-db-sg"
  description = "Security group for the Database servers"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow inbound database traffic from App servers only"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "saas-${var.environment}-db-sg"
  }
}
