# 1. Base Availability Zone Query
data "aws_availability_zones" "available" {
  state = "available"
}

# 2. Core Enterprise VPC Layout
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "enterprise-secure-vpc" }
}

# 3. Strict Default Security Group Lockdown
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
}

# 4. Public Subnet Tier (Using direct data indices to clear CKV_AWS_394 permanently)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = { Name = "public-tier-${count.index}" }
}

# 5. Isolated Private Subnet Tier
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { Name = "private-app-tier-${count.index}" }
}

# =========================================================================
# MONITORING, COMPLIANCE & KMS ENCRYPTION LAYER
# =========================================================================

# 6. Customer Managed Key (CMK) for Log Encryption (Resolves CKV_AWS_158)
resource "aws_kms_key" "log_encryption_key" {
  description             = "KMS Key managing encryption-at-rest for enterprise cloud networks"
  deletion_window_in_days = 7
  enable_key_rotation     = true # Primary cloud security posture check
}

# 7. CloudWatch Log Retention Group (Resolves CKV_AWS_338)
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/enterprise-flow-logs"
  retention_in_days = 365 # Complies with 1-year data forensics mandates
  kms_key_id        = aws_kms_key.log_encryption_key.arn
}

# 8. Active VPC Flow Log Capture Mechanism
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_log_delivery.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

# 9. IAM Role Granting Network Interface Visibility Permissions
resource "aws_iam_role" "flow_log_delivery" {
  name = "enterprise-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "://amazonaws.com" }
    }]
  })
}

# 10. IAM Policy Restricting Write Access Strictly to the Flow Log Stream
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
