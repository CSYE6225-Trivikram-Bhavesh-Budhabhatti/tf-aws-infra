# outputs.tf
output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "public_subnets" {
  value = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_b.id,
    aws_subnet.public_subnet_c.id,
  ]
}

output "private_subnets" {
  value = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id,
    aws_subnet.private_subnet_c.id,
  ]
}
