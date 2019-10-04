module "luthername_eks_cluster" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  resource       = "eks"

  providers {
    template = "template"
  }
}

resource "aws_cloudwatch_log_group" "eks_cluster" {
  # Cannot depend on the aws_eks_cluster.app resource.
  name              = "/aws/eks/${module.luthername_eks_cluster.names[0]}/cluster"
  retention_in_days = 7
}

resource "aws_eks_cluster" "app" {
  name                      = "${module.luthername_eks_cluster.names[count.index]}"
  role_arn                  = "${aws_iam_role.eks_master.arn}"
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = ["${aws_security_group.eks_master.id}"]
    subnet_ids              = ["${aws_subnet.net.*.id}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.eks_master_AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.eks_master_AmazonEKSServicePolicy",
    "aws_cloudwatch_log_group.eks_cluster",
  ]
}

output "aws_eks_cluster_version" {
  value = "${aws_eks_cluster.app.version}"
}

output "aws_eks_cluster_name" {
  value = "${aws_eks_cluster.app.name}"
}

output "aws_eks_cluster_endpoint" {
  value = "${aws_eks_cluster.app.endpoint}"
}

module "luthername_eks_master_role" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  resource       = "role"
  subcomponent   = "eks"

  providers {
    template = "template"
  }
}

resource "aws_iam_role" "eks_master" {
  name               = "${module.luthername_eks_master_role.names[count.index]}"
  assume_role_policy = "${data.aws_iam_policy_document.eks_assume_role.json}"
}

data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_master_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.eks_master.name}"
}

resource "aws_iam_role_policy_attachment" "eks_master_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.eks_master.name}"
}

data "aws_kms_key" "volumes" {
  key_id = "${var.volumes_aws_kms_key_id}"
}

resource "aws_iam_role_policy" "eks_master_attach_volumes" {
  role   = "${aws_iam_role.eks_master.name}"
  policy = "${data.aws_iam_policy_document.attach_volumes.json}"
}

data "aws_iam_policy_document" "attach_volumes" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:Describe*",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
    ]

    resources = ["${data.aws_kms_key.volumes.arn}"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ec2.${var.aws_region}.amazonaws.com"]
    }
  }
}

module "luthername_eks_master_nsg" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  resource       = "nsg"
  subcomponent   = "eks"

  providers {
    template = "template"
  }
}

resource "aws_security_group" "eks_master" {
  name        = "${module.luthername_eks_master_nsg.names[count.index]}"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${aws_vpc.main.id}"

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "${module.luthername_eks_master_nsg.names[count.index]}"
    Project      = "${module.luthername_eks_master_nsg.luther_project}"
    Environment  = "${module.luthername_eks_master_nsg.luther_env}"
    Organization = "${module.luthername_eks_master_nsg.org_name}"
    Component    = "${module.luthername_eks_master_nsg.component}"
    Resource     = "${module.luthername_eks_master_nsg.resource}"
    ID           = "${module.luthername_eks_master_nsg.ids[0]}"
  }
}

resource "aws_security_group_rule" "eks_master_ingress_bastion" {
  description              = "Allow bastion to communicate with the cluster API Server"
  security_group_id        = "${aws_security_group.eks_master.id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = "${module.aws_bastion.aws_security_group_id}"
}

resource "aws_security_group_rule" "eks_master_ingress_worker_https" {
  description              = "Allow pods to communicate with the cluster API Server"
  security_group_id        = "${aws_security_group.eks_master.id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = "${aws_security_group.eks_worker.id}"
}
