# # Only update the AMI when k8s version or instance type has changed. This avoids accidently
# refreshing the nodes due to a new AMI added to AWS.
locals {
  # Detect architecture from instance type
  core        = substr(var.worker_instance_type, 0, 3)
  is_graviton = contains(["a1", "c6g", "m6g", "r6g", "t4g"], local.core)
  arch        = local.is_graviton ? "arm64" : "x86_64"
  k8s_version = aws_eks_cluster.app.version

  ssm_param_al2023 = "/aws/service/eks/optimized-ami/${local.k8s_version}/amazon-linux-2023-${local.arch}/recommended/image_id"
  ssm_param_al2    = "/aws/service/eks/optimized-ami/${local.k8s_version}/amazon-linux-2-${local.arch}/recommended/image_id"
}

data "aws_ssm_parameter" "eks_image_al2023" {
  name = local.ssm_param_al2023
}

data "aws_ssm_parameter" "eks_image_al2" {
  name = local.ssm_param_al2
}

locals {
  selected_image_id = try(
    data.aws_ssm_parameter.eks_image_al2023.value,
    data.aws_ssm_parameter.eks_image_al2.value,
    null
  )
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
    command = "echo 'ERROR: No EKS worker AMI found via SSM!' && exit 1"
  }
}
