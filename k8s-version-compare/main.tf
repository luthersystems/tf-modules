locals {
  # Only the numeric major/minor pair affects Kubernetes version ordering.
  current = [for part in regex("^([0-9]+)\\.([0-9]+)", var.current == "" ? "0.0" : var.current) : tonumber(part)]
  desired = [for part in regex("^([0-9]+)\\.([0-9]+)", var.desired) : tonumber(part)]

  is_downgrade = var.current != "" && (
    local.desired[0] < local.current[0] ||
    (local.desired[0] == local.current[0] && local.desired[1] < local.current[1])
  )
}
