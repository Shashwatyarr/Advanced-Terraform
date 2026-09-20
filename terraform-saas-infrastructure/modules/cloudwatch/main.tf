# Simple SNS Topic for Alert Notifications
resource "aws_sns_topic" "alerts" {
  name = "saas-${var.environment}-alerts"
}

# Subscribe an email to the topic
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# High CPU Alarm for the Auto Scaling Group
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "saas-${var.environment}-HighCPU"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  
  # Environment aware thresholds: dev alerts at 90%, prod is stricter and alerts at 75%
  threshold           = var.environment == "prod" ? 75 : 90
  
  alarm_description   = "This metric monitors ASG EC2 CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

# ALB 5XX Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "saas-${var.environment}-ALB-5XX-Errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10" 
  alarm_description   = "Monitors ALB for 5XX errors originating from the application"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

# ALB High Target Response Time Alarm
resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  alarm_name          = "saas-${var.environment}-ALB-HighResponseTime"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = var.environment == "prod" ? 0.5 : 1.0
  
  alarm_description   = "Monitors ALB target response time"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }
}
