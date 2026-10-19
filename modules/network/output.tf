output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The unique identifier of the core network infrastructure"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "The collective collection of private subnet tier mappings"
}
