# Fetch the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# Launch Template for EC2 instances
resource "aws_launch_template" "this" {
  name_prefix   = "saas-${var.environment}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  network_interfaces {
    security_groups = [var.app_security_group_id]
  }

  # Simple user data script to start an Apache web server for demonstration purposes
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from SaaS Application in the ${upper(var.environment)} Environment</h1>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "saas-${var.environment}-app-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "this" {
  name                = "saas-${var.environment}-asg"
  vpc_zone_identifier = var.vpc_zone_identifier
  target_group_arns   = var.target_group_arns

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  # This dynamic tag is required because ASG tags are applied differently than standard resource tags
  tag {
    key                 = "Name"
    value               = "saas-${var.environment}-asg-instance"
    propagate_at_launch = true
  }
}
