locals {
  interface_endpoint_services = toset([
    "ec2",
    "ec2messages",
    "ecr.api",
    "ecr.dkr",
    "logs",
    "ssm",
    "ssmmessages",
    "sts"
  ])
}

resource "aws_security_group" "endpoints" {
  name        = "${local.name_prefix}-vpce"
  description = "Allow HTTPS from the platform VPC to interface endpoints"
  vpc_id      = aws_vpc.platform.id

  tags = {
    Name = "${local.name_prefix}-vpce"
  }
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_https" {
  security_group_id = aws_security_group.endpoints.id
  description       = "HTTPS from resources inside the VPC"
  cidr_ipv4         = var.vpc_cidr
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "endpoints_return" {
  security_group_id = aws_security_group.endpoints.id
  description       = "Return traffic to resources inside the VPC"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "-1"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.platform.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat(
    [for route_table in aws_route_table.private_platform : route_table.id],
    [for route_table in aws_route_table.data : route_table.id]
  )

  tags = {
    Name = "${local.name_prefix}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoint_services

  vpc_id              = aws_vpc.platform.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for subnet in aws_subnet.endpoints : subnet.id]
  security_group_ids  = [aws_security_group.endpoints.id]

  tags = {
    Name    = "${local.name_prefix}-${replace(each.value, ".", "-")}-endpoint"
    Service = each.value
  }
}
