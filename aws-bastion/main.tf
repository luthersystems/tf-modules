module "luthername_ec2" {
  source         = "../luthername"
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

locals {
  inspector_gpg_key = <<GPGKEY
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2.0.18 (GNU/Linux)

mQINBFYDlfEBEADFpfNt/mdCtsmfDoga+PfHY9bdXAD68yhp2m9NyH3BOzle/MXI
8siNfoRgzDwuWnIaezHwwLWkDw2paRxp1NMQ9qRe8Phq0ewheLrQu95dwDgMcw90
gf9m1iKVHjdVQ9qNHlB2OFknPDxMDRHcrmlJYDKYCX3+MODEHnlK25tIH2KWezXP
FPSU+TkwjLRzSMYH1L8IwjFUIIi78jQS9a31R/cOl4zuC5fOVghYlSomLI8irfoD
JSa3csVRujSmOAf9o3beiMR/kNDMpgDOxgiQTu/Kh39cl6o8AKe+QKK48kqO7hra
h1dpzLbfeZEVU6dWMZtlUksG/zKxuzD6d8vXYH7Z+x09POPFALQCQQMC3WisIKgj
zJEFhXMCCQ3NLC3CeyMq3vP7MbVRBYE7t3d2uDREkZBgIf+mbUYfYPhrzy0qT9Tr
PgwcnUvDZuazxuuPzucZGOJ5kbptat3DcUpstjdkMGAId3JawBbps77qRZdA+swr
o9o3jbowgmf0y5ZS6KwvZnC6XyTAkXy2io7mSrAIRECrANrzYzfp5v7uD7w8Dk0X
1OrfOm1VufMzAyTu0YQGBWaQKzSB8tCkvFw54PrRuUTcV826XU7SIJNzmNQo58uL
bKyLVBSCVabfs0lkECIesq8PT9xMYfQJ421uATHyYUnFTU2TYrCQEab7oQARAQAB
tCdBbWF6b24gSW5zcGVjdG9yIDxpbnNwZWN0b3JAYW1hem9uLmNvbT6JAjgEEwEC
ACIFAlYDlfECGwMGCwkIBwMCBhUIAgkKCwQWAgMBAh4BAheAAAoJECR0CWBYNgQY
8yUP/2GpIl40f3mKBUiSTe0XQLvwiBCHmY+V9fOuKqDTinxssjEMCnz0vsKeCZF/
L35pwNa/oW0OJa8D7sCkKG+8LuyMpcPDyqptLrYPprUWtz2+qLCHgpWsrku7ateF
x4hWS0jUVeHPaBzI9V1NTHsCx9+nbpWQ5Fk+7VJI8hbMDY7NQx6fcse8WTlP/0r/
HIkKzzqQQaaOf5t9zc5DKwi+dFmJbRUyaq22xs8C81UODjHunhjHdZ21cnsgk91S
fviuaum9aR4/uVIYOTVWnjC5J3+VlczyUt5FaYrrQ5ov0dM+biTUXwve3X8Q85Nu
DPnO/+zxb7Jz3QCHXnuTbxZTjvvl60Oi8//uRTnPXjz4wZLwQfibgHmk1++hzND7
wOYA02Js6v5FZQlLQAod7q2wuA1pq4MroLXzziDfy/9ea8B+tzyxlmNVRpVZY4Ll
DOHyqGQhpkyV3drjjNZlEofwbfu7m6ODwsgMl5ynzhKklJzwPJFfB3mMc7qLi+qX
MJtEX8KJ/iVUQStHHAG7daL1bxpWSI3BRuaHsWbBGQ/mcHBgUUOQJyEp5LAdg9Fs
VP55gWtF7pIqifiqlcfgG0Ov+A3NmVbmiGKSZvfrc5KsF/k43rCGqDx1RV6gZvyI
LfO9+3sEIlNrsMib0KRLDeBt3EuDsaBZgOkqjDhgJUesqiCy
=iEhB
-----END PGP PUBLIC KEY BLOCK-----
GPGKEY
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
set -euxo pipefail

# Disable root SSH
sed -i 's/^#PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl reload sshd

# Install Amazon Inspector Agent
curl -o install-inspector.sh https://inspector-agent.amazonaws.com/linux/latest/install
curl -o install-inspector.sh.sig https://d1wk0tztpsntt1.cloudfront.net/linux/latest/install.sig
echo '${base64encode(local.inspector_gpg_key)}' | base64 -d | gpg --import
gpg --verify ./install-inspector.sh.sig
bash install-inspector.sh
rm -f install-inspector.sh
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
  source                               = "../aws-instance-monitoring-actions"
  replication                          = "1"
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
  source         = "../luthername"
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
  source         = "../luthername"
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
  source         = "../luthername"
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
  source         = "../luthername"
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
#    source = "../luthername"
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
  source         = "../luthername"
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
