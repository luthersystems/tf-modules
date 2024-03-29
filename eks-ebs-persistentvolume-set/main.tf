locals {
  persistentvolume_document = templatefile("${path.module}/pv.tftpl", { configs = [for i in range(var.replication) : {
    name              = module.luthername_pv.names[i]
    region            = var.aws_region
    zone              = var.aws_availability_zones[i % length(var.aws_availability_zones)]
    index             = i
    size_gb           = var.init_volume_size_gb
    volume_id         = module.aws_ebs_volume_set.aws_ebs_volume_ids[i]
    storage_class     = var.k8s_storage_class
    access_modes_json = jsonencode(var.k8s_access_modes)
    fs_type           = var.fs_type
    labels_json = jsonencode(
      merge(
        var.k8s_labels,
        {
          "app.kubernetes.io/name"      = module.luthername_pv.names[i]
          "app.kubernetes.io/component" = var.component
          # TF 0.12 tweak - confirm whether a string is necessary here
          "replica-index"                            = tostring(i)
          "failure-domain.beta.kubernetes.io/region" = var.aws_region
          "failure-domain.beta.kubernetes.io/zone"   = var.aws_availability_zones[i % length(var.aws_availability_zones)]
          "topology.kubernetes.io/region"            = var.aws_region
          "topology.kubernetes.io/zone"              = var.aws_availability_zones[i % length(var.aws_availability_zones)]
        },
      ),
    )
  }] })
}

output "k8s_persistentvolume_document" {
  value = local.persistentvolume_document
}

module "luthername_pv" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = var.component
  subcomponent   = var.subcomponent
  resource       = "k8spv"
  replication    = var.replication
}

module "aws_ebs_volume_set" {
  source = "../aws-ebs-volume-set"

  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = var.component
  subcomponent   = var.subcomponent
  replication    = var.replication

  init_volume_type    = var.init_volume_type
  init_volume_size_gb = var.init_volume_size_gb

  aws_availability_zones  = var.aws_availability_zones
  aws_kms_key_arn         = data.aws_kms_key.main.arn
  additional_tags         = var.additional_tags
  additional_per_vol_tags = var.additional_per_vol_tags
  snapshot_ids            = var.snapshot_ids

  providers = {
    aws = aws
  }
}

output "aws_ebs_volume_ids" {
  value = module.aws_ebs_volume_set.aws_ebs_volume_ids
}

data "aws_kms_key" "main" {
  key_id = var.aws_kms_key_id
}
