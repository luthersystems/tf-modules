data "aws_iam_role" "assumed_role_admin" {
  name = "admin"
}

# deprecated - moved to ansible
locals {

  alt_admin_role_entry = (
    var.has_alt_admin_role ? <<ALTADMIN
    - rolearn: ${local.k8s_alt_admin_role_arn}
      username: luther:admin
      groups:
        - system:masters
ALTADMIN
    : ""
  )

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
${local.alt_admin_role_entry}
CONFIGMAPAWSAUTH

  # storageclass_gp2_encrypted declares "gp2-encrypted" for backwards
  # compatibility.
  storageclass_gp2_encrypted = <<STORAGECLASS
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
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

  # storageclass_sc1_encrypted declares "sc1-encrypted" for ledger
  # data.
  storageclass_sc1_encrypted = <<STORAGECLASS
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: sc1-encrypted
provisioner: kubernetes.io/aws-ebs
parameters:
  type: sc1
  fsType: ext4
  encrypted: "true"
  kmsKeyId: ${var.volumes_aws_kms_key_id}
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
STORAGECLASS

  # storageclass_gp3_encrypted declares "gp3-encrypted" as the default
  # storageclass but that will not actually work until the eks-created
  # storageclass, "gp2-encrypted", is patched to deny its claim as the default.
  storageclass_gp3_encrypted = <<STORAGECLASS
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  name: gp3-encrypted
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  fsType: ext4
  encrypted: "true"
  kmsKeyId: ${var.volumes_aws_kms_key_id}
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
STORAGECLASS

}

output "config_map_aws_auth" {
  value = local.config_map_aws_auth
}
