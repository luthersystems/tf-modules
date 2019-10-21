locals {
  persistentvolume_document = "${join("", data.template_file.persistentvolume_document.*.rendered)}"
}

output "k8s_persistentvolume_document" {
  value = "${local.persistentvolume_document}"
}

module "luthername_pv" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  subcomponent   = "${var.subcomponent}"
  resource       = "k8spv"
  replication    = "${var.replication}"

  providers = {
    template = "template"
  }
}

data "template_file" "persistentvolume_document" {
  count = "${var.replication}"

  template=<<TEMPLATE
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: $${name}
  labels: $${labels_json}
spec:
  capacity:
    storage: $${size_gb}Gi
  accessModes: $${access_modes_json}
  storageClassName: $${storage_class}
  awsElasticBlockStore:
    volumeID: $${volume_id}
    fsType: $${fs_type}
TEMPLATE

  vars = {
    name              = "${module.luthername_pv.names[count.index]}"
    region            = "${var.aws_region}"
    zone              = "${var.aws_availability_zones[count.index % length(var.aws_availability_zones)]}"
    index             = "${count.index}"
    size_gb           = "${var.volume_size_gb}"
    volume_id         = "${module.aws_ebs_volume_set.aws_ebs_volume_ids[count.index]}"
    storage_class     = "${var.k8s_storage_class}"
    access_modes_json = "${jsonencode(var.k8s_access_modes)}"
    fs_type           = "${var.fs_type}"
    labels_json       = "${jsonencode(merge(var.k8s_labels, map("app.kubernetes.io/name", "${module.luthername_pv.names[count.index]}", "app.kubernetes.io/component", "${var.component}", "replica-index", "${count.index}", "failure-domain.beta.kubernetes.io/region", "${var.aws_region}", "failure-domain.beta.kubernetes.io/zone", "${var.aws_availability_zones[count.index % length(var.aws_availability_zones)]}")))}"
  }
}

module "aws_ebs_volume_set" {
  source = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//aws-ebs-volume-set?ref=v3.0.0"

  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  subcomponent   = "${var.subcomponent}"
  replication    = "${var.replication}"

  aws_availability_zones = "${var.aws_availability_zones}"
  volume_size_gb         = "${var.volume_size_gb}"
  aws_kms_key_arn        = "${data.aws_kms_key.main.arn}"

  providers = {
    aws      = "aws"
    template = "template"
  }
}

output "aws_ebs_volume_ids" {
  value = "${module.aws_ebs_volume_set.aws_ebs_volume_ids}"
}

module "aws_ebs_snapshot_set" {
  source = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//aws-ebs-snapshot-set?ref=v3.0.0"

  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  subcomponent   = "${var.subcomponent}"
  replication    = "${var.replication}"

  aws_ebs_volume_ids = "${module.aws_ebs_volume_set.aws_ebs_volume_ids}"
  should_exist       = "${var.snapshots_should_exist}"

  providers = {
    aws      = "aws"
    template = "template"
  }
}

output "aws_ebs_snapshot_ids" {
  value = "${module.aws_ebs_snapshot_set.aws_ebs_snapshot_ids}"
}

data "aws_kms_key" "main" {
  key_id = "${var.aws_kms_key_id}"
}
