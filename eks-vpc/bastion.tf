locals {
  fqdn_bastion_vars = {
    project     = var.luther_project
    region_code = var.aws_region_short_code[var.aws_region]
    org_part    = "${var.org_name == "" ? "" : "-"}${var.org_name}"
    env         = var.luther_env
    domain      = var.human_domain
  }

  fqdn_bastion_name = format("%s-%s-%s%s.%s",
    local.fqdn_bastion_vars.project,
    local.fqdn_bastion_vars.region_code,
    local.fqdn_bastion_vars.env,
    local.fqdn_bastion_vars.org_part,
    local.fqdn_bastion_vars.domain,
  )
}

locals {
  bastion_public_dns = var.use_bastion ? module.aws_bastion[0].aws_instance_public_dns[0] : ""
}

output "bastion_dns_name" {
  value = (var.use_bastion && var.human_domain != "") ? aws_route53_record.bastion[0].name : local.bastion_public_dns
}

# A better dns name to use for ssh provisioning on the bastion because it can
# trigger reprovisioning if the bastion is replaced for any reason.
output "bastion_provisioning_dns_name" {
  value = local.bastion_public_dns
}

data "aws_route53_zone" "external" {
  count = (var.use_bastion && var.human_domain != "") ? 1 : 0
  name  = "${var.human_domain}."
}

resource "aws_route53_record" "bastion" {
  count = (var.use_bastion && var.human_domain != "") ? 1 : 0

  zone_id = data.aws_route53_zone.external.0.zone_id
  name    = local.fqdn_bastion_name
  type    = "CNAME"
  ttl     = 300
  records = [module.aws_bastion[0].aws_instance_public_dns[0]]
}

module "aws_bastion" {
  count = var.use_bastion ? 1 : 0

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
  ssh_whitelist_ingress                = var.bastion_ssh_whitelist
  prometheus_server_security_group_id  = aws_security_group.monitoring_temp.id
  authorized_key_sync_s3_bucket_arn    = var.ssh_public_keys_s3_bucket_arn
  common_static_asset_s3_bucket_arn    = var.common_static_s3_bucket_arn
  aws_kms_key_arns                     = var.aws_kms_key_arns
  aws_cloudwatch_alarm_actions_enabled = var.aws_cloudwatch_alarm_actions_enabled
  aws_autorecovery_sns_arn             = var.aws_autorecovery_sns_arn
  ssh_port                             = var.bastion_ssh_port
  cloudwatch_log_group                 = aws_cloudwatch_log_group.main.name
  cloudwatch_log_group_arn             = aws_cloudwatch_log_group.main.arn
  aws_availability_zones               = local.region_availability_zones
  replication                          = var.bastion_replication
  volume_type                          = var.bastion_volume_type

  providers = {
    aws = aws
  }
}

# null_resource.bastion_k8s_provisioning uploads k8s resource definitions to
# ec2 so that they may be loaded into eks from inside the VPC (no need for a
# tunnel).  Ansible playbooks are responsible for applying and destroying the
# k8s resources defined by the uploaded files.
resource "null_resource" "bastion_k8s_provisioning" {
  count = var.use_bastion ? 1 : 0

  triggers = {
    bastion_host      = module.aws_bastion[0].aws_instance_public_dns[0]
    k8s_facts         = local.k8s_facts_json
    externaldns_facts = local.externaldns_facts_json
  }

  connection {
    host = module.aws_bastion[0].aws_instance_public_dns[0]
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
  bastion_name = var.use_bastion ? module.aws_bastion[0].name : ""

  k8s_facts = {
    k8s_cluster_aws_region                 = var.aws_region
    k8s_cluster_name                       = aws_eks_cluster.app.name
    k8s_cluster_endpoint                   = aws_eks_cluster.app.endpoint
    k8s_cluster_version                    = aws_eks_cluster.app.version
    k8s_cluster_azs                        = local.eks_worker_azs
    k8s_cluster_auth_config_map            = local.config_map_aws_auth
    k8s_cluster_storageclass_gp2_encrypted = local.storageclass_gp2_encrypted
    k8s_cluster_storageclass_gp3_encrypted = local.storageclass_gp3_encrypted
    k8s_cluster_storageclass_sc1_encrypted = local.storageclass_sc1_encrypted
    aws_load_balancer_controller_iam_role  = module.aws_lb_controller_service_account_iam_role.arn
    eks_worker_iam_role_arn                = aws_iam_role.eks_worker.arn
    k8s_admin_role_arn                     = data.aws_iam_role.assumed_role_admin.arn
    storage_kms_key_id                     = var.volumes_aws_kms_key_id

    prometheus_service_account_iam_role_arn = local.prometheus_service_account_role_arn
    prometheus_workspace_id                 = try(aws_prometheus_workspace.k8s[0].id, "")

    fluentbit_service_account_iam_role_arn = local.fluentbit_service_account_role_arn
    fluentbit_log_group_name               = aws_cloudwatch_log_group.main.name

    k8s_fabric_ro_service_account_iam_role_arns        = local.fabric_ro_service_account_role_arns
    k8s_fabric_snapshot_service_account_iam_role_arns  = local.fabric_snapshot_service_account_role_arns
    k8s_fabric_namespace_service_account_iam_role_arns = local.fabric_namespace_service_account_iam_role_arns
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
  count = var.use_bastion ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.aws_bastion[0].aws_security_group_id
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
