output "gitea_vm_name" {
  value       = google_compute_instance.this.name
  description = "Name of the Gitea VM instance"
}

output "gitea_vm_ip" {
  value       = google_compute_instance.this.network_interface[0].access_config[0].nat_ip
  description = "Public IP address of the Gitea VM"
}

output "zone" {
  value       = google_compute_instance.this.zone
  description = "Zone where the Gitea VM is deployed"
}


output "public_ip" {
  description = "Public IP address of the Gitea instance."
  value       = google_compute_instance.this.network_interface[0].access_config[0].nat_ip
}
