# Subnet group para RDS
resource "aws_db_subnet_group" "main" {
  name       = replace("${var.project_name}-db-subnet", "_", "-")
  subnet_ids = aws_subnet.private[*].id

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-subnet"
  })
}

#Primera instancia RDS PostgreSQL
resource "aws_db_instance" "primary" {
  identifier           = replace("${var.project_name}-db-1", "_", "-")
  engine              = "postgres"
  engine_version      = "14"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  storage_type        = "gp2"
  availability_zone   = data.aws_availability_zones.available.names[0]

  db_name  = replace("${var.project_name}_db", "-", "_")
  username = jsondecode(aws_secretsmanager_secret_version.postgresql.secret_string)["username"]
  password = jsondecode(aws_secretsmanager_secret_version.postgresql.secret_string)["password"]

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.postgresql.id]

  skip_final_snapshot = true
  backup_retention_period = 7

  tags = merge(var.tags, {
    Name = "${var.project_name}-postgresql-1"
  })
}

#segunda instancia RDS PostgreSQL
resource "aws_db_instance" "secondary" {
  identifier           = replace("${var.project_name}-db-2", "_", "-")
  engine              = "postgres"
  engine_version      = "14"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  storage_type        = "gp2"
  availability_zone   = data.aws_availability_zones.available.names[1]

  db_name  = replace("${var.project_name}_db", "-", "_")
  username = jsondecode(aws_secretsmanager_secret_version.postgresql.secret_string)["username"]
  password = jsondecode(aws_secretsmanager_secret_version.postgresql.secret_string)["password"]

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.postgresql.id]

  skip_final_snapshot = true
  backup_retention_period = 7

  tags = merge(var.tags, {
    Name = "${var.project_name}-postgresql-2"
  })
}