locals {
  public_subnets = {
    "${var.region}a" = "10.0.1.0/24"
    "${var.region}b" = "10.0.2.0/24"
    "${var.region}c" = "10.0.3.0/24"
  }

  private_subnets = {
    "${var.region}a" = "10.0.20.0/24"
    "${var.region}b" = "10.0.21.0/24"
    "${var.region}c" = "10.0.22.0/24"
  }

}

//vpc
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

//internet_gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "Internet-Gateway"
  }
}


resource "aws_subnet" "public_subnet" {
  count                   = length(local.public_subnets)
  cidr_block              = element(values(local.public_subnets), count.index)
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = element(keys(local.public_subnets), count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "Pub-Subnet"
  }
}


resource "aws_subnet" "private_subnet" {
  count                   = length(local.private_subnets)
  cidr_block              = element(values(local.private_subnets), count.index)
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = false
  availability_zone       = element(keys(local.private_subnets), count.index)



  tags = {
    Name = "Private-Sub-A"
  }
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Public-RT"
  }
}

resource "aws_route_table_association" "public_rt_association" {
  count          = length(local.public_subnets)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_rt_association" {
  count          = length(local.private_subnets)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}


resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Priavte-RT"
  }
}

resource "aws_eip" "elastic_ip" {
  vpc = true

  tags = {
    Name = "Elastic-IP"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public_subnet.1.id

  tags = {
    Name = "Nat-Gateway"
  }
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id

  timeouts {
    create = "5m"
  }
}