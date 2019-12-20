module "luthername_ec2" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  resource       = "ec2"

  providers = {
    template = "template"
  }
}

resource "aws_instance" "service" {
  count = "1" # TODO

  ami           = "${var.aws_ami}"
  subnet_id     = "${element(var.aws_subnet_ids, count.index)}"
  instance_type = "${var.aws_instance_type}"
  key_name      = "${var.aws_ssh_key_name}"

  ebs_optimized = "${lookup(var.aws_ebs_optimizable_instance_types, var.aws_instance_type, false)}"

  user_data = <<USERDATA
#!/bin/bash
set -x

# Disable root SSH
sed -i 's/^#PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl reload sshd
USERDATA

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "${var.root_volume_size_gb}"
    delete_on_termination = true
  }

  iam_instance_profile   = "${aws_iam_instance_profile.service.name}"
  vpc_security_group_ids = ["${aws_security_group.service.id}"]

  tags = {
    Name         = "${module.luthername_ec2.names[count.index]}"
    Project      = "${module.luthername_ec2.luther_project}"
    Environment  = "${module.luthername_ec2.luther_env}"
    Organization = "${module.luthername_ec2.org_name}"
    Component    = "${module.luthername_ec2.component}"
    Resource     = "${module.luthername_ec2.resource}"
    ID           = "${module.luthername_ec2.ids[count.index]}"
  }

  lifecycle {
    ignore_changes = [
      "ami",
      "key_name",
    ]
  }
}

output "aws_instance_private_ips" {
  value = "${aws_instance.service.*.private_ip}"
}

output "aws_instance_public_ips" {
  value = "${aws_instance.service.*.public_ip}"
}

output "aws_instance_public_dns" {
  value = "${aws_instance.service.*.public_dns}"
}

module "aws_instance_monitoring_actions_service" {
  source                               = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-instance-monitoring-actions.git?ref=v1.0.0"
  replication                          = "1"                                                                                                   # TODO
  aws_region                           = "${var.aws_region}"
  aws_instance_ids                     = ["${aws_instance.service.id}"]
  instance_names                       = "${module.luthername_ec2.names}"
  aws_cloudwatch_alarm_actions_enabled = "${var.aws_cloudwatch_alarm_actions_enabled}"
  aws_autorecovery_sns_arn             = "${var.aws_autorecovery_sns_arn}"
  aws_autorestart_arn                  = "${var.aws_autorestart_arn}"

  providers = {
    template = "template"
  }
}

module "luthername_nsg" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  resource       = "nsg"

  providers = {
    template = "template"
  }
}

resource "aws_security_group" "service" {
  description = "${var.component} security group for ${var.luther_project}-${var.luther_env} (${var.org_name})"

  vpc_id = "${var.aws_vpc_id}"

  tags = {
    Name         = "${module.luthername_nsg.names[count.index]}"
    Project      = "${module.luthername_nsg.luther_project}"
    Environment  = "${module.luthername_nsg.luther_env}"
    Organization = "${module.luthername_nsg.org_name}"
    Component    = "${module.luthername_nsg.component}"
    Resource     = "${module.luthername_nsg.resource}"
    ID           = "${module.luthername_nsg.ids[count.index]}"
  }
}

output "aws_security_group_id" {
  value = "${aws_security_group.service.id}"
}

resource "aws_security_group_rule" "ingress_prometheus_server" {
  type                     = "ingress"
  from_port                = "${var.prometheus_node_exporter_metrics_port}"
  to_port                  = "${var.prometheus_node_exporter_metrics_port}"
  protocol                 = "tcp"
  source_security_group_id = "${var.prometheus_server_security_group_id}"
  security_group_id        = "${aws_security_group.service.id}"
}

resource "aws_security_group_rule" "ingress_prometheus_server_pubkey" {
  type                     = "ingress"
  from_port                = "${var.authorized_key_sync_metrics_port}"
  to_port                  = "${var.authorized_key_sync_metrics_port}"
  protocol                 = "tcp"
  source_security_group_id = "${var.prometheus_server_security_group_id}"
  security_group_id        = "${aws_security_group.service.id}"
}

resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = "${var.ssh_port}"
  to_port           = "${var.ssh_port}"
  protocol          = "tcp"
  cidr_blocks       = ["${var.ssh_whitelist_ingress}"]
  security_group_id = "${aws_security_group.service.id}"
}

resource "aws_iam_instance_profile" "service" {
  role = "${aws_iam_role.service.name}"
}

resource "aws_iam_role" "service" {
  assume_role_policy = "${data.aws_iam_policy_document.ec2_assume_role.json}"
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

module "luthername_policy_logs" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  resource       = "iampolicy"
  subcomponent   = "logs"

  providers = {
    template = "template"
  }
}

resource "aws_iam_role_policy" "cloudwatch_logs" {
  name   = "${module.luthername_policy_logs.names[count.index]}"
  role   = "${aws_iam_role.service.id}"
  policy = "${data.aws_iam_policy_document.cloudwatch_logs.json}"
}

data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    sid = "LutherPutLogs"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

module "luthername_policy_authorized_key_sync" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  resource       = "iampolicy"
  subcomponent   = "pubkey"

  providers = {
    template = "template"
  }
}

resource "aws_iam_role_policy" "authorized_key_sync" {
  name   = "${module.luthername_policy_authorized_key_sync.names[count.index]}"
  role   = "${aws_iam_role.service.id}"
  policy = "${data.aws_iam_policy_document.authorized_key_sync.json}"
}

data "aws_iam_policy_document" "authorized_key_sync" {
  statement {
    sid       = "LutherListAuthorizedKeys"
    actions   = ["s3:ListBucket"]
    resources = ["${var.authorized_key_sync_s3_bucket_arn}"]
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

module "luthername_policy_common_assets" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  resource       = "iampolicy"
  subcomponent   = "commons"

  providers = {
    template = "template"
  }
}

resource "aws_iam_role_policy" "common_assets" {
  name   = "${module.luthername_policy_common_assets.names[count.index]}"
  role   = "${aws_iam_role.service.id}"
  policy = "${data.aws_iam_policy_document.common_assets.json}"
}

data "aws_iam_policy_document" "common_assets" {
  statement {
    actions = [
      "s3:HeadObject",
      "s3:GetObject",
    ]

    resources = ["${var.common_static_asset_s3_bucket_arn}/*"]
  }
}

#module "luthername_policy_project_assets" {
#    source = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
#    luther_project = "${var.luther_project}"
#    aws_region = "${var.aws_region}"
#    luther_env = "${var.luther_env}"
#    org_name = "${var.org_name}"
#    component = "${var.component}"
#    resource = "iampolicy"
#    subcomponent = "project"
#}
#
#resource "aws_iam_role_policy" "project_assets" {
#    name = "${module.luthername_policy_project_assets.names[count.index]}"
#    role = "${aws_iam_role.service.id}"
#    policy = "${data.aws_iam_policy_document.project_assets.json}"
#}
#
#data "aws_iam_policy_document" "project_assets" {
#    statement {
#        actions = [
#            "s3:HeadObject",
#            "s3:GetObject",
#        ]
#        resources = ["${var.project_static_asset_s3_bucket_arn}/*"]
#    }
#}

module "luthername_policy_decrypt" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  resource       = "iampolicy"
  subcomponent   = "decrypt"

  providers = {
    template = "template"
  }
}

resource "aws_iam_role_policy" "decrypt" {
  name   = "${module.luthername_policy_decrypt.names[count.index]}"
  role   = "${aws_iam_role.service.id}"
  policy = "${data.aws_iam_policy_document.decrypt_assets.json}"
}

data "aws_iam_policy_document" "decrypt_assets" {
  statement {
    sid       = "DecryptAssets"
    actions   = ["kms:Decrypt"]
    resources = ["${var.aws_kms_key_arns}"]
  }
}

# Allow the bastion to ssh to itself as ansible requires this functionality to
# provision the bastion instance(s) in case the ssh whitelist prevents it.
resource "aws_security_group_rule" "ingress_bastion" {
  type                     = "ingress"
  from_port                = "${var.ssh_port}"
  to_port                  = "${var.ssh_port}"
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.service.id}"
  security_group_id        = "${aws_security_group.service.id}"
}
