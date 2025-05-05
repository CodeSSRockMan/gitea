
output "network_self_link" {
  value = google_compute_network.vpc_network.self_link
}


output "vpc_network_id" {
  description = "Self link of the VPC network"
  value       = google_compute_network.vpc_network.id
}

output "subnet_public_self_link" {
  description = "Self link of the public subnet"
  value       = google_compute_subnetwork.public_subnet.self_link
}
