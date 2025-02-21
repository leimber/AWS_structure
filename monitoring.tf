#dashboard CloudWatch
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = replace("${var.project_name}-dashboard", "_", "-")

  dashboard_body = jsonencode({
    widgets = [
      # Métricas de ASG
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupTotalInstances", "AutoScalingGroupName", aws_autoscaling_group.main.name],
            [".", "GroupInServiceInstances", ".", "."]
          ]
          period = 300
          region = var.region
          title  = "ASG - Instancias"
          view   = "timeSeries"
        }
      },
      #Métricas ALB público
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.public.arn_suffix],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          period = 300
          region = var.region
          title  = "ALB Público - Requests"
          view   = "timeSeries"
        }
      },
      #métricas de CPU de EC2
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.main.name, { "stat": "Average" }]
          ]
          period = 300
          region = var.region
          title  = "EC2 - CPU Utilization"
          view   = "timeSeries"
        }
      },
      # Métricas de Redis
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", aws_elasticache_cluster.main.id],
            [".", "FreeableMemory", ".", "."],
            [".", "CurrConnections", ".", "."]
          ]
          period = 300
          region = var.region
          title  = "Redis - Performance"
          view   = "timeSeries"
        }
      },
      # Métricas de RDS
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.main.identifier],
            [".", "FreeableMemory", ".", "."],
            [".", "ReadIOPS", ".", "."],
            [".", "WriteIOPS", ".", "."]
          ]
          period = 300
          region = var.region
          title  = "RDS - Performance"
          view   = "timeSeries"
        }
      },
      #Métricas de CloudFront
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", aws_cloudfront_distribution.main.id],
            [".", "BytesDownloaded", ".", "."],
            [".", "TotalErrorRate", ".", "."]
          ]
          period = 300
          region = "us-east-1"  # CloudFront metrics are in us-east-1
          title  = "CloudFront - Performance"
          view   = "timeSeries"
        }
      }
    ]
  })
}