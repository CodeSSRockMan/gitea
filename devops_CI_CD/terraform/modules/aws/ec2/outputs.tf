
output "public_ip" {
  value = aws_instance.ec2.public_ip
}
output "instance_id" {
  value = aws_instance.ec2.id
}

variable "instance_name" {
  description = "The Name tag for the EC2 instance"
  type        = string
}
