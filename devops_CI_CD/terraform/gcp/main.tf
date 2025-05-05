module "gcp_network" {
  source       = "../modules/gcp/gcp_network"
  network_name = var.network_name
  region       = var.region
  cidr_block   = var.cidr_block
  project_id   = var.project_id

}


module "compute_engine" {
  source                = "../modules/gcp/compute_engine"
  gitea_vm_name         = var.gitea_vm_name
  machine_type          = var.machine_type
  zone                  = var.zone
  image                 = var.image
  network               = module.gcp_network.vpc_network_id          # <-- importante
  subnetwork            = module.gcp_network.subnet_public_self_link # <-- nuevo
  tags                  = var.instance_tags
  gitea_secret_user     = var.gitea_secret_user
  gitea_secret_password = var.gitea_secret_password
}


module "firewall" {
  source        = "../modules/gcp/firewall"
  network       = module.gcp_network.vpc_network_id # <-- importante, network es un output del módulo de red
  gitea_vm_name = var.gitea_vm_name
  target_tags   = var.instance_tags
  depends_on    = [module.gcp_network] # <-- importante, depende de la red

}

module "gcs_bucket" {
  source      = "../modules/gcp/gcs_bucket"
  bucket_name = var.bucket_name
  region      = var.region
}