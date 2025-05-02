output "vpc_network_id" {
  description = "VPC network ID."
  value       = module.gcp_network.vpc_network_id
}

output "public_subnet_self_link" {
  description = "Public subnet self-link."
  value       = module.gcp_network.subnet_public_self_link
}

output "gitea_instance_public_ip" {
  description = "Public IP of Gitea instance."
  value       = module.compute_engine.public_ip
}

output "gcs_bucket_name" {
  description = "GCS bucket name for backups."
  value       = module.gcs_bucket.bucket_name
}

output "gcs_bucket_url" {
  description = "Public URL of the GCS bucket."
  value       = "https://storage.cloud.google.com/${module.gcs_bucket.bucket_name}"
}
