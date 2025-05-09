# Allow HTTP traffic from anywhere
resource "google_compute_firewall" "allow_http" {
  name    = "${var.gitea_vm_name}-fw-http"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  target_tags   = var.target_tags

  description   = "Allow HTTP traffic from any source"
}

# Allow SSH only from IAP IP ranges
resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "${var.gitea_vm_name}-fw-iap-ssh"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"] # Reserved for Identity-Aware Proxy

  target_tags   = var.target_tags

  description   = "Allow SSH access through IAP only"
}

resource "google_compute_firewall" "allow_gitea_web" {
  name    = "${var.gitea_vm_name}-fw-gitea"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]  # o restringe si quieres más seguridad
  target_tags   = var.target_tags

  description   = "Allow external access to Gitea web interface on port 3000"
}
