variable "aws_region" {
  description = "AWS region for resources and backend"
  type        = string
  default     = "us-east-1"
}

variable "management_ip" {
  description = "IP address for management access"
  type        = string
  sensitive   = true
}
