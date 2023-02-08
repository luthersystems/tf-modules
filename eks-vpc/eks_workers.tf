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

module "luthername_eks_worker_launch_template" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = var.component
  # avoid destroying all nodes:
  #resource       = aws_eks_cluster.app.version

  # This id is a hack because ASG uses it as a prefix
  id = "worker-"
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
  count = local.managed_nodes ? 0 : 1

  desired_capacity = var.autoscaling_desired

  launch_template {
    id      = aws_launch_template.eks_worker.id
    version = aws_launch_template.eks_worker.default_version
  }

  max_size            = var.autoscaling_desired
  min_size            = var.autoscaling_desired
  name                = module.luthername_eks_worker_autoscaling_group.name
  vpc_zone_identifier = slice(aws_subnet.net.*.id, 0, var.autoscaling_desired)

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

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_worker_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_node_sa_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_worker_AmazonEKS_CNI_Policy
  ]
}

locals {
  eks_worker_asg_name = local.managed_nodes ? aws_eks_node_group.eks_worker[0].resources[0].autoscaling_groups[0].name : aws_autoscaling_group.eks_worker[0].name
}

output "eks_worker_asg_name" {
  value = local.eks_worker_asg_name
}

resource "aws_launch_template" "eks_worker" {

  update_default_version = true

  dynamic "network_interfaces" {
    for_each = local.managed_nodes ? [] : [local.managed_nodes]

    content {
      associate_public_ip_address = true
      security_groups             = [aws_security_group.eks_worker.id]
    }
  }


  dynamic "iam_instance_profile" {
    for_each = local.managed_nodes ? [] : [local.managed_nodes]

    content {
      name = aws_iam_instance_profile.eks_worker[0].name
    }
  }

  image_id               = data.aws_ami.eks_worker.id
  instance_type          = var.worker_instance_type
  name_prefix            = module.luthername_eks_worker_launch_template.name
  vpc_security_group_ids = local.managed_nodes ? [aws_security_group.eks_worker.id] : []
  user_data              = base64gzip(local.user_data)
  key_name               = local.managed_nodes ? "" : var.aws_ssh_key_name # disable ssh keys on managed nodes

  dynamic "instance_market_options" {
    for_each = !local.managed_nodes && length(var.spot_price) > 0 ? [var.spot_price] : []

    content {
      market_type = "spot"

      spot_options {
        max_price = var.spot_price
      }
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      key_name,
      image_id,
    ]
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = module.luthername_eks_worker_autoscaling_group.tags
  }
}

resource "aws_eks_node_group" "eks_worker" {
  count = local.managed_nodes ? 1 : 0

  node_group_name_prefix = module.luthername_eks_worker_autoscaling_group.name

  cluster_name  = aws_eks_cluster.app.name
  node_role_arn = aws_iam_role.eks_worker.arn
  subnet_ids    = slice(aws_subnet.net.*.id, 0, var.autoscaling_desired)

  capacity_type = length(var.spot_price) > 0 ? "SPOT" : "ON_DEMAND"

  scaling_config {
    desired_size = var.autoscaling_desired
    max_size     = var.autoscaling_desired
    min_size     = var.autoscaling_desired
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.eks_worker.id
    version = aws_launch_template.eks_worker.default_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_worker_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_node_sa_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_worker_AmazonEKS_CNI_Policy
  ]

  tags = module.luthername_eks_worker_autoscaling_group.tags
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
  count = local.disable_cni_node_role ? 0 : 1

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_worker.name
}

resource "aws_iam_role_policy_attachment" "eks_node_sa_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = module.eks_node_service_account_iam_role.name
}

resource "aws_iam_role_policy_attachment" "eks_worker_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_worker.name
}

resource "aws_iam_role_policy" "eks_worker_s3_readonly" {
  count = var.disable_s3_node_role || length(local.s3_prefixes) == 0 ? 0 : 1

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

    resources = compact([
      var.storage_s3_bucket_arn,
      var.common_static_s3_bucket_arn,
      var.common_external_s3_bucket_arn,
    ])
  }
}

locals {
  s3_prefixes = length(var.storage_s3_bucket_arn) > 0 ? [for prefix in var.storage_s3_key_prefixes : format("%s/%s", var.storage_s3_bucket_arn, prefix)] : []
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

resource "aws_iam_role_policy" "eks_worker_alb_ingress_controller" {
  count = local.disable_alb_node_role ? 0 : 1

  name = "alb-ingress-controller"
  # Policy taken from the guide here: https://aws.amazon.com/blogs/opensource/kubernetes-ingress-aws-alb-ingress-controller/
  # Original policy: https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.9/docs/examples/iam-policy.json
  role   = aws_iam_role.eks_worker.name
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "acm:DescribeCertificate",
        "acm:ListCertificates",
        "acm:GetCertificate"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateSecurityGroup",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeAddresses",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeTags",
        "ec2:DescribeVpcs",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifyNetworkInterfaceAttribute",
        "ec2:RevokeSecurityGroupIngress"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:AddListenerCertificates",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteRule",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:DescribeListenerCertificates",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:DescribeSSLPolicies",
        "elasticloadbalancing:DescribeTags",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetGroupAttributes",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:ModifyRule",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:RemoveListenerCertificates",
        "elasticloadbalancing:RemoveTags",
        "elasticloadbalancing:SetIpAddressType",
        "elasticloadbalancing:SetSecurityGroups",
        "elasticloadbalancing:SetSubnets",
        "elasticloadbalancing:SetWebAcl"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateServiceLinkedRole",
        "iam:GetServerCertificate",
        "iam:ListServerCertificates"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cognito-idp:DescribeUserPoolClient"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "waf-regional:GetWebACLForResource",
        "waf-regional:GetWebACL",
        "waf-regional:AssociateWebACL",
        "waf-regional:DisassociateWebACL"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "tag:GetResources",
        "tag:TagResources"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "waf:GetWebACL"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "wafv2:GetWebACL",
        "wafv2:GetWebACLForResource",
        "wafv2:AssociateWebACL",
        "wafv2:DisassociateWebACL"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "shield:DescribeProtection",
        "shield:GetSubscriptionState",
        "shield:DeleteProtection",
        "shield:CreateProtection",
        "shield:DescribeSubscription",
        "shield:ListProtections"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
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
  count = local.managed_nodes ? 0 : 1

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
