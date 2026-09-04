resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc-${var.environment}"
  }
}

resource "aws_subnet" "public" {
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${var.environment}-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = var.private_subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name = "private-subnet-${var.environment}-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public-route-table-${var.environment}"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-internet-gateway"
  }
}

resource "aws_route_table" "private" {
  count  = var.private_subnet_count
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private-route-table-${count.index + 1}"
  }
}

resource "aws_route" "private" {
  count                  = var.private_subnet_count
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = var.private_subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_nat_gateway" "main" {
  count         = var.public_subnet_count
  allocation_id = aws_eip.main[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name = "main-nat-gateway-${count.index + 1}"
  }
}

resource "aws_eip" "main" {
  count  = var.public_subnet_count
  domain = "vpc"

  tags = {
    Name = "main-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}
