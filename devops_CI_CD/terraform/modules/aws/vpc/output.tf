
output "vpc_id" {
  value = aws_vpc.gitea_main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

