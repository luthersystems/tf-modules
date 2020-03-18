data "aws_iam_policy_document" "transfer_assume_role" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

module "luthername_transfer_server_role" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "sftp"
  resource       = "role"
}

resource "aws_iam_role" "transfer_server" {
  name               = module.luthername_transfer_server_role.names[0]
  assume_role_policy = data.aws_iam_policy_document.transfer_assume_role.json

  tags = {
    Name         = module.luthername_transfer_server_role.names[0]
    Project      = module.luthername_transfer_server_role.luther_project
    Environment  = module.luthername_transfer_server_role.luther_env
    Organization = module.luthername_transfer_server_role.org_name
    Component    = module.luthername_transfer_server_role.component
    Resource     = module.luthername_transfer_server_role.resource
    ID           = module.luthername_transfer_server_role.ids[0]
  }
}

data "aws_iam_policy_document" "transfer_server" {
  statement {
    sid       = "InvokeAuthAPI"
    actions   = ["execute-api:Invoke"]
    resources = ["${aws_api_gateway_stage.transfer_auth.execution_arn}/GET/*"]
  }

  statement {
    sid       = "GetAuthAPI"
    actions   = ["apigateway:GET"]
    resources = [aws_api_gateway_rest_api.transfer_auth.execution_arn]
  }
}

resource "aws_iam_role_policy" "transfer_server" {
  name   = "transfer-server"
  role   = aws_iam_role.transfer_server.id
  policy = data.aws_iam_policy_document.transfer_server.json
}

module "luthername_transfer_server_logging_role" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "sftp"
  resource       = "role"
  subcomponent   = "logging"
}

resource "aws_iam_role" "transfer_server_logging" {
  name               = module.luthername_transfer_server_logging_role.names[0]
  assume_role_policy = data.aws_iam_policy_document.transfer_assume_role.json

  tags = {
    Name         = module.luthername_transfer_server_logging_role.names[0]
    Project      = module.luthername_transfer_server_logging_role.luther_project
    Environment  = module.luthername_transfer_server_logging_role.luther_env
    Organization = module.luthername_transfer_server_logging_role.org_name
    Component    = module.luthername_transfer_server_logging_role.component
    Subcomponent = module.luthername_transfer_server_logging_role.subcomponent
    Resource     = module.luthername_transfer_server_logging_role.resource
    ID           = module.luthername_transfer_server_logging_role.ids[0]
  }
}

data "aws_iam_policy_document" "transfer_server_logging" {
  statement {
    sid = "AllowLogging"

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "transfer_server_logging" {
  name   = "transfer-server-logging"
  role   = aws_iam_role.transfer_server_logging.id
  policy = data.aws_iam_policy_document.transfer_server_logging.json
}

module "luthername_transfer_server" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "sftp"
  resource       = "ts"
}

module "luthername_vpc" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "sftp"
  resource       = "vpc"
}

resource "aws_vpc" "sftp" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Name"        = module.luthername_vpc.names[0]
    "Project"     = module.luthername_vpc.luther_project
    "Environment" = module.luthername_vpc.luther_env
    "Component"   = module.luthername_vpc.component
    "Resource"    = module.luthername_vpc.resource
    "ID"          = module.luthername_vpc.ids[0]
  }
}

module "luthername_ig" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "sftp"
  resource       = "ig"
}

resource "aws_internet_gateway" "sftp" {
  vpc_id = aws_vpc.sftp.id

  tags = {
    Name         = module.luthername_ig.names[0]
    Project      = module.luthername_ig.luther_project
    Environment  = module.luthername_ig.luther_env
    Organization = module.luthername_ig.org_name
    Component    = module.luthername_ig.component
    Resource     = module.luthername_ig.resource
    ID           = module.luthername_ig.ids[0]
  }
}

module "luthername_rt" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "sftp"
  resource       = "rt"
}

resource "aws_route_table" "sftp" {
  vpc_id = aws_vpc.sftp.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sftp.id
  }

  tags = {
    Name         = module.luthername_rt.names[0]
    Project      = module.luthername_rt.luther_project
    Environment  = module.luthername_rt.luther_env
    Organization = module.luthername_rt.org_name
    Component    = module.luthername_rt.component
    Resource     = module.luthername_rt.resource
    ID           = module.luthername_rt.ids[0]
  }
}

resource "aws_route_table_association" "sftp" {
  count          = length(local.region_availability_zones)
  subnet_id      = element(aws_subnet.sftp.*.id, count.index)
  route_table_id = aws_route_table.sftp.id
}

module "luthername_sn" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "sftp"
  resource       = "sn"
  replication    = length(local.region_availability_zones)
}

resource "aws_subnet" "sftp" {
  count      = length(local.region_availability_zones)
  vpc_id     = aws_vpc.sftp.id
  cidr_block = cidrsubnet("10.0.0.0/16", 8, count.index + 1)
  availability_zone = element(
    local.region_availability_zones,
    count.index,
  )

  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.sftp]

  tags = {
    "Name"         = module.luthername_sn.names[count.index]
    "Project"      = module.luthername_sn.luther_project
    "Environment"  = module.luthername_sn.luther_env
    "Organization" = module.luthername_sn.org_name
    "Component"    = module.luthername_sn.component
    "Resource"     = module.luthername_sn.resource
    "ID"           = module.luthername_sn.ids[count.index]
  }
}

module "luthername_eip" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "sftp"
  resource       = "eip"
  replication    = length(local.region_availability_zones)
}

resource "aws_eip" "sftp" {
  count = length(local.region_availability_zones)
  vpc   = true

  depends_on = [aws_internet_gateway.sftp]

  tags = {
    "Name"         = module.luthername_eip.names[count.index]
    "Project"      = module.luthername_eip.luther_project
    "Environment"  = module.luthername_eip.luther_env
    "Organization" = module.luthername_eip.org_name
    "Component"    = module.luthername_eip.component
    "Resource"     = module.luthername_eip.resource
    "ID"           = module.luthername_eip.ids[count.index]
  }
}

module "luthername_lb" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "sftp"
  resource       = "lb"
}

resource "aws_lb" "sftp" {
  name               = module.luthername_lb.names[0]
  internal           = false
  load_balancer_type = "network"

  enable_cross_zone_load_balancing = true

  subnet_mapping {
    subnet_id     = element(aws_subnet.sftp.*.id, 0)
    allocation_id = element(aws_eip.sftp.*.id, 0)
  }

  subnet_mapping {
    subnet_id     = element(aws_subnet.sftp.*.id, 1)
    allocation_id = element(aws_eip.sftp.*.id, 1)
  }

  subnet_mapping {
    subnet_id     = element(aws_subnet.sftp.*.id, 2)
    allocation_id = element(aws_eip.sftp.*.id, 2)
  }

  tags = {
    Name         = module.luthername_lb.names[0]
    Project      = module.luthername_lb.luther_project
    Environment  = module.luthername_lb.luther_env
    Organization = module.luthername_lb.org_name
    Component    = module.luthername_lb.component
    Resource     = module.luthername_lb.resource
    ID           = module.luthername_lb.ids[0]
  }
}

module "luthername_tg" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "sftp"
  resource       = "tg"
}

resource "aws_lb_target_group" "sftp" {
  name        = module.luthername_tg.names[0]
  port        = "22"
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.sftp.id

  tags = {
    Name         = module.luthername_tg.names[0]
    Project      = module.luthername_tg.luther_project
    Environment  = module.luthername_tg.luther_env
    Organization = module.luthername_tg.org_name
    Component    = module.luthername_tg.component
    Resource     = module.luthername_tg.resource
    ID           = module.luthername_tg.ids[0]
  }
}

resource "aws_lb_target_group_attachment" "sftp" {
  count            = length(local.region_availability_zones)
  target_group_arn = aws_lb_target_group.sftp.arn
  target_id        = element(data.aws_network_interface.sftp.*.private_ip, count.index)
  port             = 22
}

data "aws_network_interface" "sftp" {
  count = length(local.region_availability_zones)
  id    = element(tolist(aws_vpc_endpoint.sftp.network_interface_ids), count.index)
}

resource "aws_lb_listener" "sftp" {
  load_balancer_arn = aws_lb.sftp.arn
  port              = "22"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sftp.arn
  }
}

module "luthername_nsg" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "sftp"
  resource       = "nsg"
}

resource "aws_security_group" "sftp" {
  description = "sftp security group for ${var.luther_project}-${var.luther_env} (${var.org_name})"
  name        = module.luthername_nsg.names[0]
  vpc_id      = aws_vpc.sftp.id

  tags = {
    Name         = module.luthername_nsg.names[0]
    Project      = module.luthername_nsg.luther_project
    Environment  = module.luthername_nsg.luther_env
    Organization = module.luthername_nsg.org_name
    Component    = module.luthername_nsg.component
    Resource     = module.luthername_nsg.resource
    ID           = module.luthername_nsg.ids[0]
  }
}

resource "aws_security_group_rule" "ingress_sftp" {
  type      = "ingress"
  from_port = "22"
  to_port   = "22"
  protocol  = "tcp"

  # allow internal healthcheck
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.sftp.id
  description       = "Allow external access to SFTP"
}

module "luthername_ve" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "sftp"
  resource       = "ve"
}

locals {
  sftp_vpc_service_name = "com.amazonaws.${var.aws_region}.transfer.server"
}

resource "aws_vpc_endpoint" "sftp" {
  vpc_id            = aws_vpc.sftp.id
  service_name      = local.sftp_vpc_service_name
  vpc_endpoint_type = "Interface"
  auto_accept       = true

  security_group_ids = [
    aws_security_group.sftp.id,
  ]

  private_dns_enabled = true

  subnet_ids = aws_subnet.sftp.*.id

  tags = {
    Name         = module.luthername_ve.names[0]
    Project      = module.luthername_ve.luther_project
    Environment  = module.luthername_ve.luther_env
    Organization = module.luthername_ve.org_name
    Component    = module.luthername_ve.component
    Resource     = module.luthername_ve.resource
    ID           = module.luthername_ve.ids[0]
  }
}

module "luthername_na" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "sftp"
  resource       = "nacl"
}

resource "aws_network_acl" "sftp" {
  vpc_id = aws_vpc.sftp.id

  subnet_ids = aws_subnet.sftp.*.id

  tags = {
    Name         = module.luthername_na.names[0]
    Project      = module.luthername_na.luther_project
    Environment  = module.luthername_na.luther_env
    Organization = module.luthername_na.org_name
    Component    = module.luthername_na.component
    Resource     = module.luthername_na.resource
    ID           = module.luthername_na.ids[0]
  }
}

resource "aws_network_acl_rule" "ingress_sftp" {
  count          = length(var.sftp_whitelist_ingress)
  network_acl_id = aws_network_acl.sftp.id
  rule_number    = count.index + 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = element(var.sftp_whitelist_ingress, count.index)
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "egress_sftp" {
  network_acl_id = aws_network_acl.sftp.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_transfer_server" "sftp" {
  identity_provider_type = "API_GATEWAY"
  url                    = aws_api_gateway_stage.transfer_auth.invoke_url
  invocation_role        = aws_iam_role.transfer_server.arn
  logging_role           = aws_iam_role.transfer_server_logging.arn
  endpoint_type          = "VPC_ENDPOINT"

  endpoint_details {
    vpc_endpoint_id = aws_vpc_endpoint.sftp.id
  }

  tags = {
    Name         = module.luthername_transfer_server.names[0]
    Project      = module.luthername_transfer_server.luther_project
    Environment  = module.luthername_transfer_server.luther_env
    Organization = module.luthername_transfer_server.org_name
    Component    = module.luthername_transfer_server.component
    Resource     = module.luthername_transfer_server.resource
    ID           = module.luthername_transfer_server.ids[0]
  }
}

output "transfer_server_public_dns" {
  value = aws_lb.sftp.dns_name
}
