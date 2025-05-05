# GCP Compute Engine Module
resource "google_compute_instance" "this" {
  name                = var.gitea_vm_name
  machine_type        = var.machine_type
  zone                = var.zone
  deletion_protection = false

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    access_config {}
  }




  tags = var.tags
}
