locals {
  ports = var.ports
  vpc = {
    prod  = "10.1.0.0/16"
    dev   = "10.2.0.0/16"
    stage = "10.3.0.0/16"
  }

  common_tags = {
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(local.vpc[var.env], 8, 1)
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.env}-subnet"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, {
    Name = "${var.env}-igw"
  })
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.env}-rt"
  })
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}


resource "aws_eip" "eip" {
  tags = merge(local.common_tags, {
    Name = "${var.env}-ip"
  })
}

resource "aws_vpc" "vpc" {
  cidr_block                       = local.vpc[var.env]
  assign_generated_ipv6_cidr_block = true

  tags = merge(local.common_tags, {
    Name = "${var.env}-vpc"
  })
}

resource "aws_security_group" "sec_group" {
  name        = "${var.env}-sec_group"
  description = "Allow ports"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(local.common_tags, {
    Name = "${var.env}-sec_group"
  })
}

resource "aws_vpc_security_group_ingress_rule" "sec_group_ipv4" {
  for_each          = toset([for p in var.ports : tostring(p)])
  security_group_id = aws_security_group.sec_group.id
  cidr_ipv4         = aws_vpc.vpc.cidr_block
  from_port         = each.value
  ip_protocol       = "tcp"
  to_port           = each.value
}

resource "aws_vpc_security_group_ingress_rule" "sec_group_ipv6" {
  for_each          = toset([for p in var.ports : tostring(p)])
  security_group_id = aws_security_group.sec_group.id
  cidr_ipv6         = aws_vpc.vpc.ipv6_cidr_block
  from_port         = each.value
  ip_protocol       = "tcp"
  to_port           = each.value
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.sec_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.sec_group.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "sec_group_ipv4_allow" {
  for_each          = toset([for p in var.ports : tostring(p)])
  security_group_id = aws_security_group.sec_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = tonumber(each.value)
  ip_protocol       = "tcp"
  to_port           = tonumber(each.value)
}