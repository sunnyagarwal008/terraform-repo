output "s3_bucket_name" {
  description = "Name of the application S3 bucket"
  value       = aws_s3_bucket.app.id
}

output "s3_bucket_arn" {
  description = "ARN of the application S3 bucket"
  value       = aws_s3_bucket.app.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.app.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.app.arn
}

output "iam_role_arn" {
  description = "ARN of the application IAM role"
  value       = aws_iam_role.app.arn
}

output "ssm_config_parameter_name" {
  description = "SSM parameter name for app configuration"
  value       = aws_ssm_parameter.app_config.name
}

# ephemeral outputs are available during apply but never written to state
output "secret_version_id" {
  description = "Version ID of the ephemeral secret (not sensitive, safe to output)"
  value       = ephemeral.aws_secretsmanager_secret_version.app_config.version_id
}
