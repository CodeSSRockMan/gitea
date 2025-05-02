output "http_rule_name" {
  value       = google_compute_firewall.allow_http.name
  description = "Name of the HTTP firewall rule"
}

