

#user pseguimiento
resource "aws_iam_user" "admin" {
  name = "${var.project_name}-admin"
  tags = var.tags
}

#rol para user de seguimiento
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
#política para rol seguimiento

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

#asignación del rol
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

#cloudtrail

resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name               = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true

  tags = var.tags
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "lab4-final-cloudtrail-logs"
  force_destroy = true

  tags = var.tags
}

#politica cloudtrail

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
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
        }
      }
    ]
  })
}