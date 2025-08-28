# Prefer AL2023 if available; otherwise fall back to AL2.
# Only refresh the AMI when k8s version, instance type, or userdata version changes.

locals {
  # Detect architecture from instance type
  core        = substr(var.worker_instance_type, 0, 3)
  is_graviton = contains(["a1", "c6g", "m6g", "r6g", "t4g"], local.core)
  arch        = local.is_graviton ? "arm64" : "x86_64"

  # Use the actual cluster version so the AMI tracks the real control plane version
  k8s_version = aws_eks_cluster.app.version
}

# Check if AL2023 images exist for this k8s version and arch
data "aws_ami_ids" "al2023" {
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["amazon-eks-node-al2023-${local.arch}-standard-${local.k8s_version}-v*"]
  }
}

# Most recent AL2023 (if present)
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amazon-eks-node-al2023-${local.arch}-standard-${local.k8s_version}-v*"]
  }
}

# Most recent AL2 (always resolve, used as fallback)
data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name = "name"
    values = [
      local.is_graviton ? "amazon-eks-${local.arch}-node-${local.k8s_version}-v*" : "amazon-eks-node-${local.k8s_version}-v*"
    ]
  }
}

locals {
  # Prefer AL2023 when any matching AMI exists; otherwise AL2
  prefer_al2023     = length(try(data.aws_ami_ids.al2023.ids, [])) > 0
  selected_image_id = local.prefer_al2023 ? data.aws_ami.al2023.id : data.aws_ami.al2.id
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
    command = "echo 'ERROR: No EKS worker AMI found via filters!' && exit 1"
  }
}

# Lookup metadata for the selected AMI (used by is_al2023 and outputs)
data "aws_ami" "selected" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "image-id"
    values = [local.selected_image_id]
  }
}

locals {
  is_al2023 = can(regex("al2023", lower(data.aws_ami.selected.name)))
}

output "is_al2023" {
  value = local.is_al2023
}
output "worker_ami_id" {
  value = data.aws_ami.selected.id
}
output "worker_ami_name" {
  value = data.aws_ami.selected.name
}
