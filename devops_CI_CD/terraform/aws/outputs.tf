output "s3_bucket_name" {
  description = "S3 bucket name for backups."
  value       = module.s3_bucket.bucket_name
}

output "s3_bucket_url" {
  description = "Public URL of the S3 bucket."
  value       = "https://s3.amazonaws.com/${module.s3_bucket.bucket_name}"
}

output "vpc_id" {
  description = "AWS VPC ID."
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "Public Subnet ID."
  value       = module.vpc.public_subnet_id
}

output "gitea_instance_public_ip" {
  description = "Public IP of Gitea EC2 instance."
  value       = module.ec2.public_ip
}
output "rds_endpoint" {
  value = module.rds.rds_endpoint
}

output "rds_db_name" {
  value = module.rds.rds_name
}
