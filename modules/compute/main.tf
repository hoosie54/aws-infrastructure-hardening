# 1. Fetch the latest stable Amazon Linux 2023 Machine Image (AMI)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-kernel-*-x86_64"]
  }
}

# 2. Host Firewalls (Security Groups): Strict Least-Privilege
resource "aws_security_group" "app_sg" {
  name        = "enterprise-app-server-sg"
  description = "Enforces isolated internal network access policies for app layer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Restrictive application microservice traffic entry"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Restrict outbound traffic exclusively to secure web verification endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =========================================================================
# IAM SECURITY POSTURE LAYER (Resolves CKV2_AWS_41)
# =========================================================================

# 3. Create a secure execution role for the virtual machine
resource "aws_iam_role" "app_execution_role" {
  name = "enterprise-app-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "://amazonaws.com" }
    }]
  })
}

# 4. Wrap the execution role inside an AWS Instance Profile container
resource "aws_iam_instance_profile" "app_profile" {
  name = "enterprise-app-instance-profile"
  role = aws_iam_role.app_execution_role.name
}

# =========================================================================
# HARDENED COMPUTE LAYER
# =========================================================================

# 5. Hardened EC2 Compute Instance
resource "aws_instance" "secure_app" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = "t3.micro"
  subnet_id            = var.private_subnet_ids[0] # Drop safely into our private network tier
  security_groups      = [aws_security_group.app_sg.id]
  iam_instance_profile = aws_iam_instance_profile.app_profile.name # Resolves CKV2_AWS_41

  # COMPLIANCE OPTIMIZATIONS
  ebs_optimized           = true # Resolves CKV_AWS_135
  monitoring              = true # Resolves CKV_AWS_126

  # CRITICAL SECURITY GUARDRAILS
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Enforces strict IMDSv2 session tokens
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted             = true # Enables robust AES-256 block storage encryption
    delete_on_termination = true
  }

  tags = { Name = "enterprise-hardened-app-server" }
}
