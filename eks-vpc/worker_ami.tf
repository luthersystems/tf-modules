# # Only update the AMI when k8s version or instance type has changed. This avoids accidently
# refreshing the nodes due to a new AMI added to AWS.
locals {
  # Determine if the instance type is Graviton (ARM architecture)
  core        = substr(var.worker_instance_type, 0, 3)
  is_graviton = contains(["a1", "c6g", "m6g", "r6g", "t4g"], local.core)
  arch        = local.is_graviton ? "arm64" : "x86_64"
  k8s_version = aws_eks_cluster.app.version

  # Paths for AL2023 and AL2 SSM AMI parameters (tries AL2023 first)
  ssm_param_paths = [
    "/aws/service/eks/optimized-ami/${local.k8s_version}/amazon-linux-2023-${local.arch}/recommended/image_id",
    "/aws/service/eks/optimized-ami/${local.k8s_version}/amazon-linux-2-${local.arch}/recommended/image_id"
  ]
}

# Try both parameter paths (AL2023 first), pick the first that exists
data "aws_ssm_parameter" "eks_worker_ami" {
  for_each = toset(local.ssm_param_paths)
  name     = each.value
}

# Select the first AMI found (AL2023 preferred, fallback to AL2)
locals {
  found_ami_ids = compact([
    for path in local.ssm_param_paths : try(data.aws_ssm_parameter.eks_worker_ami[path].value, null)
  ])
  selected_ami_id = length(local.found_ami_ids) > 0 ? local.found_ami_ids[0] : null
}

resource "terraform_data" "worker_ami" {
  input = local.selected_ami_id

  lifecycle {
    ignore_changes = [input]
  }

  triggers_replace = [aws_eks_cluster.app.version, var.worker_instance_type]
}

# Optional: Fail early if no AMI is found
resource "null_resource" "fail_if_no_ami" {
  count = local.selected_ami_id == null ? 1 : 0
  provisioner "local-exec" {
    command = "echo 'ERROR: No EKS worker AMI found via SSM!' && exit 1"
  }
}
