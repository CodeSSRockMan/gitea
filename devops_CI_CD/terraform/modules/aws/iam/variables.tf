variable "role_name" {
  description = "IAM Role name"
  type        = string
}

variable "policy_arns" {
  description = "List of managed policy ARNs"
  type        = list(string)
}
