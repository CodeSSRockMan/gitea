resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "gitea-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "gitea-subnet-group"
  }
}

resource "aws_db_instance" "gitea_rds" {
  identifier              = "gitea-db-instance"
  db_name                 = var.db_name
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  username                = var.db_user
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [var.rds_sg_id]

  skip_final_snapshot     = true
  publicly_accessible     = false
  multi_az                = false
  storage_encrypted       = true
  backup_retention_period = 7

  

  tags = {
    Name    = "gitea-db"
    Project = "dr"
  }
}
