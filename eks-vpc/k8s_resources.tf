data "aws_iam_role" "assumed_role_admin" {
  name = "admin"
}

locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.eks_worker.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${data.aws_iam_role.assumed_role_admin.arn}
      username: luther:admin
      groups:
        - system:masters
CONFIGMAPAWSAUTH

  # storageclass_gp2_encrypted declares "gp2-encrypted" as the default
  # storageclass but that will not actually work until the eks-created
  # storageclass, "gp2", is patched to deny its claim as the default.
  storageclass_gp2_encrypted = <<STORAGECLASS
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  name: gp2-encrypted
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  fsType: ext4
  encrypted: "true"
  kmsKeyId: ${var.volumes_aws_kms_key_id}
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
STORAGECLASS
}

output "config_map_aws_auth" {
  value = "${local.config_map_aws_auth}"
}
