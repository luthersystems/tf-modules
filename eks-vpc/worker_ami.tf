# Prefer AL2023 if available; otherwise fall back to AL2.
# Only refresh the AMI when k8s version, instance type, or userdata version changes.

locals {
  # Detect architecture from instance type
  core        = substr(var.worker_instance_type, 0, 3)
  is_graviton = contains(["a1", "c6g", "m6g", "r6g", "t4g"], local.core)
  arch        = local.is_graviton ? "arm64" : "x86_64"

  # Track the real control plane version
  k8s_version   = aws_eks_cluster.app.version
  eks_ami_owner = "602401143452" # EKS official AMI account
}

# Find AL2023 candidates (doesn't fail if zero)
data "aws_ami_ids" "al2023" {
  owners = [local.eks_ami_owner]
  filter {
    name   = "name"
    values = ["amazon-eks-node-al2023-${local.arch}-standard-${local.k8s_version}-v*"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Find AL2 candidates (doesn't fail if zero)
data "aws_ami_ids" "al2" {
  owners = [local.eks_ami_owner]
  filter {
    name = "name"
    values = [
      local.is_graviton ? "amazon-eks-${local.arch}-node-${local.k8s_version}-v*" : "amazon-eks-node-${local.k8s_version}-v*"
    ]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

locals {
  has_al2023 = length(try(data.aws_ami_ids.al2023.ids, [])) > 0
  has_al2    = length(try(data.aws_ami_ids.al2.ids, [])) > 0
}

# Resolve the most recent AL2023 only if any exist
data "aws_ami" "al2023" {
  count       = local.has_al2023 ? 1 : 0
  most_recent = true
  owners      = [local.eks_ami_owner]
  filter {
    name   = "name"
    values = ["amazon-eks-node-al2023-${local.arch}-standard-${local.k8s_version}-v*"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Resolve the most recent AL2 only if AL2023 does not exist and AL2 exists
data "aws_ami" "al2" {
  count       = (!local.has_al2023 && local.has_al2) ? 1 : 0
  most_recent = true
  owners      = [local.eks_ami_owner]
  filter {
    name = "name"
    values = [
      local.is_graviton ? "amazon-eks-${local.arch}-node-${local.k8s_version}-v*" : "amazon-eks-node-${local.k8s_version}-v*"
    ]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

locals {
  # Put the conditional on one line to avoid parsing issues
  selected_image_id = local.has_al2023 ? data.aws_ami.al2023[0].id : (local.has_al2 ? data.aws_ami.al2[0].id : null)
}

resource "terraform_data" "image_id" {
  input = local.selected_image_id
  lifecycle {
    ignore_changes = [input]
  }
  # pull latest AMI if relevant inputs change
  triggers_replace = [
    aws_eks_cluster.app.version,
    var.worker_instance_type,
    var.custom_instance_userdata_version
  ]
}

locals {
  image_id = terraform_data.image_id.output
}

# Safety: fail hard if no AMI was resolved
resource "null_resource" "fail_if_no_ami" {
  count = local.selected_image_id == null ? 1 : 0
  provisioner "local-exec" {
    command = "echo 'ERROR: No EKS worker AMI found (AL2023 or AL2) for ${local.k8s_version} ${local.arch}!' && exit 1"
  }
}

# Lookup metadata for the selected AMI (and detect AL2023)
data "aws_ami" "selected" {
  count  = local.selected_image_id != null ? 1 : 0
  owners = [local.eks_ami_owner]
  filter {
    name   = "image-id"
    values = [local.selected_image_id]
  }
}

locals {
  is_al2023 = length(data.aws_ami.selected) > 0 ? can(regex("al2023", lower(data.aws_ami.selected[0].name))) : false
}

output "is_al2023" {
  value = local.is_al2023
}

output "worker_ami_id" {
  value = length(data.aws_ami.selected) > 0 ? data.aws_ami.selected[0].id : null
}

output "worker_ami_name" {
  value = length(data.aws_ami.selected) > 0 ? data.aws_ami.selected[0].name : null
}
