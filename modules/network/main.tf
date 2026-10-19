data "aws_availability_zones" "available" {
  state = "available"
 }

# Core Enterprise VPC Layout
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "enterprise-secure-vpc" }
}

# Strict Default Security Group Lockdown
# Enterprise Posture: Strips all implicit ingress/egress rules to neutralize default group abuse.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
}

# Public Subnet Tier (Reserved exclusively for public load balancers)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false # Enforce explicit elastic IP allocation only

  tags = { Name = "public-tier-${count.index}" }
}

# Isolated Private Subnet Tier (Houses application logic and private databases)
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { Name = "private-app-tier-${count.index}" }
}
