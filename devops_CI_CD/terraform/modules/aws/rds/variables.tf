
variable "vpc_id" {
  type = string
  description = "VPC ID for RDS (optional)"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for RDS"
}


variable "rds_sg_id" {
  type = string
  description = "Security group ID for the RDS instance"

}

variable "db_user" {
  type        = string
  description = "RDS master username"
}

variable "db_password" {
  type        = string
  description = "RDS master password"
}

variable "db_name" {
  type        = string
  description = "RDS database name"
}