data "template_file" "id" {
  count    = "${var.replication}"
  template = "$${subcomponent}$${id}"

  vars {
    subcomponent = "${var.subcomponent}"
    id           = "${var.id != "" ? var.id : "${count.index}"}"
  }
}

data "template_file" "org_part" {
  template = "$${hyphen}$${org_name}"

  vars {
    hyphen   = "${var.org_name == "" ? "" : "-"}"
    org_name = "${var.org_name}"
  }
}

data "template_file" "name" {
  count    = "${var.replication}"
  template = "$${project}-$${region_code}-$${env}$${org_part}-$${component}-$${resource}-$${id}"

  vars {
    project     = "${var.luther_project}"
    region_code = "${var.aws_region_short_code[var.aws_region]}"
    env         = "${var.luther_env}"
    org_part    = "${data.template_file.org_part.rendered}"
    component   = "${var.component}"
    resource    = "${var.resource}"
    id          = "${data.template_file.id.*.rendered[count.index]}"
  }
}
