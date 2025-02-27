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

output "ec2_instance_id" {
  description = "ID of the EC2 instance in the public subnet"
  value       = aws_instance.app_instance.id
}

output "public_ip_of_ec2" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_instance.public_ip
}

output "security_group_id" {
  description = "ID of the security group for the EC2 instance"
  value       = aws_security_group.app_sg.id
}