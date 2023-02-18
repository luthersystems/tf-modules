#
# Only update the AMI when k8s version has changed. This avoids accidently
# refreshing the nodes due to a new AMI added to AWS.
#
locals {
  image_id = chomp(data.local_file.worker_ami.content)
  # TODO: is there a better way to cache this, directly in the state file?
  ami_cache_file = "${path.root}/vars/${terraform.workspace}/worker_ami.txt"
}

data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.app.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

resource "null_resource" "get_worker_ami" {
  triggers = { k8s_version = aws_eks_cluster.app.version }
  provisioner "local-exec" {
    command = "echo ${data.aws_ami.eks_worker.id} >> ${local.ami_cache_file}"
  }
}

data "local_file" "worker_ami" {
  filename   = local.ami_cache_file
  depends_on = [null_resource.get_worker_ami]
}
