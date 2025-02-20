#subnetgroup para ElastiCache
resource "aws_elasticache_subnet_group" "main" {
  name       = replace("${var.project_name}-cache-subnet", "_", "-")
  subnet_ids = aws_subnet.private[*].id

  tags = var.tags
}

# Cluster de Redis
resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${replace(var.project_name, "_", "-")}-cache"
  engine              = "redis"
  node_type           = "cache.t3.micro"
  num_cache_nodes     = 1
  port                = 6379
  security_group_ids  = [aws_security_group.redis.id]
  subnet_group_name   = aws_elasticache_subnet_group.main.name

  tags = merge(var.tags, {
    Name = "${var.project_name}-redis"
  })
}