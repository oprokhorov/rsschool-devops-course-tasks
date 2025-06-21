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

variable "allowed_inbound_ports" {
  description = "Map of allowed inbound ports and their source (CIDR or security group) and description"
  type = map(object({
    port                     = number
    cidr                     = optional(string)
    source_security_group_id = optional(string)
    description              = string
  }))
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
