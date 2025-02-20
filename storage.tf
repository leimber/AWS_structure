#archivos en EFS
resource "aws_efs_file_system" "main" {
  creation_token = "${var.project_name}-efs"
  encrypted      = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-efs"
  })
}

# Mount targets de EFS (uno por subnet privada)
resource "aws_efs_mount_target" "private" {
  count = length(aws_subnet.private)

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}