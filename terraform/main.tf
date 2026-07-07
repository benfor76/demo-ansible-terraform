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

# 1. Discover existing VPC by Name Tag
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# 2. Discover existing Subnet within that VPC by Name Tag
data "aws_subnet" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.subnet_name]
  }
  vpc_id = data.aws_vpc.selected.id
}

# 3. Discover existing Security Group by Name within that VPC
data "aws_security_group" "selected" {
  filter {
    name   = "group-name"
    values = [var.security_group_name]
  }
  vpc_id = data.aws_vpc.selected.id
}

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

# Output the IP for Ansible visibility
output "instance_public_ip" {
  value       = aws_instance.rhel_vm.public_ip
  description = "The public IP address of the new RHEL VM"
}
