# k8s upgrade helper vars
locals {

  upgrade_stages = ["do_1.21", "prep_1.22", "do_1.22", "prep_1.23", "do_1.23", "finish_1.23"]

  upgrade_stages_settings = {

    "do_1.21" = {
      kubernetes_version    = "1.21"
      managed_nodes         = false
      kubeproxy_addon       = false
      cni_addon             = false
      coredns_addon         = false
      csi_addon             = false
      disable_alb_node_role = false
      disable_cni_node_role = false
      disable_csi_node_role = false
      monitoring            = false
    }

    "prep_1.22" = {
      kubernetes_version    = "1.21"
      managed_nodes         = true
      kubeproxy_addon       = true
      cni_addon             = true
      coredns_addon         = true
      csi_addon             = false
      disable_alb_node_role = false
      disable_cni_node_role = false
      disable_csi_node_role = false
      monitoring            = false
    }

    "do_1.22" = {
      kubernetes_version    = "1.22"
      managed_nodes         = true
      kubeproxy_addon       = true
      cni_addon             = true
      coredns_addon         = true
      csi_addon             = false
      disable_alb_node_role = false
      disable_cni_node_role = false
      disable_csi_node_role = false
      monitoring            = false
    }

    "prep_1.23" = {
      kubernetes_version    = "1.22"
      managed_nodes         = true
      kubeproxy_addon       = true
      cni_addon             = true
      coredns_addon         = true
      csi_addon             = true
      disable_alb_node_role = false
      disable_cni_node_role = false
      disable_csi_node_role = false
      monitoring            = false
    }

    "do_1.23" = {
      kubernetes_version    = "1.23"
      managed_nodes         = true
      kubeproxy_addon       = true
      cni_addon             = true
      coredns_addon         = true
      csi_addon             = true
      disable_alb_node_role = false
      disable_cni_node_role = false
      disable_csi_node_role = false
      monitoring            = false
    }

    "finish_1.23" = {
      kubernetes_version    = "1.23"
      managed_nodes         = true
      kubeproxy_addon       = true
      cni_addon             = true
      coredns_addon         = true
      csi_addon             = true
      disable_alb_node_role = true
      disable_cni_node_role = true
      disable_csi_node_role = true
      monitoring            = true
    }
  }

  upgrade_stage = try(local.upgrade_stages[var.k8s1_21to1_23_upgrade_step - 1], "")

  upgrade_overrides = try(local.upgrade_stages_settings[local.upgrade_stage], null)

  kubernetes_version = try(local.upgrade_overrides.kubernetes_version, var.kubernetes_version)

  managed_nodes = try(local.upgrade_overrides.managed_nodes, var.managed_nodes)

  kubeproxy_addon = try(local.upgrade_overrides.kubeproxy_addon, var.kubeproxy_addon && length(var.kubeproxy_addon_version[local.kubernetes_version]) > 0)
  cni_addon       = try(local.upgrade_overrides.cni_addon, var.cni_addon && length(var.coredns_addon_version[local.kubernetes_version]) > 0)
  csi_addon       = try(local.upgrade_overrides.csi_addon, var.csi_addon && length(var.csi_addon_version[local.kubernetes_version]) > 0)
  coredns_addon   = try(local.upgrade_overrides.coredns_addon, var.coredns_addon && length(var.coredns_addon_version[local.kubernetes_version]) > 0)

  disable_alb_node_role = try(local.upgrade_overrides.disable_alb_node_role, var.disable_alb_node_role)
  disable_cni_node_role = try(local.upgrade_overrides.disable_cni_node_role, var.disable_cni_node_role)
  disable_csi_node_role = try(local.upgrade_overrides.disable_csi_node_role, var.disable_csi_node_role)

  monitoring = try(local.upgrade_overrides.monitoring, var.monitoring)
}

output "upgrade_stage" {
  value = local.upgrade_stage
}
