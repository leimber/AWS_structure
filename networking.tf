
#obtnción AZ

data "aws_availability_zones" "available" {
  state = "available"
}

#creación VPC de servcios


resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc"
  })
}

#creación gateway conexión a internet

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-igw"
  })
}


# Subnets Públicas (para ALB público)
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-public-${count.index + 1}"
  })
}

# Subnets Privadas (para las instancias EC2)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-private-${count.index + 1}"
  })
}

# elastic IP para NAT Gateway
resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  })
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-${count.index + 1}"
  })
}

# Tabla de rutas pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-public-rt"
  })
}

# tabla de rutas privadas
resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-private-rt-${count.index + 1}"
  })
}

# vinculacion tabla de rutas publicas
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# vinculación tabla de rutas privadas
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}



#CREACIÓN VPC SECUNDARIA PARA BACKUP

# VPC  backup
resource "aws_vpc" "backup" {
  cidr_block           = "172.16.0.0/16"  # Diferente rango de IPs que la VPC principal
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-backup-vpc"
  })
}

# Subnet backups
resource "aws_subnet" "backup" {
  count             = 2
  vpc_id            = aws_vpc.backup.id
  cidr_block        = "172.16.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-backup-${count.index + 1}"
  })
}

# VPC Peering
resource "aws_vpc_peering_connection" "main_to_backup" {
  vpc_id      = aws_vpc.main.id
  peer_vpc_id = aws_vpc.backup.id
  auto_accept = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-peering"
  })
}

#tabla de rutas VPC principal para acceder VPC de backup
resource "aws_route" "main_to_backup_private" {
  count                     = 2
  route_table_id            = aws_route_table.private[count.index].id
  destination_cidr_block    = aws_vpc.backup.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.main_to_backup.id
}

#tabla de ruta VPC de backup
resource "aws_route_table" "backup" {
  vpc_id = aws_vpc.backup.id

  route {
    cidr_block                = aws_vpc.main.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.main_to_backup.id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-backup-rt"
  })
}

# Asociar tabla subnets de backup
resource "aws_route_table_association" "backup" {
  count          = 2
  subnet_id      = aws_subnet.backup[count.index].id
  route_table_id = aws_route_table.backup.id
}