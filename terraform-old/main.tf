# S3 bucket (free - only pay for storage/requests, empty bucket is free)
resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-${var.environment}-bucket"
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SSM Parameter Store (free tier - standard parameters are free)
resource "aws_ssm_parameter" "app_env" {
  name  = "/${var.project_name}/${var.environment}/app-env"
  type  = "String"
  value = var.environment
}

resource "aws_ssm_parameter" "app_version" {
  name  = "/${var.project_name}/${var.environment}/app-version"
  type  = "String"
  value = "1.0.0"
}

# IAM role (free)
resource "aws_iam_role" "app_role" {
  name = "${var.project_name}-${var.environment}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "app_ssm_read" {
  name = "ssm-read"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParametersByPath"]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/${var.project_name}/${var.environment}/*"
      }
    ]
  })
}

# CloudWatch Log Group (free tier: 5 GB ingestion + storage per month)
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/${var.project_name}/${var.environment}"
  retention_in_days = 7
}
