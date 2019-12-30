module "luthername_vol" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  subcomponent   = "${var.subcomponent}"
  resource       = "vol"
  replication    = "${var.replication}"

  providers = {
    template = "template"
  }
}

locals {
  common_volume_tags = {
    Project      = "${module.luthername_vol.luther_project}"
    Environment  = "${module.luthername_vol.luther_env}"
    Organization = "${module.luthername_vol.org_name}"
    Component    = "${module.luthername_vol.component}"
    Resource     = "${module.luthername_vol.resource}"
  }
}

resource "aws_ebs_volume" "vol" {
  count             = "${var.replication}"
  availability_zone = "${element(var.aws_availability_zones, count.index)}"
  size              = "${var.volume_size_gb}"

  # Encrypt the volume using the environment-wide key.
  encrypted  = true
  kms_key_id = "${var.aws_kms_key_arn}"

  tags = "${merge(local.common_volume_tags,
                  map("Name", "${module.luthername_vol.names[count.index]}",
                      "ID", "${module.luthername_vol.ids[count.index]}"),
                  var.additional_tags)}"
}

output "aws_ebs_volume_ids" {
  value = "${aws_ebs_volume.vol.*.id}"
}
