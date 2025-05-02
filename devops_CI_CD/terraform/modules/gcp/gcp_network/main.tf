resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
  description             = "VPC for ${var.network_name}"
  project                 = var.project_id
}

locals {
  subnet_definition = {
    name       = "public"
    new_bits   = 8
    netnum     = 0
    private_ip = false
  }
}



resource "google_compute_subnetwork" "public_subnet" {
  name                     = "${var.network_name}-public"
  ip_cidr_range            = cidrsubnet(var.cidr_block, local.subnet_definition.new_bits, local.subnet_definition.netnum)
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = local.subnet_definition.private_ip
  description              = "Public subnet for ${var.network_name}"
}
