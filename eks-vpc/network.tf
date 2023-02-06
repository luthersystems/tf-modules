module "luthername_vpc" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = var.component
  resource       = "vpc"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Name"                                                            = module.luthername_vpc.names[0]
    "Project"                                                         = module.luthername_vpc.luther_project
    "Environment"                                                     = module.luthername_vpc.luther_env
    "Component"                                                       = module.luthername_vpc.component
    "Resource"                                                        = module.luthername_vpc.resource
    "ID"                                                              = module.luthername_vpc.ids[0]
    "kubernetes.io/cluster/${module.luthername_eks_cluster.names[0]}" = "shared"
  }
}

output "main_vpc_id" {
  value = aws_vpc.main.id
}

module "luthername_net" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "project"
  resource       = "net"
  replication    = length(local.region_availability_zones)
}

# ip addresses in block 10.0.0.0/18 belong to third-party resources used by
# both org1 and org2.
resource "aws_subnet" "net" {
  count      = length(local.region_availability_zones)
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet("10.0.0.0/16", 8, count.index + 1)
  availability_zone = element(
    local.region_availability_zones,
    count.index,
  )

  # Setting to false requires ansible to provision machines from inside the
  # VPC (running inside or through a proxy).
  map_public_ip_on_launch = var.public_worker_ip

  tags = {
    "Name"                                                            = module.luthername_net.names[count.index]
    "Project"                                                         = module.luthername_net.luther_project
    "Environment"                                                     = module.luthername_net.luther_env
    "Organization"                                                    = module.luthername_net.org_name
    "Component"                                                       = module.luthername_net.component
    "Resource"                                                        = module.luthername_net.resource
    "ID"                                                              = module.luthername_net.ids[count.index]
    "kubernetes.io/cluster/${module.luthername_eks_cluster.names[0]}" = "shared"
    "kubernetes.io/role/elb"                                          = "1"
  }
}

output "net_subnet_ids" {
  value = aws_subnet.net.*.id
}

# ip addresses in block 10.0.0.0/18 belong to third-party resources used by
# both org1 and org2.
resource "aws_subnet" "net_private" {
  count  = length(local.region_availability_zones)
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(
    "10.0.0.0/16",
    8,
    count.index + 1 + length(local.region_availability_zones),
  )
  availability_zone = element(
    local.region_availability_zones,
    count.index,
  )

  # NOTE:  These subnets are not directly rearchable from the internet. They are
  # used to launch private loadbalancers in k8s.

  tags = {
    "Name"                                                            = module.luthername_net.names[count.index]
    "Project"                                                         = module.luthername_net.luther_project
    "Environment"                                                     = module.luthername_net.luther_env
    "Organization"                                                    = module.luthername_net.org_name
    "Component"                                                       = module.luthername_net.component
    "Resource"                                                        = module.luthername_net.resource
    "ID"                                                              = module.luthername_net.ids[count.index]
    "kubernetes.io/cluster/${module.luthername_eks_cluster.names[0]}" = "shared"
    "kubernetes.io/role/internal-elb"                                 = "1"
  }
}

module "luthername_igw" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "project"
  resource       = "igw"
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name         = module.luthername_igw.names[0]
    Project      = module.luthername_igw.luther_project
    Environment  = module.luthername_igw.luther_env
    Organization = module.luthername_igw.org_name
    Component    = module.luthername_igw.component
    Resource     = module.luthername_igw.resource
    ID           = module.luthername_igw.ids[0]
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
}

output "route_table_id" {
  value = aws_route_table.main.id
}

resource "aws_route" "main_igw" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "main_igw" {
  count          = length(local.region_availability_zones)
  subnet_id      = aws_subnet.net[count.index].id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "net_private_main_igw" {
  count          = length(local.region_availability_zones)
  subnet_id      = aws_subnet.net_private[count.index].id
  route_table_id = aws_route_table.main.id
}
