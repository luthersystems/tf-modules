data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.app.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

# This data source is included for ease of sample architecture deployment
# and can be swapped out as necessary.
data "aws_region" "current" {
}

locals {
  syslog_timestamp_format = "%b %d %H:%M:%S"
}

module "common_userdata" {
  source = "../aws-instance-userdata"

  aws_region           = var.aws_region
  cloudwatch_log_group = aws_cloudwatch_log_group.main.name
  distro               = "amazon_linux"
  log_namespace        = "worker"

  timestamped_log_files = [
    {
      path             = "/var/log/messages",
      timestamp_format = local.syslog_timestamp_format,
    },
    {
      path             = "/var/log/secure",
      timestamp_format = local.syslog_timestamp_format,
    },
    {
      path             = "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",
      timestamp_format = "%Y-%m-%dT%H:%M:%S",
    },
    {
      path             = "/var/log/cloud-init.log",
      timestamp_format = local.syslog_timestamp_format,
    },
  ]

  log_files = [
    "/var/log/cloud-init-output.log",
  ]
}

locals {
  docker_log_opts = {
    "awslogs-region"       = var.aws_region,
    "awslogs-group"        = aws_cloudwatch_log_group.main.name,
    "awslogs-create-group" = "false",
    "tag"                  = "docker/{{.Name}}/{{.ID}}",
  }

  docker_config = {
    "bridge"                   = "none",
    "log-driver"               = "awslogs",
    "log-opts"                 = local.docker_log_opts,
    "live-restore"             = true,
    "max-concurrent-downloads" = 10,
  }

  user_data_vars = {
    docker_config_json = jsonencode(local.docker_config),
    endpoint           = aws_eks_cluster.app.endpoint,
    cluster_ca         = aws_eks_cluster.app.certificate_authority[0].data,
    cluster_name       = aws_eks_cluster.app.name,
    common_userdata    = module.common_userdata.user_data
  }

  user_data = templatefile("${path.module}/files/userdata.sh.tmpl", local.user_data_vars)
}

# Docker log options are output so they can be used to configure a
# docker-in-docker (dind) daemon to route logs into the same log group.
output "docker_log_opts" {
  value = jsonencode(local.docker_log_opts)
}

module "luthername_eks_worker_launch_configuration" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = var.component
  resource       = aws_eks_cluster.app.version

  # This id is a hack because ASG uses it as a prefix
  id = "worker-"
}

resource "aws_launch_configuration" "eks_worker" {
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.eks_worker.name
  image_id                    = data.aws_ami.eks_worker.id
  instance_type               = var.worker_instance_type
  name_prefix                 = module.luthername_eks_worker_launch_configuration.name
  security_groups             = [aws_security_group.eks_worker.id]
  user_data_base64            = base64gzip(local.user_data)
  key_name                    = var.aws_ssh_key_name
  spot_price                  = var.spot_price

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      key_name,
      image_id,
    ]
  }
}

module "luthername_eks_worker_autoscaling_group" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "app"
  resource       = "asg"
  subcomponent   = "worker"
}

output "eks_worker_azs" {
  value = local.eks_worker_azs
}

locals {
  eks_worker_azs = slice(local.region_availability_zones, 0, var.autoscaling_desired)
}

resource "aws_autoscaling_group" "eks_worker" {
  desired_capacity     = var.autoscaling_desired
  launch_configuration = aws_launch_configuration.eks_worker.id
  max_size             = var.autoscaling_desired
  min_size             = var.autoscaling_desired
  name                 = module.luthername_eks_worker_autoscaling_group.name
  vpc_zone_identifier  = slice(aws_subnet.net.*.id, 0, var.autoscaling_desired)

  target_group_arns = var.worker_asg_target_group_arns

  dynamic "tag" {
    for_each = module.luthername_eks_worker_autoscaling_group.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "kubernetes.io/cluster/${aws_eks_cluster.app.name}"
    value               = "owned"
    propagate_at_launch = true
  }
}

output "eks_worker_asg_name" {
  value = aws_autoscaling_group.eks_worker.name
}

module "luthername_eks_worker_role" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "app"
  resource       = "role"
  subcomponent   = "worker"
}

resource "aws_iam_role" "eks_worker" {
  name               = module.luthername_eks_worker_role.name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

output "aws_iam_role_eks_worker" {
  value = aws_iam_role.eks_worker.name
}

output "aws_iam_role_eks_worker_arn" {
  value = aws_iam_role.eks_worker.arn
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_worker.name
}

resource "aws_iam_role_policy_attachment" "eks_worker_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = var.disable_node_role ? module.eks_node_service_account_iam_role.name : aws_iam_role.eks_worker.name
}

resource "aws_iam_role_policy_attachment" "eks_worker_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_worker.name
}

resource "aws_iam_role_policy" "eks_worker_s3_readonly" {
  count = var.disable_node_role || length(local.s3_prefixes) == 0 ? 0 : 1

  name   = "s3-readonly"
  role   = aws_iam_role.eks_worker.name
  policy = data.aws_iam_policy_document.s3_readonly.json
}

data "aws_iam_policy_document" "s3_readonly" {
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = var.aws_kms_key_arns
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = local.s3_prefixes
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${var.common_static_s3_bucket_arn}/*",
      "${var.common_external_s3_bucket_arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      var.storage_s3_bucket_arn,
      var.common_static_s3_bucket_arn,
      var.common_external_s3_bucket_arn,
    ]
  }
}

locals {
  s3_prefixes = [for prefix in var.storage_s3_key_prefixes : format("%s/%s", var.storage_s3_bucket_arn, prefix)]
}

resource "aws_iam_role_policy" "eks_worker_cloudwatch_logs" {
  name   = "cloudwatch-logs"
  role   = aws_iam_role.eks_worker.name
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

    resources = ["${aws_cloudwatch_log_group.main.arn}:*"]
  }
}

module "luthername_eks_worker_profile" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "app"
  resource       = "profile"
  subcomponent   = "worker"
}

resource "aws_iam_instance_profile" "eks_worker" {
  name = module.luthername_eks_worker_profile.name
  role = aws_iam_role.eks_worker.name
}

module "luthername_eks_worker_nsg" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "app"
  resource       = "nsg"
  subcomponent   = "worker"
}

resource "aws_security_group" "eks_worker" {
  name        = module.luthername_eks_worker_nsg.name
  description = "Security group for worker nodes in k8s"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name"                                              = module.luthername_eks_worker_nsg.name
    "Project"                                           = module.luthername_eks_worker_nsg.luther_project
    "Environment"                                       = module.luthername_eks_worker_nsg.luther_env
    "Organization"                                      = module.luthername_eks_worker_nsg.org_name
    "Component"                                         = module.luthername_eks_worker_nsg.component
    "Resource"                                          = module.luthername_eks_worker_nsg.resource
    "ID"                                                = module.luthername_eks_worker_nsg.id
    "kubernetes.io/cluster/${aws_eks_cluster.app.name}" = "owned"
  }
}

output "eks_worker_security_group_id" {
  value = aws_security_group.eks_worker.id
}

resource "aws_security_group_rule" "eks_worker_ingress_bastion_ssh" {
  count = var.use_bastion ? 1 : 0

  description              = "Allow bastion to connect to the worker over SSH"
  security_group_id        = aws_security_group.eks_worker.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 22
  to_port                  = 22
  source_security_group_id = module.aws_bastion[0].aws_security_group_id
}

resource "aws_security_group_rule" "eks_worker_ingress_self" {
  description              = "Allow workers to communicate with each other"
  security_group_id        = aws_security_group.eks_worker.id
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 65535
  source_security_group_id = aws_security_group.eks_worker.id
}

# NOTE:  Seems like I had to change this range from a lower bound of 1024 being
# unbounded.  Otherwise the kubectl proxy was unable to connect to pod that
# bound to low ports (e.g. 80).
resource "aws_security_group_rule" "eks_worker_ingress_eks_master" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  security_group_id        = aws_security_group.eks_worker.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 0
  to_port                  = 65535
  source_security_group_id = aws_security_group.eks_master.id
}

output "aws_iam_role_eks_node_sa_arn" {
  value = module.eks_node_service_account_iam_role.arn
}

output "aws_iam_role_eks_node_sa" {
  value = module.eks_node_service_account_iam_role.name
}

resource "random_string" "eks_node" {
  length  = 4
  upper   = false
  special = false
}

module "eks_node_service_account_iam_role" {
  source = "../eks-service-account-iam-role"

  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  component      = "k8s"

  oidc_provider_name = local.oidc_provider_name
  oidc_provider_arn  = local.oidc_provider_arn
  service_account    = "aws-node"
  k8s_namespace      = "kube-system"
  id                 = random_string.eks_node.result

  providers = {
    aws = aws
  }
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name             = aws_eks_cluster.app.name
  addon_name               = "vpc-cni"
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = module.eks_node_service_account_iam_role.arn
}

resource "random_string" "ebs_csi" {
  length  = 4
  upper   = false
  special = false
}

module "ebs_csi_controller_service_account_iam_role" {
  source = "../eks-service-account-iam-role"

  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  component      = "k8s"

  oidc_provider_name = local.oidc_provider_name
  oidc_provider_arn  = local.oidc_provider_arn
  service_account    = "ebs-csi-controller-sa"
  k8s_namespace      = "kube-system"
  id                 = random_string.ebs_csi.result

  providers = {
    aws = aws
  }
}

module "ebs_csi_node_service_account_iam_role" {
  source = "../eks-service-account-iam-role"

  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  component      = "k8s"

  oidc_provider_name = local.oidc_provider_name
  oidc_provider_arn  = local.oidc_provider_arn
  service_account    = "ebs-csi-node-sa"
  k8s_namespace      = "kube-system"
  id                 = random_string.ebs_csi.result

  providers = {
    aws = aws
  }
}


data "aws_iam_policy_document" "kms_ebs" {
  statement {
    effect = "Allow"

    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]

    resources = [data.aws_kms_key.volumes.arn]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = [true]
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = [data.aws_kms_key.volumes.arn]
  }
}

resource "aws_eks_addon" "ebs-csi" {
  count = 1

  cluster_name             = aws_eks_cluster.app.name
  addon_name               = "aws-ebs-csi-driver"
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = module.ebs_csi_controller_service_account_iam_role.arn
}

resource "aws_iam_role_policy_attachment" "ebs_controllerr_csi_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = module.ebs_csi_controller_service_account_iam_role.name
}

resource "aws_iam_role_policy" "ebs_controller_csi_kms" {
  role   = module.ebs_csi_controller_service_account_iam_role.name
  policy = data.aws_iam_policy_document.kms_ebs.json
}
