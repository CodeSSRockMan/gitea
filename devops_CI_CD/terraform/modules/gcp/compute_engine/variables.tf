variable "gitea_vm_name" {
  type        = string
  description = "Name of the Gitea virtual machine"
}

variable "machine_type" {
  type        = string
  description = "Machine type for the instance (e.g. e2-micro)"
}

variable "zone" {
  type        = string
  description = "GCP zone to deploy the instance (e.g. us-central1-a)"
}

variable "image" {
  type        = string
  description = "Boot disk image (e.g. debian-cloud/debian-11)"
}

variable "network" {
  type        = string
  description = "Name or self_link of the VPC network"
}

variable "tags" {
  type        = list(string)
  description = "List of tags to apply to the instance"
}

variable "gitea_secret_user" {
  type        = string
  description = "Name of the Secret Manager secret that holds the SSH username"
}

variable "gitea_secret_password" {
  type        = string
  description = "Name of the Secret Manager secret that holds the SSH public key"
}
variable "subnetwork" {
  description = "Subnetwork self_link or name for the Gitea VM"
  type        = string
}
