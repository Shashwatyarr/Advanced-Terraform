# Application Load Balancer
resource "aws_lb" "this" {
  name               = "saas-${var.environment}-alb"
  internal           = false # Internet-facing
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnets

  # Drop invalid header fields is a security best practice
  drop_invalid_header_fields = true

  tags = {
    Name = "saas-${var.environment}-alb"
  }
}

# Target Group for the Auto Scaling Group instances
resource "aws_lb_target_group" "this" {
  name     = "saas-${var.environment}-tg"
  port     = 80 # The port the application is listening on
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = {
    Name = "saas-${var.environment}-tg"
  }
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
