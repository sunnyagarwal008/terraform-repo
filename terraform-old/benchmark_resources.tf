# Benchmark resources to test IACM OPA memory scaling
# This file creates a large number of lightweight AWS resources

# Variables for controlling resource count
variable "ssm_parameter_count" {
  description = "Number of SSM parameters to create"
  type        = number
  default     = 500
}

variable "iam_policy_count" {
  description = "Number of IAM policies to create"
  type        = number
  default     = 100
}

variable "s3_bucket_count" {
  description = "Number of S3 buckets to create"
  type        = number
  default     = 50
}

# SSM Parameters (free tier - standard parameters are free)
# These are lightweight and won't incur costs
resource "aws_ssm_parameter" "benchmark" {
  count = var.ssm_parameter_count

  name  = "/${var.project_name}/${var.environment}/benchmark/param-${count.index}"
  type  = "String"
  value = "benchmark-value-${count.index}"

  tags = merge(local.common_tags, {
    BenchmarkResource = "true"
    Index            = count.index
  })
}

# IAM Policies (free)
resource "aws_iam_policy" "benchmark" {
  count = var.iam_policy_count

  name        = "${var.project_name}-${var.environment}-benchmark-policy-${count.index}"
  description = "Benchmark IAM policy ${count.index}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-benchmark-${count.index}",
          "arn:aws:s3:::${var.project_name}-${var.environment}-benchmark-${count.index}/*"
        ]
      }
    ]
  })

  tags = merge(local.common_tags, {
    BenchmarkResource = "true"
    Index            = count.index
  })
}

# S3 Buckets (minimal cost - only pay for storage and requests)
resource "aws_s3_bucket" "benchmark" {
  count = var.s3_bucket_count

  bucket = "${var.project_name}-${var.environment}-benchmark-${count.index}-${substr(md5("${var.project_name}-${count.index}"), 0, 8)}"

  tags = merge(local.common_tags, {
    BenchmarkResource = "true"
    Index            = count.index
  })
}

resource "aws_s3_bucket_versioning" "benchmark" {
  count  = var.s3_bucket_count
  bucket = aws_s3_bucket.benchmark[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "benchmark" {
  count  = var.s3_bucket_count
  bucket = aws_s3_bucket.benchmark[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "benchmark" {
  count  = var.s3_bucket_count
  bucket = aws_s3_bucket.benchmark[count.index].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudWatch Log Groups (free tier: 5 GB ingestion per month)
resource "aws_cloudwatch_log_group" "benchmark" {
  count = 100

  name              = "/aws/${var.project_name}/${var.environment}/benchmark/log-group-${count.index}"
  retention_in_days = 1  # Minimal retention to reduce costs

  tags = merge(local.common_tags, {
    BenchmarkResource = "true"
    Index            = count.index
  })
}

# IAM Roles (free)
resource "aws_iam_role" "benchmark" {
  count = 100

  name = "${var.project_name}-${var.environment}-benchmark-role-${count.index}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    BenchmarkResource = "true"
    Index            = count.index
  })
}

# Attach policies to roles
resource "aws_iam_role_policy_attachment" "benchmark" {
  count = 100

  role       = aws_iam_role.benchmark[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Output summary
output "benchmark_resource_counts" {
  description = "Summary of benchmark resources created"
  value = {
    ssm_parameters     = var.ssm_parameter_count
    iam_policies       = var.iam_policy_count
    s3_buckets         = var.s3_bucket_count
    s3_bucket_configs  = var.s3_bucket_count * 3  # versioning, encryption, public access block
    log_groups         = 100
    iam_roles          = 100
    role_attachments   = 100
    total_resources    = var.ssm_parameter_count + var.iam_policy_count + (var.s3_bucket_count * 4) + 100 + 100 + 100
  }
}
