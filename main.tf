# main.tf
provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

# Generate unique suffix for KMS keys
resource "random_id" "kms_suffix" {
  byte_length = 4
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

locals {
  key_suffix = "csye6225-${random_id.kms_suffix.hex}"
}

data "aws_caller_identity" "current" {}
resource "aws_kms_key" "ec2_key" {
  description             = "ec2-key-${local.key_suffix}"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-default-1",
    Statement = [
      {
        Sid    = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "Allow service-linked role use of the CMK",
        Effect = "Allow",
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ],
        Resource = "*"
      },
      {
        Sid    = "Allow attachment of persistent resources",
        Effect = "Allow",
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        },
        Action = [
          "kms:CreateGrant"
        ],
        Resource = "*",
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      }
    ]
  })

  tags = {
    Assignment = "csye6225"
  }
}


resource "aws_kms_key" "rds_key" {
  description             = "rds-key-${local.key_suffix}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_key" "s3_key" {
  description             = "s3-key-${local.key_suffix}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_key" "secrets_key" {
  description             = "secrets-key-${local.key_suffix}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

# Secrets Manager 
resource "aws_secretsmanager_secret" "db_password" {
  name       = "csye6225-db-password-${random_id.kms_suffix.hex}"
  kms_key_id = aws_kms_key.secrets_key.arn
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
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

  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Load Balancer Security Group
resource "aws_security_group" "load_balancer_sg" {
  name        = "load-balancer-sg"
  description = "Security group for load balancer"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
resource "aws_iam_role" "ec2_s3_cloudwatch_access_role" {
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

# IAM Policy for S3 Access
resource "aws_iam_policy" "s3_cloudwatch_access_policy" {
  name        = "s3-access-policy"
  description = "Policy to allow access to S3 bucket and KMS"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetBucketPolicy"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.webapp_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.webapp_bucket.bucket}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = [
          aws_kms_key.s3_key.arn,
          aws_kms_key.secrets_key.arn
        ]
      },
      {
        Effect   = "Allow",
        Action   = "secretsmanager:GetSecretValue",
        Resource = aws_secretsmanager_secret.db_password.arn
      },
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ],
        Resource = aws_kms_key.ec2_key.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  role       = aws_iam_role.ec2_s3_cloudwatch_access_role.name
  policy_arn = aws_iam_policy.s3_cloudwatch_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_s3_access_profile" {
  name = "ec2-s3-access-profile"
  role = aws_iam_role.ec2_s3_cloudwatch_access_role.name
}

# S3 Bucket
resource "random_uuid" "bucket_uuid" {}

resource "aws_s3_bucket" "webapp_bucket" {
  bucket        = random_uuid.bucket_uuid.result
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "webapp_bucket_encryption" {
  bucket = aws_s3_bucket.webapp_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
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

# Load Balancer
resource "aws_lb" "web_app_lb" {
  name               = "csye6225-web-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_b.id,
    aws_subnet.public_subnet_c.id
  ]
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "web_app_tg" {
  name        = "csye6225-web-app-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "instance"

  health_check {
    path                = "/healthz"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# resource "aws_lb_listener" "web_app_listener" {
#   load_balancer_arn = aws_lb.web_app_lb.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web_app_tg.arn
#   }
# }

# Launch Template (using your exact user_data format)
resource "aws_launch_template" "web_app_lt" {
  name          = "csye6225-web-app-template"
  image_id      = var.aws_ami_id
  instance_type = var.aws_instance_type
  key_name      = var.aws_key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app_sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_s3_access_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = var.aws_volume_size
      volume_type           = var.aws_volume_type
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.ec2_key.arn
    }
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Install AWS CLI (if not already present)
              if ! command -v aws &> /dev/null; then
                apt-get update
              fi

              # Retrieve DB password from Secrets Manager
              DB_PASSWORD=$(aws secretsmanager get-secret-value \
                --secret-id ${aws_secretsmanager_secret.db_password.name} \
                --query SecretString \
                --output text)
                cat > /opt/csye6225/webapp/.env << EOL
                DB_HOST=${aws_db_instance.webapp_db.endpoint}
                DB_USER=${var.DB_USER}
                DB_PASSWORD=$DB_PASSWORD
                DB_NAME=${var.DB_NAME}
                DB_URI=postgresql://${var.DB_USER}:$DB_PASSWORD@${aws_db_instance.webapp_db.endpoint}/${var.DB_NAME}
                S3_BUCKET_NAME=${aws_s3_bucket.webapp_bucket.bucket}
                S3_REGION=${var.region}
              EOL
              sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
              -a fetch-config \
              -m ec2 \
              -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
              sudo systemctl start amazon-cloudwatch-agent
              sudo systemctl enable amazon-cloudwatch-agent
              systemctl enable csye6225-flask-webapp.service
              sudo systemctl restart csye6225-flask-webapp.service
              EOF
  )
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web_app_asg" {
  name              = "csye6225-web-app-asg"
  min_size          = 3
  max_size          = 5
  desired_capacity  = 3
  health_check_type = "ELB"
  vpc_zone_identifier = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_b.id,
    aws_subnet.public_subnet_c.id
  ]
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
  launch_template {
    id      = aws_launch_template.web_app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "csye6225-flask-webapp-instance"
    propagate_at_launch = true
  }

  target_group_arns = [aws_lb_target_group.web_app_tg.arn]
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.web_app_asg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.web_app_asg.name
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 10
  alarm_description   = "Scale up if CPU > 5% for 2 periods"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_app_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu-utilization"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 7
  alarm_description   = "Scale down if CPU < 3% for 2 periods"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_app_asg.name
  }
}

# RDS Configuration
data "aws_rds_engine_version" "latest_postgres" {
  engine  = "postgres"
  version = "17.4"
}

resource "aws_db_parameter_group" "webapp_db_param_group" {
  name        = "csye6225-db-parameter-group"
  family      = "postgres17"
  description = "Parameter group for the csye6225 web app database"
}

resource "aws_db_instance" "webapp_db" {
  identifier             = "csye6225-db"
  engine                 = "postgres"
  engine_version         = data.aws_rds_engine_version.latest_postgres.version
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds_key.arn
  username               = var.DB_USER
  password               = random_password.db_password.result
  db_name                = var.DB_NAME
  publicly_accessible    = false
  skip_final_snapshot    = true
  parameter_group_name   = aws_db_parameter_group.webapp_db_param_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.webapp_db_subnet_group.name
}

resource "aws_db_subnet_group" "webapp_db_subnet_group" {
  name       = "webapp-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id, aws_subnet.private_subnet_c.id]
}

resource "aws_security_group" "db_sg" {
  name        = "db-security-group"
  description = "Allow inbound traffic from the application security group"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Route53 Configuration
data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "web_app" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.subdomain
  type    = "A"

  alias {
    name                   = aws_lb.web_app_lb.dns_name
    zone_id                = aws_lb.web_app_lb.zone_id
    evaluate_target_health = true
  }
}
# Development Certificate (ACM)
resource "aws_acm_certificate" "dev_cert" {
  count             = var.aws_profile == "dev" ? 1 : 0
  domain_name       = "${var.subdomain}.${var.domain_name}"
  validation_method = "DNS"

  tags = {
    Name        = "dev-certificate"
    Environment = "dev"
    Assignment  = "csye6225"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 validation record for dev certificate
resource "aws_route53_record" "dev_cert_validation" {
  count = var.aws_profile == "dev" ? 1 : 0

  allow_overwrite = true
  name            = tolist(aws_acm_certificate.dev_cert[0].domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.dev_cert[0].domain_validation_options)[0].resource_record_value]
  ttl             = 60
  type            = tolist(aws_acm_certificate.dev_cert[0].domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.selected.zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "dev_cert_validation" {
  count = var.aws_profile == "dev" ? 1 : 0

  certificate_arn         = aws_acm_certificate.dev_cert[0].arn
  validation_record_fqdns = [aws_route53_record.dev_cert_validation[0].fqdn]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.web_app_lb.arn # Your ALB's ARN
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08" # AWS-recommended policy
  certificate_arn = var.aws_profile == "dev" ? (
    aws_acm_certificate_validation.dev_cert_validation[0].certificate_arn
    ) : (
    var.demo_certificate_arn
  )
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_app_tg.arn # Your target group
  }
}
