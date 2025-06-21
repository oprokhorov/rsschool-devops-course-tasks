variable "aws_region" {
  description = "AWS region for resources and backend"
  type        = string
  default     = "us-east-1"
}

variable "deployer_public_key" {
  type      = string
  sensitive = true
}

variable "management_ip" {
  description = "IP address with ssh access to bastion host"
  type        = string
  sensitive   = true
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "172.21.32.0/20"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for the first public subnet"
  type        = string
  default     = "172.21.32.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for the second public subnet"
  type        = string
  default     = "172.21.34.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for the first private subnet"
  type        = string
  default     = "172.21.33.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for the second private subnet"
  type        = string
  default     = "172.21.35.0/24"
}

