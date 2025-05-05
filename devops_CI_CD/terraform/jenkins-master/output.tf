output "jenkins_public_ip" {
  value = module.jenkins_master.public_ip
}

output "jenkins_instance_id" {
  value = module.jenkins_master.instance_id
}

output "jenkins_sg_id" {
  value = module.security_group.jenkins_sg_id
}

output "iam_instance_profile_name" {
  value = module.iam.instance_profile_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.vpc.public_subnet_id
}
