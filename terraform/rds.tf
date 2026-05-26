resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  subnet_ids  = aws_subnet.private_db[*].id
  description = "Private DB subnets - no internet route"

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
  }
}

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"

  engine         = "postgres"
  engine_version = "15"
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  # Aucun accès depuis internet
  publicly_accessible = false

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  backup_retention_period = 0
  backup_window           = "02:00-03:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name        = "${var.project_name}-db"
    Environment = var.environment
  }
}
