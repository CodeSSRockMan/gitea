resource "google_compute_firewall" "allow_http" {
  name    = "${var.gitea_vm_name}-fw-http"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = var.target_tags

  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"
}
