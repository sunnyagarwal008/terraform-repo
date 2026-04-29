required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 5.0"
  }
}

# Declare input variables available to all components in this stack
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type    = string
  default = "tfstacks-demo"
}

variable "state_bucket_name" {
  type = string
}

# ─── Components ───────────────────────────────────────────────────────────────

component "iam" {
  source = "./components/iam"

  inputs = {
    project_name = var.project_name
    environment  = var.environment
  }

  providers = {
    aws = provider.aws.this
  }
}

component "storage" {
  source = "./components/storage"

  inputs = {
    project_name = var.project_name
    environment  = var.environment
  }

  providers = {
    aws = provider.aws.this
  }
}

component "messaging" {
  source = "./components/messaging"

  inputs = {
    project_name = var.project_name
    environment  = var.environment
  }

  providers = {
    aws = provider.aws.this
  }
}

component "database" {
  source = "./components/database"

  inputs = {
    project_name = var.project_name
    environment  = var.environment
  }

  providers = {
    aws = provider.aws.this
  }
}

# ─── Stack Outputs ────────────────────────────────────────────────────────────

output "s3_bucket_name" {
  type  = string
  value = component.storage.s3_bucket_name
}

output "sqs_queue_url" {
  type  = string
  value = component.messaging.sqs_queue_url
}

output "dynamodb_table_name" {
  type  = string
  value = component.database.table_name
}

output "iam_role_arn" {
  type  = string
  value = component.iam.role_arn
}
