resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSM outbound only"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "gitea-rds-sg"
  description = "Allow MySQL"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gitea-rds-sg"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Security group for public Gitea EC2"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # acceso público HTTP
  security_group_id = aws_security_group.ec2_sg.id
  description       = "Allow HTTP"
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2_sg.id
  description       = "Allow all outbound"
}

# resource "aws_security_group" "jenkins_sg" {
#   name        = "jenkins-sg"
#   description = "Allow HTTP access to Jenkins and HTTPS egress"
#   vpc_id      = var.vpc_id

#   ingress {
#     from_port   = 8080
#     to_port     = 8080
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # O usa tu IP: ["X.X.X.X/32"]
#     description = "Allow web access to Jenkins UI"
#   }

#   egress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow outbound HTTPS"
#   }

#   tags = {
#     Name = "jenkins-sg"
#   }
# }
