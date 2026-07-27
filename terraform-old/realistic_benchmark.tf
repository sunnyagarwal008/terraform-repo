# Realistic Cloud Infrastructure Benchmark
# Simulates a real cloud estate with diverse resource types and dependencies

variable "vpc_count" {
  description = "Number of VPCs to create"
  type        = number
  default     = 55
}

variable "instances_per_vpc" {
  description = "Number of EC2 instances per VPC"
  type        = number
  default     = 18
}

variable "lambda_count" {
  description = "Number of Lambda functions"
  type        = number
  default     = 600
}

variable "rds_count" {
  description = "Number of RDS instances"
  type        = number
  default     = 120
}

# VPCs with full networking stack
resource "aws_vpc" "realistic" {
  count = var.vpc_count

  cidr_block           = "10.${count.index}.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name              = "${var.project_name}-vpc-${count.index}"
    BenchmarkResource = "true"
    Type              = "networking"
  })
}

# Subnets (3 per VPC - public, private, database)
resource "aws_subnet" "public" {
  count = var.vpc_count * 3

  vpc_id                  = aws_vpc.realistic[floor(count.index / 3)].id
  cidr_block              = "10.${floor(count.index / 3)}.${(count.index % 3) * 64}.0/18"
  availability_zone       = data.aws_availability_zones.available.names[count.index % 3]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-subnet-public-${count.index}"
    Type = "public"
  })
}

resource "aws_subnet" "private" {
  count = var.vpc_count * 3

  vpc_id            = aws_vpc.realistic[floor(count.index / 3)].id
  cidr_block        = "10.${floor(count.index / 3)}.${64 + (count.index % 3) * 64}.0/18"
  availability_zone = data.aws_availability_zones.available.names[count.index % 3]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-subnet-private-${count.index}"
    Type = "private"
  })
}

# Internet Gateways
resource "aws_internet_gateway" "realistic" {
  count = var.vpc_count

  vpc_id = aws_vpc.realistic[count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-igw-${count.index}"
  })
}

# Route Tables (2 per VPC)
resource "aws_route_table" "public" {
  count = var.vpc_count

  vpc_id = aws_vpc.realistic[count.index].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.realistic[count.index].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-rt-public-${count.index}"
  })
}

resource "aws_route_table" "private" {
  count = var.vpc_count

  vpc_id = aws_vpc.realistic[count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-rt-private-${count.index}"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = var.vpc_count * 3

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[floor(count.index / 3)].id
}

# Security Groups with rules
resource "aws_security_group" "web" {
  count = var.vpc_count

  name_prefix = "${var.project_name}-web-${count.index}"
  vpc_id      = aws_vpc.realistic[count.index].id
  description = "Security group for web servers in VPC ${count.index}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sg-web-${count.index}"
  })
}

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  count = var.vpc_count

  security_group_id = aws_security_group.web[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "web_https" {
  count = var.vpc_count

  security_group_id = aws_security_group.web[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "web_all" {
  count = var.vpc_count

  security_group_id = aws_security_group.web[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "app" {
  count = var.vpc_count

  name_prefix = "${var.project_name}-app-${count.index}"
  vpc_id      = aws_vpc.realistic[count.index].id
  description = "Security group for app servers in VPC ${count.index}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sg-app-${count.index}"
  })
}

resource "aws_vpc_security_group_ingress_rule" "app_from_web" {
  count = var.vpc_count

  security_group_id            = aws_security_group.app[count.index].id
  referenced_security_group_id = aws_security_group.web[count.index].id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "db" {
  count = var.vpc_count

  name_prefix = "${var.project_name}-db-${count.index}"
  vpc_id      = aws_vpc.realistic[count.index].id
  description = "Security group for databases in VPC ${count.index}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sg-db-${count.index}"
  })
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  count = var.vpc_count

  security_group_id            = aws_security_group.db[count.index].id
  referenced_security_group_id = aws_security_group.app[count.index].id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

# EC2 instances with dependencies
resource "aws_instance" "web" {
  count = var.vpc_count * var.instances_per_vpc

  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public[floor(count.index / var.instances_per_vpc) * 3].id

  vpc_security_group_ids = [
    aws_security_group.web[floor(count.index / var.instances_per_vpc)].id
  ]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web-${count.index}"
    Type = "web"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Lambda functions with IAM roles
resource "aws_lambda_function" "realistic" {
  count = var.lambda_count

  function_name = "${var.project_name}-lambda-${count.index}"
  role          = aws_iam_role.lambda[count.index].arn
  handler       = "index.handler"
  runtime       = "python3.11"
  filename      = "${path.module}/lambda_placeholder.zip"

  environment {
    variables = {
      ENVIRONMENT = var.environment
      INDEX       = count.index
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-lambda-${count.index}"
  })
}

resource "aws_iam_role" "lambda" {
  count = var.lambda_count

  name = "${var.project_name}-lambda-role-${count.index}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-lambda-role-${count.index}"
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count = var.lambda_count

  role       = aws_iam_role.lambda[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch Log Groups for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  count = var.lambda_count

  name              = "/aws/lambda/${aws_lambda_function.realistic[count.index].function_name}"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-lambda-logs-${count.index}"
  })
}

# RDS instances with subnet groups
resource "aws_db_subnet_group" "realistic" {
  count = var.rds_count

  name       = "${var.project_name}-db-subnet-${count.index}"
  subnet_ids = [
    aws_subnet.private[floor(count.index / (var.rds_count / var.vpc_count)) * 3].id,
    aws_subnet.private[floor(count.index / (var.rds_count / var.vpc_count)) * 3 + 1].id,
  ]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-db-subnet-${count.index}"
  })
}

resource "aws_db_instance" "realistic" {
  count = var.rds_count

  identifier           = "${var.project_name}-db-${count.index}"
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name              = "appdb${count.index}"
  username             = "dbadmin"
  password             = "TemporaryPassword123!"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.realistic[count.index].name

  vpc_security_group_ids = [
    aws_security_group.db[floor(count.index / (var.rds_count / var.vpc_count))].id
  ]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-rds-${count.index}"
  })
}

# SNS Topics
resource "aws_sns_topic" "realistic" {
  count = 300

  name = "${var.project_name}-topic-${count.index}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sns-${count.index}"
  })
}

# SQS Queues
resource "aws_sqs_queue" "realistic" {
  count = 300

  name = "${var.project_name}-queue-${count.index}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sqs-${count.index}"
  })
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Output summary
output "realistic_resource_counts" {
  description = "Summary of realistic benchmark resources created"
  value = {
    vpcs                   = var.vpc_count
    subnets                = var.vpc_count * 6  # 3 public + 3 private
    internet_gateways      = var.vpc_count
    route_tables           = var.vpc_count * 2
    route_table_assocs     = var.vpc_count * 3
    security_groups        = var.vpc_count * 3  # web, app, db
    sg_rules               = var.vpc_count * 5  # ingress + egress rules
    ec2_instances          = var.vpc_count * var.instances_per_vpc
    lambda_functions       = var.lambda_count
    lambda_iam_roles       = var.lambda_count
    lambda_role_attachments = var.lambda_count
    lambda_log_groups      = var.lambda_count
    rds_subnet_groups      = var.rds_count
    rds_instances          = var.rds_count
    sns_topics             = 300
    sqs_queues             = 300
    total_resources        = var.vpc_count * 6 + var.vpc_count + var.vpc_count * 2 + var.vpc_count * 3 + var.vpc_count * 3 + var.vpc_count * 5 + (var.vpc_count * var.instances_per_vpc) + var.lambda_count * 4 + var.rds_count * 2 + 600
  }
}
