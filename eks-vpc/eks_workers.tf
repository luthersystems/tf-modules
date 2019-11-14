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
data "aws_region" "current" {}

# EKS currently documents required userdata (local.eks_worker_userdata) for EKS
# worker nodes to properly configure Kubernetes applications on the EC2
# instance.  We implement a Terraform local here to simplify Base64 encoding
# this information into the AutoScaling Launch Configuration.
#
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  docker_log_opts = <<LOGOPTS
{
    "awslogs-region": ${jsonencode(var.aws_region)},
    "awslogs-group": ${jsonencode(aws_cloudwatch_log_group.main.name)},
    "awslogs-create-group": "false",
    "tag": "docker/{{.Name}}/{{.ID}}"
}
LOGOPTS

  docker_config_json = <<DOCKERCONFIG
{
    "bridge": "none",
    "log-driver": "awslogs",
    "log-opts": ${indent(4, local.docker_log_opts)},
    "live-restore": true,
    "max-concurrent-downloads": 10
}
DOCKERCONFIG

  eks_worker_userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.app.endpoint}' --b64-cluster-ca '${aws_eks_cluster.app.certificate_authority.0.data}' --docker-config-json '${local.docker_config_json}' '${aws_eks_cluster.app.name}'
USERDATA
}

# Docker log options are output so they can be used to configure a
# docker-in-docker (dind) daemon to route logs into the same log group.
output "docker_log_opts" {
  value = "${local.docker_log_opts}"
}

module "luthername_eks_worker_launch_configuration" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  resource       = "ec2"
  id             = "worker-"                                                                            # This id is a hack because ASG uses it as a prefix

  providers {
    template = "template"
  }
}

resource "aws_launch_configuration" "eks_worker" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.eks_worker.name}"
  image_id                    = "${data.aws_ami.eks_worker.id}"
  instance_type               = "${var.worker_instance_type}"
  name_prefix                 = "${module.luthername_eks_worker_launch_configuration.names[count.index]}"
  security_groups             = ["${aws_security_group.eks_worker.id}"]
  user_data_base64            = "${base64encode(local.eks_worker_userdata)}"
  key_name                    = "${var.aws_ssh_key_name}"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["key_name", "image_id"]
  }
}

module "luthername_eks_worker_autoscaling_group" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "app"
  resource       = "asg"
  subcomponent   = "worker"

  providers {
    template = "template"
  }
}

resource "aws_autoscaling_group" "eks_worker" {
  desired_capacity     = 3
  launch_configuration = "${aws_launch_configuration.eks_worker.id}"
  max_size             = 3
  min_size             = 1
  name                 = "${module.luthername_eks_worker_autoscaling_group.names[count.index]}"
  vpc_zone_identifier  = ["${aws_subnet.net.*.id}"]

  tag {
    key                 = "Name"
    value               = "${module.luthername_eks_worker_autoscaling_group.names[count.index]}"
    propagate_at_launch = false
  }

  tag {
    key                 = "Project"
    value               = "${module.luthername_eks_worker_autoscaling_group.luther_project}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${module.luthername_eks_worker_autoscaling_group.luther_env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Organization"
    value               = "${module.luthername_eks_worker_autoscaling_group.org_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Component"
    value               = "${module.luthername_eks_worker_autoscaling_group.component}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Subcomponent"
    value               = "${module.luthername_eks_worker_autoscaling_group.subcomponent}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${aws_eks_cluster.app.name}"
    value               = "owned"
    propagate_at_launch = true
  }
}

module "luthername_eks_worker_role" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "app"
  resource       = "role"
  subcomponent   = "worker"

  providers {
    template = "template"
  }
}

resource "aws_iam_role" "eks_worker" {
  name               = "${module.luthername_eks_worker_role.names[count.index]}"
  assume_role_policy = "${data.aws_iam_policy_document.ec2_assume_role.json}"
}

output "aws_iam_role_eks_worker" {
  value = "${aws_iam_role.eks_worker.name}"
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
  role       = "${aws_iam_role.eks_worker.name}"
}

resource "aws_iam_role_policy_attachment" "eks_worker_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.eks_worker.name}"
}

resource "aws_iam_role_policy_attachment" "eks_worker_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.eks_worker.name}"
}

resource "aws_iam_role_policy" "eks_worker_s3_readonly" {
  role   = "${aws_iam_role.eks_worker.name}"
  policy = "${data.aws_iam_policy_document.s3_readonly.json}"
}

data "aws_iam_policy_document" "s3_readonly" {
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["${var.aws_kms_key_arns}"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = ["${data.template_file.s3_prefixes.*.rendered}"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = ["${var.common_static_s3_bucket_arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${var.storage_s3_bucket_arn}",
      "${var.common_static_s3_bucket_arn}",
    ]
  }
}

data "template_file" "s3_prefixes" {
  count = "${length(var.storage_s3_key_prefixes)}"

  template = "$${bucket_arn}/$${prefix}"

  vars = {
    bucket_arn = "${var.storage_s3_bucket_arn}"
    prefix     = "${var.storage_s3_key_prefixes[count.index]}"
  }
}

resource "aws_iam_role_policy" "eks_worker_cloudwatch_logs" {
  role   = "${aws_iam_role.eks_worker.name}"
  policy = "${data.aws_iam_policy_document.cloudwatch_logs.json}"
}

data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["${aws_cloudwatch_log_group.main.arn}"]
  }
}

resource "aws_iam_role_policy" "eks_worker_alb_ingress_controller" {
  # Policy taken from the guide here: https://aws.amazon.com/blogs/opensource/kubernetes-ingress-aws-alb-ingress-controller/
  # Original policy: https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.0.0/docs/examples/iam-policy.json
  role = "${aws_iam_role.eks_worker.name}"

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
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
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
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeListenerCertificates",
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
        "elasticloadbalancing:RemoveTags",
        "elasticloadbalancing:SetIpAddressType",
        "elasticloadbalancing:SetSecurityGroups",
        "elasticloadbalancing:SetSubnets",
        "elasticloadbalancing:SetWebACL"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetServerCertificate",
        "iam:ListServerCertificates"
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
    }
  ]
}
POLICY
}

module "luthername_eks_worker_profile" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "app"
  resource       = "profile"
  subcomponent   = "worker"

  providers {
    template = "template"
  }
}

resource "aws_iam_instance_profile" "eks_worker" {
  name = "${module.luthername_eks_worker_profile.names[count.index]}"
  role = "${aws_iam_role.eks_worker.name}"
}

module "luthername_eks_worker_nsg" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "app"
  resource       = "nsg"
  subcomponent   = "worker"

  providers {
    template = "template"
  }
}

resource "aws_security_group" "eks_worker" {
  name        = "${module.luthername_eks_worker_nsg.names[count.index]}"
  description = "Security group for worker nodes in k8s"
  vpc_id      = "${aws_vpc.main.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "${module.luthername_eks_worker_nsg.names[count.index]}",
     "Project", "${module.luthername_eks_worker_nsg.luther_project}",
     "Environment", "${module.luthername_eks_worker_nsg.luther_env}",
     "Organization", "${module.luthername_eks_worker_nsg.org_name}",
     "Component", "${module.luthername_eks_worker_nsg.component}",
     "Resource", "${module.luthername_eks_worker_nsg.resource}",
     "ID", "${module.luthername_eks_worker_nsg.ids[count.index]}",
     "kubernetes.io/cluster/${aws_eks_cluster.app.name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "eks_worker_ingress_bastion_ssh" {
  description              = "Allow bastion to connect to the worker over SSH"
  security_group_id        = "${aws_security_group.eks_worker.id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 22
  to_port                  = 22
  source_security_group_id = "${module.aws_bastion.aws_security_group_id}"
}

resource "aws_security_group_rule" "eks_worker_ingress_self" {
  description              = "Allow workers to communicate with each other"
  security_group_id        = "${aws_security_group.eks_worker.id}"
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 65535
  source_security_group_id = "${aws_security_group.eks_worker.id}"
}

# NOTE:  Seems like I had to change this range from a lower bound of 1024 being
# unbounded.  Otherwise the kubectl proxy was unable to connect to pod that
# bound to low ports (e.g. 80).
resource "aws_security_group_rule" "eks_worker_ingress_eks_master" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  security_group_id        = "${aws_security_group.eks_worker.id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 0
  to_port                  = 65535
  source_security_group_id = "${aws_security_group.eks_master.id}"
}
