locals {
  aws_region_code = lookup(var.aws_region_short_code, var.aws_region, "")
  az_region_code  = lookup(var.az_location_short_code, var.az_location, "")
  prefix = join(var.delim, compact(
    [
      var.luther_project,
      local.aws_region_code,
      local.az_region_code,
      var.luther_env,
      var.org_name,
      var.component,
      var.resource,
  ]))

  ids   = [for i in range(var.replication) : "${var.subcomponent}${var.id == "" ? i : var.id}"]
  names = [for i in range(var.replication) : "${local.prefix}${var.delim}${local.ids[i]}"]

  id   = var.replication == 1 ? local.ids[0] : null
  name = var.replication == 1 ? local.names[0] : null
}
