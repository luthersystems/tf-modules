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

# Additional customizations
set -euo pipefail

# Install latest security updates
yum update --security -y

# Disable root SSH
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl reload sshd

# Install Amazon Inspector Agent
curl -o install-inspector.sh https://inspector-agent.amazonaws.com/linux/latest/install
curl -o install-inspector.sh.sig https://d1wk0tztpsntt1.cloudfront.net/linux/latest/install.sig
echo '${base64encode(local.inspector_gpg_key)}' | base64 -d | gpg --import
gpg --verify ./install-inspector.sh.sig
bash install-inspector.sh
rm -f install-inspector.sh
USERDATA
}

# Docker log options are output so they can be used to configure a
# docker-in-docker (dind) daemon to route logs into the same log group.
output "docker_log_opts" {
  value = "${local.docker_log_opts}"
}

module "luthername_eks_worker_launch_configuration" {
  source         = "../luthername"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  resource       = "ec2"

  # This id is a hack because ASG uses it as a prefix
  id = "worker-"

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
  source         = "../luthername"
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
  desired_capacity     = "${var.autoscaling_desired}"
  launch_configuration = "${aws_launch_configuration.eks_worker.id}"
  max_size             = "${var.autoscaling_desired}"
  min_size             = 1
  name                 = "${module.luthername_eks_worker_autoscaling_group.names[count.index]}"
  vpc_zone_identifier  = ["${aws_subnet.net.*.id}"]

  target_group_arns = ["${var.worker_asg_target_group_arns}"]

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

output "eks_worker_asg_name" {
  value = "${aws_autoscaling_group.eks_worker.name}"
}

module "luthername_eks_worker_role" {
  source         = "../luthername"
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
      "${var.storage_s3_bucket_arn}",
      "${var.common_static_s3_bucket_arn}",
      "${var.common_external_s3_bucket_arn}",
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
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeAddresses",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeInternetGateways",
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
        "iam:CreateServiceLinkedRole",
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
  source         = "../luthername"
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
  source         = "../luthername"
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

output "eks_worker_security_group_id" {
  value = "${aws_security_group.eks_worker.id}"
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
