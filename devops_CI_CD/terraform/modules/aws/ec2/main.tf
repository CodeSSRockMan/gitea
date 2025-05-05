
<<<<<<< HEAD
resource "aws_instance" "ec2" {
=======
resource "aws_instance" "gitea_web" {
>>>>>>> origin/develop
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
<<<<<<< HEAD
  iam_instance_profile        = var.iam_instance_profile

  tags = {
    Name = var.instance_name
  }

  lifecycle {
    ignore_changes = [associate_public_ip_address] #
=======


  tags = {
    Name = "AWS-EC2"
>>>>>>> origin/develop
  }
}
