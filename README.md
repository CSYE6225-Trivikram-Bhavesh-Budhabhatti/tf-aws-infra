## Clone the repository
Clone this repository to your local machine

```bash
git clone https://github.com/trivikram-bhavesh-budhabhatti/terraform-aws-infrastructure.git
cd tf-aws-infra
```

## Configure your AWS credentials
Make sure AWS CLI is configured on your local machine using the following command:
    
```bash
aws configure
```

## Modify terraform.tfvars for environment-specific settings

## Initialize Terraform
Run terraform init to initialize the Terraform configuration and download the necessary provider plugins.
```bash
terraform init
```

## Review the execution plan
Run terraform plan to see the changes that will be made by the Terraform configuration:
```bash
terraform plan
```
## Format the Terraform configuration
Run terraform fmt to fix the formatting of the code
```bash
terraform fmt
```

## Apply the Terraform configuration
Run terraform apply to create the AWS infrastructure. Terraform will prompt you to confirm:
```bash
terraform apply
```

## Destroy the infrastructure
To delete all the resources created by Terraform, use the following command:
```bash
terraform destroy
```

## Terraform Resources Created
- VPC: A Virtual Private Cloud (VPC) is created with the CIDR block defined by the vpc_cidr variable.
- Subnets:
  - 3 Public subnets
  - 3 Private subnets
- Internet Gateway (IGW): A gateway for outbound traffic from public subnets.
- Route Tables:
  - A public route table for the public subnets
  - A private route table for the private subnets
- Route Table Associations: Associates each subnet with its respective route table.
  
## Variables
### Required Variables:
- aws_profile: AWS CLI profile to use.
- region: AWS region to deploy resources in.
- vpc_cidr: CIDR block for the VPC.
- vpc_name: Name tag for the VPC.
- public_subnet_cidrs: CIDR blocks for public subnets.
- private_subnet_cidrs: CIDR blocks for private subnets.
- availability_zones: List of availability zones to use for the subnets.
- destination_cidr: Destination CIDR block for the public route (usually 0.0.0.0/0 for the Internet).
- public_route_table_name: Name tag for the public route table.
- private_route_table_name: Name tag for the private route table.
Optional Variables (Customizable):
You can modify any other variables in terraform.tfvars to suit your specific infrastructure requirements.
