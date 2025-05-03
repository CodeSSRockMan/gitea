
variable "instance_type" {}
variable "ami_id" {}
variable "subnet_id" {}
variable "security_group_id" {}

variable "iam_instance_profile" {
  description = "Name of the IAM instance profile to attach"
  type        = string
  default     = null
}
