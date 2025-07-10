# # Only update the AMI when k8s version or instance type has changed. This avoids accidently
# refreshing the nodes due to a new AMI added to AWS.
locals {
  # Detect architecture from instance type
  core        = substr(var.worker_instance_type, 0, 3)
  is_graviton = contains(["a1", "c6g", "m6g", "r6g", "t4g"], local.core)
  arch        = local.is_graviton ? "arm64" : "x86_64"
  k8s_version = aws_eks_cluster.app.version

  # SSM parameter paths: prefer AL2023, fallback to AL2
  ssm_param_paths = [
    "/aws/service/eks/optimized-ami/${local.k8s_version}/amazon-linux-2023-${local.arch}/recommended/image_id",
    "/aws/service/eks/optimized-ami/${local.k8s_version}/amazon-linux-2-${local.arch}/recommended/image_id"
  ]
}

data "aws_ssm_parameter" "eks_worker_ami" {
  for_each = toset(local.ssm_param_paths)
  name     = each.value
}

locals {
  # Pick the first AMI found (AL2023 preferred)
  selected_worker_ami = compact([
    for path in local.ssm_param_paths :
    try(data.aws_ssm_parameter.eks_worker_ami[path].value, null)
  ])[0]
}

resource "terraform_data" "worker_ami" {
  input = local.selected_worker_ami

  lifecycle {
    ignore_changes = [input]
  }

  triggers_replace = [aws_eks_cluster.app.version, var.worker_instance_type]
}

# Use this everywhere else!
locals {
  image_id = terraform_data.worker_ami.output
}

resource "null_resource" "fail_if_no_ami" {
  count = local.selected_worker_ami == null ? 1 : 0
  provisioner "local-exec" {
    command = "echo 'ERROR: No EKS worker AMI found via SSM!' && exit 1"
  }
}
