terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = var.state_bucket_name
    key            = "components/messaging/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = var.lock_table_name
    encrypt        = true
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform-stacks"
  }
}

# SQS standard queue — free tier: 1 million requests/month
resource "aws_sqs_queue" "app" {
  name                       = "${local.name_prefix}-queue"
  message_retention_seconds  = 86400  # 1 day
  visibility_timeout_seconds = 30
  tags                       = local.common_tags
}

# Dead-letter queue for failed messages
resource "aws_sqs_queue" "dlq" {
  name                      = "${local.name_prefix}-dlq"
  message_retention_seconds = 1209600 # 14 days
  tags                      = local.common_tags
}

resource "aws_sqs_queue_redrive_policy" "app" {
  queue_url = aws_sqs_queue.app.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

# SNS topic — free tier: 1 million publishes/month
resource "aws_sns_topic" "app" {
  name = "${local.name_prefix}-topic"
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "sqs" {
  topic_arn = aws_sns_topic.app.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.app.arn
}

resource "aws_sqs_queue_policy" "sns_publish" {
  queue_url = aws_sqs_queue.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.app.arn
        Condition = {
          ArnEquals = { "aws:SourceArn" = aws_sns_topic.app.arn }
        }
      }
    ]
  })
}
