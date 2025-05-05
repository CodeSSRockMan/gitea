resource "aws_security_group" "ephimeral_sg" {
  name        = "ephimeral-sg"
  description = "Security group for ephemeral resources"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ephimeral-sg"


  }
}