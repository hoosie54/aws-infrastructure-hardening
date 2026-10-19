variable "vpc_id" {
  type        = string
  description = "The target VPC ID where the compute resources will be deployed"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "The isolated private subnets to house the secure compute instances"
}
