locals {
  region_code = var.aws_region_short_code[var.aws_region]
  prefix = join("-", compact(
    [
      var.luther_project,
      local.region_code,
      var.luther_env,
      var.org_name,
      var.component,
      var.resource,
  ]))

  ids   = [for i in range(var.replication) : "${var.subcomponent}${var.id == "" ? i : var.id}"]
  names = [for i in range(var.replication) : "${local.prefix}-${local.ids[i]}"]

  id   = var.replication == 1 ? local.ids[0] : null
  name = var.replication == 1 ? local.names[0] : null
}
