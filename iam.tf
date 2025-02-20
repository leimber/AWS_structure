# AZ disponibles
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# User seguimiento
resource "aws_iam_user" "admin" {
  name = "${var.project_name}-admin"
  tags = var.tags
}

# Rol para user de seguimiento
resource "aws_iam_role" "admin_role" {
  name = "${var.project_name}-admin-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.admin.arn
        }
      }
    ]
  })

  tags = var.tags
}

# Política para rol seguimiento
resource "aws_iam_role_policy" "admin_role_policy" {
  name = "${var.project_name}-readonly-policy"
  role = aws_iam_role.admin_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudtrail:Get*",
          "cloudtrail:Describe*",
          "cloudtrail:List*",
          "cloudtrail:LookupEvents",
          "s3:Get*",
          "s3:List*",
          "iam:Get*",
          "iam:List*",
          "dynamodb:Get*",
          "dynamodb:List*",
          "dynamodb:Describe*",
          "ec2:Describe*",
          "elasticloadbalancing:Describe*",
          "autoscaling:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "cloudwatch:Describe*",
          "route53:List*",
          "route53:Get*",
          "rds:Describe*",
          "efs:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Asignación del rol
resource "aws_iam_user_policy" "allow_assume_role" {
  name = "${var.project_name}-assume-role-policy"
  user = aws_iam_user.admin.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = aws_iam_role.admin_role.arn
      }
    ]
  })
}

# S3 Bucket para CloudTrail
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "lab4-final-cloudtrail-logs"
  force_destroy = true

  tags = var.tags
}

# Configuraciones adicionales requeridas para el bucket S3
resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Política para el bucket de CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck20150319"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite20150319"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
          StringLike = {
            "aws:SourceArn": "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/*"
          }
        }
      }
    ]
  })
}

# CloudTrail
resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name               = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true

  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_s3_bucket.cloudtrail
  ]

  tags = var.tags
}