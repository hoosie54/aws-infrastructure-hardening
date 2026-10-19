variable "vpc_cidr" {
  type        = string
  description = "Base CIDR block for the core corporate network topology"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR ranges allocated for public internet-facing tiers"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR ranges allocated for fully isolated backend application tiers"
}

variable "aws_region" {
  type        = string
  description = "Passed regional identifier mapping back to environment parameters"
}
