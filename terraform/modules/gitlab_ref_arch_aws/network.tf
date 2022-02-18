locals {
  existing_network = var.vpc_id != null && (var.subnet_pub_ids != null || var.subnet_priv_ids != null)
  create_network   = var.create_network && !local.existing_network
  default_network  = !local.create_network && !local.existing_network
}

resource "aws_default_vpc" "default" {
  count = local.default_network ? 1 : 0
  tags = {
    Name = "Default VPC"
  }
}

data "aws_subnet_ids" "defaults" {
  count  = local.default_network ? 1 : 0
  vpc_id = aws_default_vpc.default[0].id

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

data "aws_availability_zones" "defaults" {
  exclude_names = var.zones_exclude
}

# Create new network stack
resource "aws_vpc" "gitlab_vpc" {
  count                = local.create_network ? 1 : 0
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

## Public Subnet(s)
resource "aws_subnet" "gitlab_vpc_sn_pub" {
  count                   = local.create_network ? var.subnet_pub_count : 0
  vpc_id                  = aws_vpc.gitlab_vpc[0].id
  cidr_block              = var.subnet_pub_cidr_block[count.index]
  availability_zone       = data.aws_availability_zones.defaults.names[(count.index + length(data.aws_availability_zones.defaults.names)) % length(data.aws_availability_zones.defaults.names)]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.prefix}-sub-pub-${count.index + 1}"
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_internet_gateway" "gitlab_vpc_gw" {
  count  = local.create_network ? min(var.subnet_pub_count, 1) : 0
  vpc_id = aws_vpc.gitlab_vpc[0].id

  tags = {
    Name = "${var.prefix}-igw"
  }
}

resource "aws_route_table" "gitlab_vpc_rt_pub" {
  count = local.create_network ? min(var.subnet_pub_count, 1) : 0

  vpc_id = aws_vpc.gitlab_vpc[0].id

  route {
    cidr_block = "0.0.0.0/0" # Internet Access
    gateway_id = aws_internet_gateway.gitlab_vpc_gw[0].id
  }

  tags = {
    Name = "${var.prefix}-pub-rt"
  }
}

resource "aws_route_table_association" "gitlab_vpc_rt_pub_rta" {
  count = local.create_network ? var.subnet_pub_count : 0

  subnet_id      = aws_subnet.gitlab_vpc_sn_pub[count.index].id
  route_table_id = aws_route_table.gitlab_vpc_rt_pub[0].id
}

## Private Subnet(s)
resource "aws_subnet" "gitlab_vpc_sn_priv" {
  count             = local.create_network ? var.subnet_priv_count : 0
  vpc_id            = aws_vpc.gitlab_vpc[0].id
  cidr_block        = var.subnet_priv_cidr_block[count.index]
  availability_zone = data.aws_availability_zones.defaults.names[(count.index + length(data.aws_availability_zones.defaults.names)) % length(data.aws_availability_zones.defaults.names)]

  tags = {
    Name                              = "${var.prefix}-sub-priv-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = 1
  }
}

### Nat Gateway and IP for Private Subnet(s)
resource "aws_eip" "gitlab_vpc_sn_priv_ng_ip" {
  count = local.create_network ? min(var.subnet_pub_count, var.subnet_priv_count) : 0

  vpc = true
}

resource "aws_nat_gateway" "gitlab_vpc_sn_priv_ng" {
  count = local.create_network ? min(var.subnet_pub_count, var.subnet_priv_count) : 0

  allocation_id = aws_eip.gitlab_vpc_sn_priv_ng_ip[count.index].id
  subnet_id     = aws_subnet.gitlab_vpc_sn_pub[count.index].id

  tags = {
    Name = "${var.prefix}-sub-priv-nat-${count.index}"
  }
}

resource "aws_route_table" "gitlab_vpc_rt_priv" {
  count = local.create_network ? min(var.subnet_pub_count, var.subnet_priv_count) : 0

  vpc_id = aws_vpc.gitlab_vpc[0].id

  route {
    cidr_block     = "0.0.0.0/0" # Internet Access
    nat_gateway_id = aws_nat_gateway.gitlab_vpc_sn_priv_ng[count.index].id
  }

  tags = {
    Name = "${var.prefix}-sub-priv-rt-${count.index}"
  }
}

resource "aws_route_table_association" "gitlab_vpc_rt_priv_rta" {
  count = local.create_network ? min(var.subnet_pub_count, var.subnet_priv_count) : 0

  subnet_id      = aws_subnet.gitlab_vpc_sn_priv[count.index].id
  route_table_id = aws_route_table.gitlab_vpc_rt_priv[count.index].id
}

# Set various params for possible network configs
locals {
  default_vpc_id     = local.default_network ? aws_default_vpc.default[0].id : null
  default_subnet_ids = local.default_network ? data.aws_subnet_ids.defaults[0].ids : null

  vpc_id          = local.create_network ? aws_vpc.gitlab_vpc[0].id : var.vpc_id
  subnet_pub_ids  = local.create_network ? aws_subnet.gitlab_vpc_sn_pub[*].id : var.subnet_pub_ids
  subnet_priv_ids = local.create_network ? aws_subnet.gitlab_vpc_sn_priv[*].id : var.subnet_priv_ids

  # Target Subnets for resource types. Selected dynamically from what's been configured - Private / Public or Default
  backend_subnet_ids  = !local.default_network ? coalescelist(local.subnet_priv_ids, local.subnet_pub_ids) : null
  frontend_subnet_ids = !local.default_network ? coalescelist(local.subnet_pub_ids, local.subnet_priv_ids) : null
  all_subnet_ids      = !local.default_network ? concat(local.subnet_pub_ids != null ? local.subnet_pub_ids : [], local.subnet_priv_ids != null ? local.subnet_priv_ids : []) : null
}

output "vpc_id" {
  value = local.default_network ? local.default_vpc_id : local.vpc_id
}

output "vpc_cidr_block" {
  value = var.vpc_cidr_block
}
