variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Target AWS Region"
}

variable "vpc_name" {
  type        = string
  description = "Value of the Name tag for your existing VPC"
}

variable "subnet_name" {
  type        = string
  description = "Value of the Name tag for your existing Subnet"
}

variable "security_group_name" {
  type        = string
  description = "The exact name of your existing Security Group"
}

variable "key_name" {
  type        = string
  description = "The name of your pre-existing AWS PEM Key Pair"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance sizing"
}
