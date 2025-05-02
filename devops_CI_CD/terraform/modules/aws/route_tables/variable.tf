variable "vpc_id" {
  type        = string
  description = "ID of the VPC to associate the route table"
}

variable "internet_gateway_id" {
  type        = string
  description = "ID of the Internet Gateway for the public route"
}

variable "public_subnet_id" {
  type        = string
  description = "ID of the public subnet to associate the route table"
}
