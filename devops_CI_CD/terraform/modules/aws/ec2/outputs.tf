
output "public_ip" {
  value = aws_instance.gitea_web.public_ip
}
