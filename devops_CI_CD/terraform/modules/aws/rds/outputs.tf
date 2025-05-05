output "rds_endpoint" {
  value       = aws_db_instance.gitea_rds.endpoint
  description = "DNS endpoint of the RDS instance"
}

output "rds_identifier" {
  value       = aws_db_instance.gitea_rds.identifier
}

output "rds_id" {
  value       = aws_db_instance.gitea_rds.id
}
