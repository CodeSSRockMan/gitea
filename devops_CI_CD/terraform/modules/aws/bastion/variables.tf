variable "subnet_id" {
  type        = string
  description = "ID of the subnet where the bastion will be deployed (should be public)"
}

variable "security_group_id" {
  type        = string
  description = "ID of the security group for the bastion instance"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for the bastion EC2 instance (e.g., Ubuntu 22.04 or Amazon Linux 2)"
}