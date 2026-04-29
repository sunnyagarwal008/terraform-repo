# Ephemeral resources are read at apply time but never written to state.
# This prevents sensitive values (secrets, tokens) from being persisted.

# Reads the secret value ephemerally — value is available during apply only
ephemeral "aws_secretsmanager_secret_version" "app_config" {
  secret_id = var.secret_name
}

# Decode the JSON secret string into a map for use by other resources
locals {
  # secret_data is ephemeral — never stored in state
  secret_data = jsondecode(ephemeral.aws_secretsmanager_secret_version.app_config.secret_string)
}

# Store the ephemeral secret value into SSM Parameter Store (write-once, not re-read from state)
# Using ephemeral resource ensures the secret_string never appears in the Terraform state file.
resource "aws_ssm_parameter" "app_api_key" {
  name        = "/${local.prefix}/app-api-key"
  description = "Application API key sourced from Secrets Manager (ephemeral)"
  type        = "SecureString"
  value       = local.secret_data["api_key"]

  lifecycle {
    # Ignore future drift — the value is managed externally via Secrets Manager
    ignore_changes = [value]
  }

  tags = local.common_tags
}
