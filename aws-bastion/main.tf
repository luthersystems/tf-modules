module "luthername_ec2" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = var.component
  resource       = "ec2"
}

locals {
  syslog_timestamp_format = "%b %d %H:%M:%S"
}

module "common_userdata" {
  source = "../aws-instance-userdata"

  aws_region           = var.aws_region
  cloudwatch_log_group = var.cloudwatch_log_group
  distro               = "ubuntu"
  log_namespace        = "bastion"
  run_as_user          = "cwagent"

  timestamped_log_files = [
    {
      path             = "/var/log/auth.log",
      timestamp_format = local.syslog_timestamp_format,
    },
    {
      path             = "/var/log/syslog",
      timestamp_format = local.syslog_timestamp_format,
    },
    {
      path             = "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",
      timestamp_format = "%Y-%m-%dT%H:%M:%S",
    },
    {
      path             = "/var/log/cloud-init.log",
      timestamp_format = "%Y-%m-%d %H:%M:%S",
    },
  ]

  log_files = [
    "/var/log/cloud-init-output.log",
  ]
}

locals {
  user_data_vars = {
    common_userdata = module.common_userdata.user_data
  }
  user_data = templatefile("${path.module}/files/userdata.sh.tmpl", local.user_data_vars)
}

resource "aws_instance" "service" {
  count = "1" # TODO

  ami              = var.aws_ami
  subnet_id        = element(var.aws_subnet_ids, count.index)
  instance_type    = var.aws_instance_type
  key_name         = var.aws_ssh_key_name
  user_data_base64 = base64gzip(local.user_data)

  ebs_optimized = lookup(
    var.aws_ebs_optimizable_instance_types,
    var.aws_instance_type,
    false,
  )

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_volume_size_gb
    delete_on_termination = true
  }

  iam_instance_profile   = aws_iam_instance_profile.service.name
  vpc_security_group_ids = [aws_security_group.service.id]

  tags = {
    Name         = module.luthername_ec2.names[count.index]
    Project      = module.luthername_ec2.luther_project
    Environment  = module.luthername_ec2.luther_env
    Organization = module.luthername_ec2.org_name
    Component    = module.luthername_ec2.component
    Resource     = module.luthername_ec2.resource
    ID           = module.luthername_ec2.ids[count.index]
  }

  lifecycle {
    ignore_changes = [
      ami,
      key_name,
      user_data,
      user_data_base64,
    ]
  }
}

output "name" {
  value = module.luthername_ec2.name
}

output "names" {
  value = module.luthername_ec2.names
}

output "aws_instance_private_ips" {
  value = aws_instance.service.*.private_ip
}

output "aws_instance_public_ips" {
  value = aws_instance.service.*.public_ip
}

output "aws_instance_public_dns" {
  value = aws_instance.service.*.public_dns
}

module "aws_instance_monitoring_actions_service" {
  source                               = "../aws-instance-monitoring-actions"
  aws_region                           = var.aws_region
  aws_instance_ids                     = [aws_instance.service[0].id]
  instance_names                       = module.luthername_ec2.names
  aws_cloudwatch_alarm_actions_enabled = var.aws_cloudwatch_alarm_actions_enabled
  aws_autorecovery_sns_arn             = var.aws_autorecovery_sns_arn
  aws_autorestart_arn                  = var.aws_autorestart_arn

  providers = {
    aws = aws
  }
}

module "luthername_nsg" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = var.component
  resource       = "nsg"
}

resource "aws_security_group" "service" {
  description = "${var.component} security group for ${var.luther_project}-${var.luther_env} (${var.org_name})"

  vpc_id = var.aws_vpc_id

  tags = {
    Name         = module.luthername_nsg.name
    Project      = module.luthername_nsg.luther_project
    Environment  = module.luthername_nsg.luther_env
    Organization = module.luthername_nsg.org_name
    Component    = module.luthername_nsg.component
    Resource     = module.luthername_nsg.resource
    ID           = module.luthername_nsg.id
  }
}

output "aws_security_group_id" {
  value = aws_security_group.service.id
}

resource "aws_security_group_rule" "ingress_prometheus_server" {
  type                     = "ingress"
  from_port                = var.prometheus_node_exporter_metrics_port
  to_port                  = var.prometheus_node_exporter_metrics_port
  protocol                 = "tcp"
  source_security_group_id = var.prometheus_server_security_group_id
  security_group_id        = aws_security_group.service.id
}

resource "aws_security_group_rule" "ingress_prometheus_server_pubkey" {
  type                     = "ingress"
  from_port                = var.authorized_key_sync_metrics_port
  to_port                  = var.authorized_key_sync_metrics_port
  protocol                 = "tcp"
  source_security_group_id = var.prometheus_server_security_group_id
  security_group_id        = aws_security_group.service.id
}

resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = var.ssh_port
  to_port           = var.ssh_port
  protocol          = "tcp"
  cidr_blocks       = var.ssh_whitelist_ingress
  security_group_id = aws_security_group.service.id
}

module "luthername_instance_profile" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = var.component
  resource       = "profile"
}

resource "aws_iam_instance_profile" "service" {
  name = module.luthername_instance_profile.name
  role = aws_iam_role.service.name
}

module "luthername_instance_role" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = var.component
  resource       = "role"
}

resource "aws_iam_role" "service" {
  name               = module.luthername_instance_role.name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "LutherEC2AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "cloudwatch_logs" {
  name   = "cloudwatch-logs"
  role   = aws_iam_role.service.id
  policy = data.aws_iam_policy_document.cloudwatch_logs.json
}

data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]

    resources = [var.cloudwatch_log_group_arn]
  }
}

resource "aws_iam_role_policy" "authorized_key_sync" {
  name   = "authorized-key-sync"
  role   = aws_iam_role.service.id
  policy = data.aws_iam_policy_document.authorized_key_sync.json
}

data "aws_iam_policy_document" "authorized_key_sync" {
  statement {
    sid       = "LutherListAuthorizedKeys"
    actions   = ["s3:ListBucket"]
    resources = [var.authorized_key_sync_s3_bucket_arn]
  }

  statement {
    sid = "LutherGetAuthorizedKeys"

    actions = [
      "s3:HeadObject",
      "s3:GetObject",
    ]

    resources = ["${var.authorized_key_sync_s3_bucket_arn}${var.authorized_key_sync_s3_key_prefix}*"]
  }
}

resource "aws_iam_role_policy" "common_assets" {
  name   = "common-assets"
  role   = aws_iam_role.service.id
  policy = data.aws_iam_policy_document.common_assets.json
}

data "aws_iam_policy_document" "common_assets" {
  statement {
    actions = [
      "s3:HeadObject",
      "s3:GetObject",
    ]

    resources = ["${var.common_static_asset_s3_bucket_arn}/*"]
  }

  statement {
    sid     = "DecryptAssets"
    actions = ["kms:Decrypt"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      # TODO look up this region to support a common bucket in an alternate
      # region
      values = ["s3.eu-west-2.amazonaws.com"]
    }

    resources = var.aws_kms_key_arns
  }
}

# Allow the bastion to ssh to itself as ansible requires this functionality to
# provision the bastion instance(s) in case the ssh whitelist prevents it.
resource "aws_security_group_rule" "ingress_bastion" {
  type                     = "ingress"
  from_port                = var.ssh_port
  to_port                  = var.ssh_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.service.id
  security_group_id        = aws_security_group.service.id
}
