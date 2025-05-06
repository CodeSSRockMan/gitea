
variable "region" {
  type = string
}
variable "instance_name" {
  description = "The Name tag for the EC2 instance"
  type        = string
}
variable "vpc_cidr" {
  type = string
}

variable "instance_type" {
  type = string
}
variable "bucket_name" {
  type = string
}

variable "db_name" {
  type = string
}
#variable "vpc_id" {}       # ← Falta
#variable "ec2_sg_id" {}    # ← Falta
