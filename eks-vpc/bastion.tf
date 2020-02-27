data "aws_route53_zone" "external" {
  name = "${var.domain}."
}

data "template_file" "fqdn_bastion" {
  # example: ics-de-dev-es.luthersystemsapp.com
  template = "$${project}-$${region_code}-$${env}$${org_part}.$${domain}"

  vars {
    project     = "${var.luther_project}"
    region_code = "${var.aws_region_short_code[var.aws_region]}"
    org_part    = "${var.org_name == "" ? "" : "-"}${var.org_name}"
    env         = "${var.luther_env}"
    domain      = "${var.domain}"
  }
}

# The common name of the bastion host.  Outputs the name from the route53
# resource to avoid race conditions with module importers trying to use
# bastion_dns_name for ssh provisioning.  Though it's better to use
# bastion_provisioning_dns_name for ssh provisioning on the bastion.
output "bastion_dns_name" {
  value = "${aws_route53_record.bastion.name}"
}

# A better dns name to use for ssh provisioning on the bastion because it can
# trigger reprovisioning if the bastion is replaced for any reason.
output "bastion_provisioning_dns_name" {
  value = "${module.aws_bastion.aws_instance_public_dns[0]}"
}

resource "aws_route53_record" "bastion" {
  zone_id = "${data.aws_route53_zone.external.zone_id}"
  name    = "${data.template_file.fqdn_bastion.rendered}"
  type    = "CNAME"
  ttl     = 300
  records = ["${module.aws_bastion.aws_instance_public_dns[0]}"]
}

locals {
  aws_autorecovery_arn = "arn:aws:automate:${var.aws_region}:ec2:recover"
  aws_autorestart_arn  = "arn:aws:swf:${var.aws_region}:${var.aws_account_id}:action/actions/AWS_EC2.InstanceId.Reboot/1.0"
}

module "aws_bastion" {
  source = "../aws-bastion"

  luther_project                       = "${var.luther_project}"
  aws_region                           = "${var.aws_region}"
  luther_env                           = "${var.luther_env}"
  org_name                             = "${var.org_name}"
  aws_instance_type                    = "${var.bastion_aws_instance_type}"
  aws_ami                              = "${var.bastion_ami}"
  aws_vpc_id                           = "${aws_vpc.main.id}"
  aws_subnet_ids                       = ["${aws_subnet.net.*.id}"]
  aws_availability_zones               = ["${data.template_file.availability_zones.*.rendered}"]
  aws_ssh_key_name                     = "${var.aws_ssh_key_name}"
  ssh_whitelist_ingress                = ["0.0.0.0/0"]
  prometheus_server_security_group_id  = "${aws_security_group.monitoring_temp.id}"
  authorized_key_sync_s3_bucket_arn    = "${var.ssh_public_keys_s3_bucket_arn}"
  common_static_asset_s3_bucket_arn    = "${var.common_static_s3_bucket_arn}"
  aws_kms_key_arns                     = ["${var.aws_kms_key_arns}"]
  aws_cloudwatch_alarm_actions_enabled = "${var.aws_cloudwatch_alarm_actions_enabled}"
  aws_autorecovery_sns_arn             = "${var.aws_autorecovery_sns_arn}"
  aws_autorecovery_arn                 = "${local.aws_autorecovery_arn}"
  aws_autorestart_arn                  = "${local.aws_autorestart_arn}"
  ssh_port                             = "${var.bastion_ssh_port}"
  providers {
    aws      = "aws"
    template = "template"
  }
}

# null_resource.bastion_k8s_provisioning uploads k8s resource definitions to
# ec2 so that they may be loaded into eks from inside the VPC (no need for a
# tunnel).  Ansible playbooks are responsible for applying and destroying the
# k8s resources defined by the uploaded files.
resource "null_resource" "bastion_k8s_provisioning" {
  triggers = {
    bastion_host    = "${module.aws_bastion.aws_instance_public_dns[0]}"
    k8s_local_facts = "${local.k8s_local_facts}"
  }

  connection {
    host = "${module.aws_bastion.aws_instance_public_dns[0]}"
    type = "ssh"
    user = "ubuntu"
    port = "${var.bastion_ssh_port}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/ansible/facts.d",
      "${local.k8s_local_facts}",
    ]
  }
}

locals {
  k8s_local_facts = <<LOCAL
sudo tee /etc/ansible/facts.d/k8s.fact <<FACT
{
    "k8s_cluster_aws_region": ${jsonencode(var.aws_region)},
    "k8s_cluster_name": ${jsonencode(aws_eks_cluster.app.name)},
    "k8s_cluster_endpoint": ${jsonencode(aws_eks_cluster.app.endpoint)},
    "k8s_cluster_version": ${jsonencode(aws_eks_cluster.app.version)},
    "k8s_cluster_auth_config_map": ${jsonencode(local.config_map_aws_auth)},
    "k8s_cluster_storageclass": ${jsonencode(local.storageclass_gp2_encrypted)},
    "k8s_cluster_storageclass_gp2_encrypted": ${jsonencode(local.storageclass_gp2_encrypted)},
    "k8s_cluster_storageclass_gp2": ${jsonencode(local.storageclass_gp2)}
}
FACT
LOCAL
}

resource "aws_security_group_rule" "bastion_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${module.aws_bastion.aws_security_group_id}"
}

module "luthername_nsg_monitoring_temp" {
  source         = "../luthername"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "mon"
  resource       = "nsg"
  subcomponent   = "temp"

  providers {
    template = "template"
  }
}

# This resource is a placeholder for the monitoring security group.
resource "aws_security_group" "monitoring_temp" {
  name   = "${module.luthername_nsg_monitoring_temp.names[0]}"
  vpc_id = "${aws_vpc.main.id}"
}
