# DynamoDB table — free tier: 25 GB storage, 25 RCU, 25 WCU (on-demand has no free tier WCU/RCU,
# but provisioned with 1 RCU/WCU stays within free tier limits)
resource "aws_dynamodb_table" "app" {
  name         = "${local.prefix}-app-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "SK"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ExpiresAt"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = local.common_tags
}
