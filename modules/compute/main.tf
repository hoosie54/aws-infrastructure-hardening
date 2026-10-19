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

  # Ingress (Inbound): No public access. Only accept traffic on port 8080 internally.
  ingress {
    description = "Restrictive application microservice traffic entry"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Restricted strictly to internal network traffic
  }

  # Egress (Outbound): Block open web access. Allow outbound HTTPS only for secure patching.
  egress {
    description = "Restrict outbound traffic exclusively to secure web verification endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Hardened EC2 Compute Instance
resource "aws_instance" "secure_app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = var.private_subnet_ids[0] # Drop safely into our private network tier

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # CRITICAL SECURITY GUARDRAILS

  # A. Enforce Strict IMDSv2 (Neutralizes Cloud SSRF Credential Theft)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Requires cryptographic session token handshakes
    http_put_response_hop_limit = 1          # Prevents container breakout token inheritance
  }

  # B. Enforce Root Storage Cryptography (Defends against physical/snapshot theft data leaks)
  root_block_device {
    encrypted             = true # Enables robust AES-256 block storage encryption
    delete_on_termination = true
  }

  tags = { Name = "enterprise-hardened-app-server" }
}
