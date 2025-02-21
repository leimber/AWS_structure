# Tema SNS principal
resource "aws_sns_topic" "alerts" {
  name = replace("${var.project_name}-alerts", "_", "-")
  tags = var.tags
}

# Suscripción al tema SNS 
resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Alarmas de CloudWatch para ASG público
resource "aws_cloudwatch_metric_alarm" "cpu_high_public" {
  alarm_name          = "${var.project_name}-cpu-utilization-high-public"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "CPU utilization above 80% in public ASG"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.public.name
  }
}

# Alarmas de CloudWatch para ASG interno
resource "aws_cloudwatch_metric_alarm" "cpu_high_internal" {
  alarm_name          = "${var.project_name}-cpu-utilization-high-internal"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "CPU utilization above 80% in internal ASG"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.internal.name
  }
}

# Alarmas para ALB público
resource "aws_cloudwatch_metric_alarm" "alb_errors_public" {
  alarm_name          = "${var.project_name}-alb-5xx-errors-public"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "HTTPCode_Target_5XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = "300"
  statistic          = "Sum"
  threshold          = "10"
  alarm_description  = "Public ALB 5XX errors above threshold"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.public.arn_suffix
  }
}

# Alarmas para ALB interno
resource "aws_cloudwatch_metric_alarm" "alb_errors_internal" {
  alarm_name          = "${var.project_name}-alb-5xx-errors-internal"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "HTTPCode_Target_5XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = "300"
  statistic          = "Sum"
  threshold          = "10"
  alarm_description  = "Internal ALB 5XX errors above threshold"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.internal.arn_suffix
  }
}

# Notificaciones de Auto Scaling Groups
resource "aws_autoscaling_notification" "asg_notifications" {
  group_names = [
    aws_autoscaling_group.public.name,
    aws_autoscaling_group.internal.name
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ]

  topic_arn = aws_sns_topic.alerts.arn
}

# Alarma para RDS primario
resource "aws_cloudwatch_metric_alarm" "rds_cpu_primary" {
  alarm_name          = "${var.project_name}-rds-primary-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/RDS"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "RDS Primary CPU utilization above 80%"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }
}

# Alarma para RDS secundario
resource "aws_cloudwatch_metric_alarm" "rds_cpu_secondary" {
  alarm_name          = "${var.project_name}-rds-secondary-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/RDS"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "RDS Secondary CPU utilization above 80%"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.secondary.id
  }
}

# Alarma para Redis
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "${var.project_name}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/ElastiCache"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "Redis CPU utilization above 80%"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.main.id
  }
}