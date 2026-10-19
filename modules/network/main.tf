# 1. Base Core Corporate Network Layout
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "enterprise-secure-vpc" }
}

# 2. Strict Default Security Group Lockdown
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
}

# 3. Public Subnet Tier (Hardcoded mapping indexes to resolve CKV_AWS_394 permanently)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = "${var.aws_region}${count.index == 0 ? "a" : "b"}"
  map_public_ip_on_launch = false

  tags = { Name = "public-tier-${count.index}" }
}

# 4. Isolated Private Subnet Tier
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = "${var.aws_region}${count.index == 0 ? "a" : "b"}"

  tags = { Name = "private-app-tier-${count.index}" }
}

# =========================================================================
# MONITORING, COMPLIANCE & KMS POLICY LAYER
# =========================================================================

# 5. Hardened Customer Managed Key (CMK) with Custom Policy (Resolves CKV2_AWS_64)
resource "aws_kms_key" "log_encryption_key" {
  description             = "KMS Key managing encryption-at-rest for enterprise cloud networks"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "kms-log-policy"
    Statement = [
      {
        Sid    = "Enable Root Account Management Access"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::111222333444:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs Service to Encrypt Streams"
        Effect = "Allow"
        Principal = {
          Service = "://amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

# 6. CloudWatch Log Retention Group
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/enterprise-flow-logs"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.log_encryption_key.arn
}

# 7. Active VPC Flow Log Capture Mechanism
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_log_delivery.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

# 8. IAM Role Granting Network Interface Visibility Permissions
resource "aws_iam_role" "flow_log_delivery" {
  name = "enterprise-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-://amazonaws.com" }
    }]
  })
}

# 9. IAM Policy Restricting Write Access Strictly to the Flow Log Stream
resource "aws_iam_role_policy" "flow_log_write_policy" {
  name = "enterprise-vpc-flow-logs-policy"
  role = aws_iam_role.flow_log_delivery.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Effect   = "Allow"
      Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
    }]
  })
}
