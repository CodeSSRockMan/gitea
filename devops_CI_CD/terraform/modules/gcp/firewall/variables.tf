variable "network" {
  type        = string
  description = "Name or self_link of the VPC network"
}

variable "gitea_vm_name" {
  type        = string
  description = "Name of the Gitea VM (used in firewall naming)"
}

variable "target_tags" {
  type        = list(string)
  description = "List of tags to match VM targets for firewall rules"
}
