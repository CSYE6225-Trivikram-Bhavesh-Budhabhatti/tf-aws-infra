variable "region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile"
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name of the VPC"
  default     = "dev-vpc"
}
variable "igw_name" {
  description = "Name of the igw"
  default     = "dev-igw"
}

variable "public_route_table_name" {
  description = "Name of the public route table"
  default     = "public-route-table"
}

variable "private_route_table_name" {
  description = "Name of the private route table"
  default     = "private-route-table"
}
variable "public_subnet_name" {
  description = "name for public subnet"
  # type        = list(string)
  default = ["public-subnet-a", "public-subnet-b", "public-subnet-c"]
}
variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "destination_cidr" {
  description = "Destination CIDR block"
  default     = "0.0.0.0/0"
}


variable "private_subnet_name" {
  description = "name for private subnet"
  type        = list(string)
  default     = ["private-subnet-a", "private-subnet-b", "private-subnet-c"]
}
variable "aws_ami_id" {
  description = "aws ami id"
  type        = string
  default     = "ami-0ddc07efd780029fb"
}
variable "aws_instance_type" {
  description = "instance type"
  type        = string
  default     = "t2.micro"
}
variable "aws_volume_size" {
  description = "name for private subnet"
  type        = string
  default     = "25"
}
variable "aws_volume_type" {
  description = "name for private subnet"
  type        = string
  default     = "gp2"
}
variable "aws_key_name" {
  description = "name for private subnet"
  type        = string
  default     = "aws-demo"
}