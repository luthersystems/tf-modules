locals {
  ansible_facts = {
    docker_log_driver   = "awslogs"
    docker_log_options  = module.eks_vpc.docker_log_opts
    region              = local.region
    env_static_bucket   = local.storage_s3_bucket_arn
    acm_certificate_arn = aws_acm_certificate.cert.arn
  }

  ansible_facts_json = jsonencode(merge(local.ansible_facts, var.additional_ansible_facts))
}

locals {
  local_file_facts = {
    escaped_facts = {
      k8s_fabric_peer_docker_log_driver  = local.ansible_facts.docker_log_driver
      k8s_fabric_peer_docker_log_options = local.ansible_facts.docker_log_options
    }
    facts = merge(local.base_file_facts, var.additional_ansible_facts)
  }
  base_file_facts = {
    env_region               = local.ansible_facts.region
    env_static_bucket        = local.ansible_facts.env_static_bucket
    frontend_certificate_arn = local.ansible_facts.acm_certificate_arn

    kubectl_version                                = module.eks_vpc.k8s_facts.k8s_cluster_version
    kubectl_eks_cluster_name                       = module.eks_vpc.k8s_facts.k8s_cluster_name
    kubectl_eks_cluster_endpoint                   = module.eks_vpc.k8s_facts.k8s_cluster_endpoint
    kubectl_eks_region                             = module.eks_vpc.k8s_facts.k8s_cluster_aws_region
    eks_cluster_azs                                = module.eks_vpc.k8s_facts.k8s_cluster_azs
    eks_cluster_init_eks_worker_iam_role_arn       = module.eks_vpc.k8s_facts.eks_worker_iam_role_arn
    eks_cluster_init_k8s_admin_role_arn            = module.eks_vpc.k8s_facts.k8s_admin_role_arn
    eks_cluster_init_storage_kms_key_id            = module.eks_vpc.k8s_facts.storage_kms_key_id
    aws_lb_controller_service_account_iam_role_arn = module.eks_vpc.k8s_facts.aws_load_balancer_controller_iam_role

    externaldns_public_service_account_iam_role_arn  = module.eks_vpc.externaldns_facts.public_service_account_iam_role_arn
    externaldns_private_service_account_iam_role_arn = module.eks_vpc.externaldns_facts.private_service_account_iam_role_arn

    prometheus_service_account_iam_role_arn = module.eks_vpc.k8s_facts.prometheus_service_account_iam_role_arn
    prometheus_workspace_id                 = module.eks_vpc.k8s_facts.prometheus_workspace_id
  }
}

resource "local_file" "ansible_facts" {
  content         = templatefile("${path.module}/terraform_facts.yaml", local.local_file_facts)
  filename        = "${path.root}/${var.ansible_relative_path}/inventories/${var.luther_env}/group_vars/all/terraform_facts.yaml"
  file_permission = "0644"
}
