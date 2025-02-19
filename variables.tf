# variables.tf
variable "region" {
  description = "AWS Region"
  default     = "us-west-2" # You can change this to your desired region
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnets"
  default     = "10.0.0.0/24"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "destination_cidr" {
  default = "0.0.0.0/0"
}