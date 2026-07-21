locals {
  az_index = {
    for index, az in var.availability_zones : az => index
  }
}

resource "aws_vpc" "platform" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_subnet" "private_platform" {
  for_each = local.az_index

  vpc_id                  = aws_vpc.platform.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, each.value)
  map_public_ip_on_launch = false

  tags = {
    Name                                      = "${local.name_prefix}-platform-${each.key}"
    Tier                                      = "platform"
    "kubernetes.io/role/internal-elb"         = "1"
    "kubernetes.io/cluster/${local.name_prefix}" = "shared"
  }
}

resource "aws_subnet" "data" {
  for_each = local.az_index

  vpc_id                  = aws_vpc.platform.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 8 + each.value)
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name_prefix}-data-${each.key}"
    Tier = "data"
  }
}

resource "aws_subnet" "endpoints" {
  for_each = local.az_index

  vpc_id                  = aws_vpc.platform.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 12 + each.value)
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name_prefix}-endpoints-${each.key}"
    Tier = "endpoints"
  }
}

resource "aws_internet_gateway" "egress" {
  count = var.enable_nat_gateway ? 1 : 0

  vpc_id = aws_vpc.platform.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

resource "aws_subnet" "public_egress" {
  count = var.enable_nat_gateway ? 1 : 0

  vpc_id                  = aws_vpc.platform.id
  availability_zone       = var.availability_zones[0]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 240)
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name_prefix}-public-egress"
    Tier = "egress"
  }
}

resource "aws_route_table" "public_egress" {
  count = var.enable_nat_gateway ? 1 : 0

  vpc_id = aws_vpc.platform.id

  tags = {
    Name = "${local.name_prefix}-public-egress-rt"
  }
}

resource "aws_route" "public_internet" {
  count = var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.public_egress[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.egress[0].id
}

resource "aws_route_table_association" "public_egress" {
  count = var.enable_nat_gateway ? 1 : 0

  subnet_id      = aws_subnet.public_egress[0].id
  route_table_id = aws_route_table.public_egress[0].id
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "egress" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public_egress[0].id

  depends_on = [aws_internet_gateway.egress]

  tags = {
    Name = "${local.name_prefix}-nat"
  }
}

resource "aws_route_table" "private_platform" {
  for_each = local.az_index

  vpc_id = aws_vpc.platform.id

  tags = {
    Name = "${local.name_prefix}-platform-${each.key}-rt"
  }
}

resource "aws_route" "private_nat" {
  for_each = var.enable_nat_gateway ? aws_route_table.private_platform : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.egress[0].id
}

resource "aws_route_table_association" "private_platform" {
  for_each = aws_subnet.private_platform

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_platform[each.key].id
}

resource "aws_route_table" "data" {
  for_each = local.az_index

  vpc_id = aws_vpc.platform.id

  tags = {
    Name = "${local.name_prefix}-data-${each.key}-rt"
  }
}

resource "aws_route_table_association" "data" {
  for_each = aws_subnet.data

  subnet_id      = each.value.id
  route_table_id = aws_route_table.data[each.key].id
}

resource "aws_route_table" "endpoints" {
  for_each = local.az_index

  vpc_id = aws_vpc.platform.id

  tags = {
    Name = "${local.name_prefix}-endpoints-${each.key}-rt"
  }
}

resource "aws_route_table_association" "endpoints" {
  for_each = aws_subnet.endpoints

  subnet_id      = each.value.id
  route_table_id = aws_route_table.endpoints[each.key].id
}

resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.platform.id

  tags = {
    Name = "${local.name_prefix}-vpc-flow-log"
  }
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/${local.name_prefix}/flow-logs"
  retention_in_days = 30

  tags = {
    Name = "${local.name_prefix}-flow-logs"
  }
}

resource "aws_iam_role" "flow_logs" {
  name = "${local.name_prefix}-vpc-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "publish-vpc-flow-logs"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "${aws_cloudwatch_log_group.flow_logs.arn}:*"
    }]
  })
}
