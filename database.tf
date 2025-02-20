# Subnet group para RDS
resource "aws_db_subnet_group" "main" {
  name       = replace("${var.project_name}-db-subnet", "_", "-")
  subnet_ids = aws_subnet.private[*].id

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-subnet"
  })
}

# Instancia RDS PostgreSQL
resource "aws_db_instance" "main" {
  identifier           = replace("${var.project_name}-db", "_", "-")
  engine              = "postgres"
  engine_version      = "14"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  storage_type        = "gp2"

  db_name  = replace("${var.project_name}_db", "-", "_")
  username = jsondecode(aws_secretsmanager_secret_version.postgresql.secret_string)["username"]
  password = jsondecode(aws_secretsmanager_secret_version.postgresql.secret_string)["password"]

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.postgresql.id]

  skip_final_snapshot = true  # Para desarrollo, en producción debería ser false
  
  backup_retention_period = 7
  multi_az               = false  # Para desarrollo, en producción debería ser true

  tags = merge(var.tags, {
    Name = "${var.project_name}-postgresql"
  })
}