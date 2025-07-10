# # Only update the AMI when k8s version or instance type has changed. This avoids accidently
# refreshing the nodes due to a new AMI added to AWS.
locals {
  # Detect architecture from instance type
  core        = substr(var.worker_instance_type, 0, 3)
  is_graviton = contains(["a1", "c6g", "m6g", "r6g", "t4g"], local.core)
  arch        = local.is_graviton ? "arm64" : "x86_64"
  k8s_version = aws_eks_cluster.app.version

  ami_name_filters = [
    "amazon-eks-node-${local.k8s_version}-v*",
    "amazon-eks-node-al2023-${local.arch}-standard-${local.k8s_version}-v*"
  ]
}

data "aws_ami" "eks_worker" {
  for_each = toset(local.ami_name_filters)
  filter {
    name   = "name"
    values = [each.value]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
  most_recent = true
  owners      = ["amazon"]
}

locals {
  eks_worker_ami_ids = [for a in data.aws_ami.eks_worker : a.id]
  selected_image_id  = length(local.eks_worker_ami_ids) > 0 ? sort(local.eks_worker_ami_ids)[length(local.eks_worker_ami_ids) - 1] : null
}

resource "terraform_data" "image_id" {
  input = local.selected_image_id

  lifecycle {
    ignore_changes = [input]
  }

  triggers_replace = [aws_eks_cluster.app.version, var.worker_instance_type]
}

locals {
  image_id = terraform_data.image_id.output
}

resource "null_resource" "fail_if_no_ami" {
  count = local.selected_image_id == null ? 1 : 0
  provisioner "local-exec" {
    command = "echo 'ERROR: No EKS worker AMI found via filters!' && exit 1"
  }
}
