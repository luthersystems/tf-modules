#
# Only update the AMI when k8s version has changed. This avoids accidently
# refreshing the nodes due to a new AMI added to AWS.
#
locals {
  image_id = terraform_data.worker_ami.output

  # Determine if the instance type is Graviton (ARM architecture)
  is_graviton = contains(["a1", "c6g", "m6g", "r6g", "t4g"], substr(var.worker_instance_type, 0, 3))

  # Set the AMI filter based on the instance type's architecture
  ami_name_filter = local.is_graviton ? "amazon-eks-arm64-node-${aws_eks_cluster.app.version}-v*" : "amazon-eks-node-${aws_eks_cluster.app.version}-v*"
}

data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = [local.ami_name_filter]
  }

  most_recent = true
  owners      = ["amazon"]
}

resource "terraform_data" "worker_ami" {
  input = data.aws_ami.eks_worker.id

  lifecycle {
    ignore_changes = [input]
  }

  triggers_replace = [aws_eks_cluster.app.version, var.worker_instance_type]
}
