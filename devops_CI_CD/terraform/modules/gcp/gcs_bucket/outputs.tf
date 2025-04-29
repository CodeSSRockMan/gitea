output "bucket_name" {
  value       = google_storage_bucket.gitea_bucket.name
  description = "The name of the created GCS bucket"
}

output "bucket_url" {
  value       = google_storage_bucket.gitea_bucket.url
  description = "URL of the GCS bucket"
}
