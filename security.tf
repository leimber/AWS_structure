# KMS key para secretos
resource "aws_kms_key" "secrets" {
  description             = "KMS key para encriptación de secretos"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.tags
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project_name}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# Secreto para PostgreSQL
resource "aws_secretsmanager_secret" "postgresql" {
  name_prefix  = "${var.project_name}-postgresql-"  
  description  = "Credenciales para PostgreSQL"
  kms_key_id   = aws_kms_key.secrets.arn

  force_overwrite_replica_secret = true
  recovery_window_in_days       = 0

  tags = var.tags
}

# Generador de contraseña segura
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret_version" "postgresql" {
  secret_id = aws_secretsmanager_secret.postgresql.id
  secret_string = jsonencode({
    username = "dbadmin"  
    password = random_password.db_password.result
    dbname   = "${var.project_name}_db"
    port     = 5432
  })
}