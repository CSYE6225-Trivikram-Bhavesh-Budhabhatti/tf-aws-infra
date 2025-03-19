provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = var.igw_name
  }
}

# Public Subnets
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

# Private Subnets
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

# Route Tables
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

# Route Table Associations for Public Subnets
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

# Private Route Table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = var.private_route_table_name
  }
}

# Route Table Associations for Private Subnets
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

# Security Group for Web Application
resource "aws_security_group" "app_sg" {
  name        = "app_security_group"
  description = "Allow web traffic and SSH"
  vpc_id      = aws_vpc.main_vpc.id

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
    from_port   = 8080 # Web Application port
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

# IAM Role for EC2 Instance
resource "aws_iam_role" "ec2_s3_access_role" {
  name = "ec2-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach S3 Access Policy to IAM Role
resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  role       = aws_iam_role.ec2_s3_access_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_s3_access_profile" {
  name = "ec2-s3-access-profile"
  role = aws_iam_role.ec2_s3_access_role.name
}

resource "random_uuid" "bucket_uuid" {}
# S3 Bucket
resource "aws_s3_bucket" "webapp_bucket" {
  bucket = "${random_uuid.bucket_uuid.result}"
  # acl    = "private"
  force_destroy = true
}
resource "aws_s3_bucket_server_side_encryption_configuration" "webapp_bucket_encryption" {
  bucket = aws_s3_bucket.webapp_bucket.id
  rule {
    apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.webapp_bucket.id
 
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
 
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

# IAM Policy for S3 Access
resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3-access-policy"
  description = "Policy to allow access to S3 bucket"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetBucketPolicy"
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.webapp_bucket.bucket}/*"
      },
      {
        Effect = "Allow"
        Action = "s3:GetBucketPolicy"
        Resource = "arn:aws:s3:::${aws_s3_bucket.webapp_bucket.bucket}"
      }
    ]
  })
}
# EC2 Instance with IAM Instance Profile
resource "aws_instance" "app_instance" {
  ami                         = var.aws_ami_id
  instance_type               = var.aws_instance_type
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  subnet_id                   = aws_subnet.public_subnet_a.id
  associate_public_ip_address = true
  key_name                    = var.aws_key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_s3_access_profile.name  # Attach the instance profile

  user_data = <<-EOF
              #!/bin/bash
              cat > /opt/csye6225/webapp/.env << EOL
              DB_HOST=${aws_db_instance.webapp_db.endpoint}
              DB_USER=${var.DB_USER}
              DB_PASSWORD=${var.DB_PASSWORD}
              DB_NAME=${var.DB_NAME}
              DB_URI=postgresql://${var.DB_USER}:${var.DB_PASSWORD}@${aws_db_instance.webapp_db.endpoint}/${var.DB_NAME}
              S3_BUCKET_NAME=${aws_s3_bucket.webapp_bucket.bucket}
              S3_REGION=${var.region}
              EOL
              systemctl enable csye6225-flask-webapp.service
              sudo systemctl restart csye6225-flask-webapp.service
              EOF

  root_block_device {
    volume_size           = var.aws_volume_size
    volume_type           = var.aws_volume_type
    delete_on_termination = true
  }

  tags = {
    Name = "csye6225-flask-webapp-instance"
  }
}
data "aws_rds_engine_version" "latest_postgres" {
  engine = "postgres"
  # latest = true
  version = "17.4"
}
resource "aws_db_parameter_group" "webapp_db_param_group" {
  name        = "csye6225-db-parameter-group"
  family      = "postgres17"
  description = "Parameter group for the csye6225 web app database"
}
# RDS Instance
resource "aws_db_instance" "webapp_db" {
  identifier           = "csye6225-db"
  engine               = "postgres"
  engine_version       = data.aws_rds_engine_version.latest_postgres.version
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  username             = var.DB_USER
  password             = var.DB_PASSWORD
  db_name              = var.DB_NAME
  publicly_accessible  = false
  skip_final_snapshot  = true
  parameter_group_name = aws_db_parameter_group.webapp_db_param_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name = aws_db_subnet_group.webapp_db_subnet_group.name
}

# RDS Subnet Group
resource "aws_db_subnet_group" "webapp_db_subnet_group" {
  name       = "webapp-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id, aws_subnet.private_subnet_c.id]
}

# Security Group for RDS
resource "aws_security_group" "db_sg" {
  name        = "db-security-group"
  description = "Allow inbound traffic from the application security group"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.app_sg.id]  # Allow traffic from the app security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}