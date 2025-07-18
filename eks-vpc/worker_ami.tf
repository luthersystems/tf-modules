# # Only update the AMI when k8s version or instance type has changed. This avoids accidently
# refreshing the nodes due to a new AMI added to AWS.
locals {
  # Detect architecture from instance type
  core        = substr(var.worker_instance_type, 0, 3)
  is_graviton = contains(["a1", "c6g", "m6g", "r6g", "t4g"], local.core)
  arch        = local.is_graviton ? "arm64" : "x86_64"
  k8s_version = aws_eks_cluster.app.version
}


data "aws_ami" "eks_worker" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name = "name"
    values = [
      "amazon-eks-node-al2023-${local.arch}-standard-${local.k8s_version}-v*",
      local.is_graviton ? "amazon-eks-${local.arch}-node-${local.k8s_version}-v*" : "amazon-eks-node-${local.k8s_version}-v*"
    ]
  }
}


locals {
  # Prefer AL2023 since they are newer, fallback to AL2
  selected_image_id = data.aws_ami.eks_worker.id
}

resource "terraform_data" "image_id" {
  input = local.selected_image_id

  lifecycle {
    ignore_changes = [input]
  }

  # pull latest AMI if user data version changes
  triggers_replace = [aws_eks_cluster.app.version, var.worker_instance_type, var.custom_instance_userdata_version]
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
