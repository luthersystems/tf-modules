data "aws_route53_zone" "external" {
  name = "${var.domain}."
}

data "template_file" "fqdn_bastion" {
  # example: ics-de-dev-es.luthersystemsapp.com
  template = "$${project}-$${region_code}-$${env}$${org_part}.$${domain}"

  vars = {
    project     = var.luther_project
    region_code = var.aws_region_short_code[var.aws_region]
    org_part    = "${var.org_name == "" ? "" : "-"}${var.org_name}"
    env         = var.luther_env
    domain      = var.domain
  }
}

# The common name of the bastion host.  Outputs the name from the route53
# resource to avoid race conditions with module importers trying to use
# bastion_dns_name for ssh provisioning.  Though it's better to use
# bastion_provisioning_dns_name for ssh provisioning on the bastion.
output "bastion_dns_name" {
  value = aws_route53_record.bastion.name
}

# A better dns name to use for ssh provisioning on the bastion because it can
# trigger reprovisioning if the bastion is replaced for any reason.
output "bastion_provisioning_dns_name" {
  value = module.aws_bastion.aws_instance_public_dns[0]
}

resource "aws_route53_record" "bastion" {
  zone_id = data.aws_route53_zone.external.zone_id
  name    = data.template_file.fqdn_bastion.rendered
  type    = "CNAME"
  ttl     = 300
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  records = [module.aws_bastion.aws_instance_public_dns[0]]
}

module "aws_bastion" {
  source = "../aws-bastion"

  luther_project                       = var.luther_project
  aws_region                           = var.aws_region
  luther_env                           = var.luther_env
  org_name                             = var.org_name
  aws_instance_type                    = var.bastion_aws_instance_type
  aws_ami                              = var.bastion_ami
  aws_vpc_id                           = aws_vpc.main.id
  aws_subnet_ids                       = aws_subnet.net.*.id
  aws_ssh_key_name                     = var.aws_ssh_key_name
  ssh_whitelist_ingress                = ["0.0.0.0/0"]
  prometheus_server_security_group_id  = aws_security_group.monitoring_temp.id
  authorized_key_sync_s3_bucket_arn    = var.ssh_public_keys_s3_bucket_arn
  common_static_asset_s3_bucket_arn    = var.common_static_s3_bucket_arn
  aws_kms_key_arns                     = var.aws_kms_key_arns
  aws_cloudwatch_alarm_actions_enabled = var.aws_cloudwatch_alarm_actions_enabled
  aws_autorecovery_sns_arn             = var.aws_autorecovery_sns_arn
  ssh_port                             = var.bastion_ssh_port
  cloudwatch_log_group                 = aws_cloudwatch_log_group.main.name
  cloudwatch_log_group_arn             = aws_cloudwatch_log_group.main.arn

  providers = {
    aws = aws
  }
}

# null_resource.bastion_k8s_provisioning uploads k8s resource definitions to
# ec2 so that they may be loaded into eks from inside the VPC (no need for a
# tunnel).  Ansible playbooks are responsible for applying and destroying the
# k8s resources defined by the uploaded files.
resource "null_resource" "bastion_k8s_provisioning" {
  triggers = {
    bastion_host      = module.aws_bastion.aws_instance_public_dns[0]
    k8s_facts         = local.k8s_facts_json
    externaldns_facts = local.externaldns_facts_json
  }

  connection {
    host = module.aws_bastion.aws_instance_public_dns[0]
    type = "ssh"
    user = "ubuntu"
    port = var.bastion_ssh_port
  }

  provisioner "file" {
    content     = local.k8s_facts_json
    destination = "/home/ubuntu/k8s.fact"
  }

  provisioner "file" {
    content     = local.externaldns_facts_json
    destination = "/home/ubuntu/externaldns.fact"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/ansible/facts.d",
      "echo k8s.fact:; cat /home/ubuntu/k8s.fact",
      "sudo mv /home/ubuntu/k8s.fact /etc/ansible/facts.d/k8s.fact",
      "echo externaldns.fact:; cat /home/ubuntu/externaldns.fact",
      "sudo mv /home/ubuntu/externaldns.fact /etc/ansible/facts.d/externaldns.fact",
    ]
  }
}

locals {
  k8s_facts = {
    k8s_cluster_aws_region                 = var.aws_region
    k8s_cluster_name                       = aws_eks_cluster.app.name
    k8s_cluster_endpoint                   = aws_eks_cluster.app.endpoint
    k8s_cluster_version                    = aws_eks_cluster.app.version
    k8s_cluster_auth_config_map            = local.config_map_aws_auth
    k8s_cluster_storageclass_gp2_encrypted = local.storageclass_gp2_encrypted
    aws_load_balancer_controller_iam_role  = module.aws_lb_controller_service_account_iam_role.arn
    eks_worker_iam_role_arn                = aws_iam_role.eks_worker.arn
    k8s_admin_role_arn                     = data.aws_iam_role.assumed_role_admin.arn
    storage_kms_key_id                     = var.volumes_aws_kms_key_id
  }
  k8s_facts_json = jsonencode(local.k8s_facts)

  externaldns_facts = {
    public_service_account_iam_role_arn  = module.externaldns_public_service_account_iam_role.arn
    private_service_account_iam_role_arn = module.externaldns_private_service_account_iam_role.arn
  }
  externaldns_facts_json = jsonencode(local.externaldns_facts)
}

output "k8s_facts" {
  value = local.k8s_facts
}

output "externaldns_facts" {
  value = local.externaldns_facts
}

resource "aws_security_group_rule" "bastion_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.aws_bastion.aws_security_group_id
}

module "luthername_nsg_monitoring_temp" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "mon"
  resource       = "nsg"
  subcomponent   = "temp"
}

# This resource is a placeholder for the monitoring security group.
resource "aws_security_group" "monitoring_temp" {
  name   = module.luthername_nsg_monitoring_temp.names[0]
  vpc_id = aws_vpc.main.id
}
