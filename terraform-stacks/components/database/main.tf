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
    key            = "components/database/terraform.tfstate"
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

# DynamoDB table — free tier: 25 GB storage, 25 RCU, 25 WCU
resource "aws_dynamodb_table" "app" {
  name         = "${local.name_prefix}-table"
  billing_mode = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key     = "pk"
  range_key    = "sk"
  tags         = local.common_tags

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  attribute {
    name = "gsi1pk"
    type = "S"
  }

  global_secondary_index {
    name            = "gsi1"
    hash_key        = "gsi1pk"
    range_key       = "sk"
    projection_type = "ALL"
    read_capacity   = 5
    write_capacity  = 5
  }

  point_in_time_recovery {
    enabled = false
  }

  server_side_encryption {
    enabled = true
  }
}
