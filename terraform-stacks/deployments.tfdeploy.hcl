identity_token "aws" {
  audience = ["aws.workload.identity"]
}

deployment "dev" {
  inputs = {
    aws_region        = "us-east-1"
    environment       = "dev"
    project_name      = "tfstacks-demo"
    state_bucket_name = "my-terraform-stacks-tfstate-2024"
  }
}

deployment "staging" {
  inputs = {
    aws_region        = "us-east-1"
    environment       = "staging"
    project_name      = "tfstacks-demo"
    state_bucket_name = "my-terraform-stacks-tfstate-2024"
  }
}
