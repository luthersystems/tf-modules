module "luthername_snap" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  resource       = "snap"
  replication    = "${var.replication}"

  providers = {
    template = "template"
  }
}

resource "aws_ebs_snapshot" "vol" {
  count       = "${var.should_exist > 0 ? var.replication : 0}"
  volume_id   = "${element(var.aws_ebs_volume_ids, count.index)}"
  description = "Snapshot of ${var.component} -- id: ${module.luthername_snap.ids[count.index]}"

  tags = {
    Name         = "${module.luthername_snap.names[count.index]}"
    Project      = "${module.luthername_snap.luther_project}"
    Environment  = "${module.luthername_snap.luther_env}"
    Organization = "${module.luthername_snap.org_name}"
    Component    = "${module.luthername_snap.component}"
    Resource     = "${module.luthername_snap.resource}"
    ID           = "${module.luthername_snap.ids[count.index]}"
  }
}

output "aws_ebs_snapshot_ids" {
  value = "${aws_ebs_snapshot.vol.*.id}"
}
