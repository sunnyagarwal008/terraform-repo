# IAM resources are always free
resource "aws_iam_role" "app" {
  name               = "${local.prefix}-app-role"
  description        = "IAM role for the ${local.prefix} application"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "app_s3" {
  name   = "s3-access"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app_s3.json
}

data "aws_iam_policy_document" "app_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.app.arn,
      "${aws_s3_bucket.app.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "app_dynamodb" {
  name   = "dynamodb-access"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app_dynamodb.json
}

data "aws_iam_policy_document" "app_dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]
    resources = [
      aws_dynamodb_table.app.arn,
      "${aws_dynamodb_table.app.arn}/index/*",
    ]
  }
}

resource "aws_iam_role_policy" "app_ssm" {
  name   = "ssm-read"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app_ssm.json
}

data "aws_iam_policy_document" "app_ssm" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:GetParametersByPath"]
    resources = ["arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${local.prefix}/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alias/aws/ssm"]
  }
}
