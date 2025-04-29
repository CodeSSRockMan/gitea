
resource "aws_instance" "gitea_web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true


  tags = {
    Name = "AWS-EC2"
  }
}
