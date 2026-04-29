# terraform-ephemeral

Demonstrates Terraform **ephemeral resources** (requires Terraform ≥ 1.10).

## What's provisioned

| Resource | AWS Free Tier |
|---|---|
| S3 bucket (app data) | 5 GB, 20K GET, 2K PUT/month |
| DynamoDB table (PAY_PER_REQUEST) | 25 GB storage free |
| IAM role + inline policies | Always free |
| SSM Parameter Store (Standard) | 10K parameters free |
| SSM SecureString (from ephemeral secret) | Always free |

## Ephemeral resource highlight

`ephemeral "aws_secretsmanager_secret_version"` reads a secret at apply time.
The secret value is used in-memory only — it is **never written to Terraform state**.

```hcl
ephemeral "aws_secretsmanager_secret_version" "app_config" {
  secret_id = var.secret_name
}
```

## Setup

### 1. Bootstrap the S3 backend (one-time)

```bash
cd bootstrap
terraform init
terraform apply
```

### 2. Create the Secrets Manager secret

```bash
aws secretsmanager create-secret \
  --name "terraform-ephemeral/app-config" \
  --secret-string '{"api_key":"your-api-key-here"}'
```

### 3. Deploy the main project

```bash
cd ..
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars as needed
terraform init
terraform apply
```

## State backend

Remote state is stored in S3 with DynamoDB locking:

- **Bucket**: `terraform-ephemeral-state-bucket`
- **Key**: `terraform-ephemeral/terraform.tfstate`
- **Lock table**: `terraform-ephemeral-lock`
- **Encryption**: AES256 (SSE-S3)
