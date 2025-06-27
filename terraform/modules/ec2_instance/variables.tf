variable "name" {
  description = "Name to be used for the instance and related resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be created"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "allowed_inbound_cidr_ports" {
  description = "List of objects for CIDR-based inbound rules"
  type = list(object({
    port        = number
    cidr        = string
    description = string
  }))
  default = []
}

variable "allowed_inbound_sg_ports" {
  description = "List of objects for SG-based inbound rules"
  type = list(object({
    port                     = number
    source_security_group_id = string
    description              = string
  }))
  default = []
}

variable "user_data" {
  description = "User data script for the instance"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default = {
    Project = "RSSchoolDevOpsCourse"
  }
}

variable "instance_profile" {
  description = "The name of the IAM instance profile to associate"
  type        = string
  default     = "SSMAccess"
}
