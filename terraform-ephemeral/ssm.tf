# SSM Parameters — free tier: standard parameters are free (up to 10K)
resource "aws_ssm_parameter" "app_config" {
  name        = "/${local.prefix}/config"
  description = "Application configuration"
  type        = "String"
  value = jsonencode({
    s3_bucket      = aws_s3_bucket.app.id
    dynamodb_table = aws_dynamodb_table.app.name
    region         = var.aws_region
    environment    = var.environment
  })

  tags = local.common_tags
}
