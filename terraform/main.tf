terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

#------------------New block to replace 1-3--------------
# 1. Dynamic VPC Discovery (Handles ID or Name Tag)
data "aws_vpc" "selected" {
  id = startswith(var.vpc_name, "vpc-") ? var.vpc_name : null

  dynamic "filter" {
    for_each = startswith(var.vpc_name, "vpc-") ? [] : [1]
    content {
      name   = "tag:Name"
      values = [var.vpc_name]
    }
  }
}

# 2. Dynamic Subnet Discovery (Handles ID or Name Tag)
data "aws_subnet" "selected" {
  id     = startswith(var.subnet_name, "subnet-") ? var.subnet_name : null
  vpc_id = data.aws_vpc.selected.id

  dynamic "filter" {
    for_each = startswith(var.subnet_name, "subnet-") ? [] : [1]
    content {
      name   = "tag:Name"
      values = [var.subnet_name]
    }
  }
}

# 3. Dynamic Security Group Discovery (Handles ID or Group Name)
data "aws_security_group" "selected" {
  id     = startswith(var.security_group_name, "sg-") ? var.security_group_name : null
  vpc_id = data.aws_vpc.selected.id

  dynamic "filter" {
    for_each = startswith(var.security_group_name, "sg-") ? [] : [1]
    content {
      name   = "group-name"
      values = [var.security_group_name]
    }
  }
}
#--------------------------------------------------------

# 4. Discover the latest official RHEL 9 AMI
data "aws_ami" "rhel9" {
  most_recent = true
  owners      = ["309956199498"] # Official Red Hat Owner ID

  filter {
    name   = "name"
    values = ["RHEL-9.*_HVM-*-x86_64-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# 5. Provision the RHEL VM mapping the discovered assets
resource "aws_instance" "rhel_vm" {
  ami                    = data.aws_ami.rhel9.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.selected.id
  vpc_security_group_ids = [data.aws_security_group.selected.id]
  key_name               = var.key_name

  tags = {
    Name        = "AAP-Provisioned-RHEL-VM"
    ManagedBy   = "Ansible-and-Terraform"
    Environment = "Demo"
  }
}

# 6. Allocate and associate an Elastic IP (EIP) to the instance
resource "aws_eip" "rhel_eip" {
  instance = aws_instance.rhel_vm.id
  domain   = "vpc"

  tags = {
    Name        = "AAP-Provisioned-RHEL-EIP"
    ManagedBy   = "Ansible-and-Terraform"
  }
}

# Output the IP for Ansible visibility
output "instance_public_ip" {
  value       = aws_instance.rhel_vm.public_ip
  description = "The public IP address of the new RHEL VM"
}

output "instance_public_dns" {
  value       = aws_eip.rhel_eip.public_dns
  description = "The AWS-provided public IPv4 DNS name assigned to the EIP"
}
