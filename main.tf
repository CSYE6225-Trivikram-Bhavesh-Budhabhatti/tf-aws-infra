provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = var.igw_name
  }
}

# Public subnets
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true
  tags = {
    Name = var.public_subnet_name[0]
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true
  tags = {
    Name = var.public_subnet_name[1]
  }
}

resource "aws_subnet" "public_subnet_c" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidrs[2]
  availability_zone       = var.availability_zones[2]
  map_public_ip_on_launch = true
  tags = {
    Name = var.public_subnet_name[2]
  }
}

# Private subnets
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = var.availability_zones[0]
  tags = {
    Name = var.private_subnet_name[0]
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = var.availability_zones[1]
  tags = {
    Name = var.private_subnet_name[1]
  }
}

resource "aws_subnet" "private_subnet_c" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidrs[2]
  availability_zone = var.availability_zones[2]
  tags = {
    Name = var.private_subnet_name[2]
  }
}

# Route tables for public and private subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = var.public_route_table_name
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = var.destination_cidr
  gateway_id             = aws_internet_gateway.main_igw.id
}

# Route table associations for public subnets
resource "aws_route_table_association" "public_subnet_a_association" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_b_association" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_c_association" {
  subnet_id      = aws_subnet.public_subnet_c.id
  route_table_id = aws_route_table.public_route_table.id
}

# Private route table (not associated with any internet gateway)
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = var.private_route_table_name
  }
}

# Route table associations for private subnets
resource "aws_route_table_association" "private_subnet_a_association" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_b_association" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_c_association" {
  subnet_id      = aws_subnet.private_subnet_c.id
  route_table_id = aws_route_table.private_route_table.id
}

# Creating Security Group for Web Application
resource "aws_security_group" "app_sg" {
  name        = "app_security_group"
  description = "Allow web traffic and SSH"
  vpc_id      = aws_vpc.main_vpc.id  # Use the created VPC
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows SSH access
  }
 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP traffic
  }
 
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS traffic
  }
 
  ingress {
    from_port   = 8080  # Web Application port
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
# Creating EC2 Instance in Public Subnet
resource "aws_instance" "app_instance" {
  ami                    = var.aws_ami_id
  instance_type          = var.aws_instance_type     
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_id              = aws_subnet.public_subnet_a.id  #using the first public subnet for now
  associate_public_ip_address = true  # Ensure it gets a public IP
  key_name = var.aws_key_name
 
  root_block_device {
    volume_size           = var.aws_volume_size
    volume_type           = var.aws_volume_type
    delete_on_termination = true
  }
 
  tags = {
    Name = "csye6225-flask-webapp-instance"
  }
}