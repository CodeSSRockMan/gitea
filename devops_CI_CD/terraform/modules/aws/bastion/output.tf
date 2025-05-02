output "bastion_private_ip" {
  value = aws_instance.bastion.private_ip
}

output "bastion_instance_id" {
  value = aws_instance.bastion.id
}

output "bastion_iam_role_name" {
  value = aws_iam_role.ssm_role.name
}
