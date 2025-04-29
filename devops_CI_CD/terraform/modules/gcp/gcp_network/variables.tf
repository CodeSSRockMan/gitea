variable "network_name" {
  type        = string
  description = "Name of the VPC network"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "cidr_block" {
  type        = string
  description = "Base CIDR block for the entire VPC (e.g. 10.10.0.0/16)"
}
# variable "project" {
#   description = "ID del proyecto en GCP"
#   type        = string
# }
variable "project_id" {
  description = "ID of the GCP project"
  type        = string
}
