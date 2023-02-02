# k8s upgrade helper vars
locals {

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
    }
  }

  upgrade_overrides = try(local.upgrade_stages_settings[var.upgrade_stage], null)

  kubernetes_version = try(local.upgrade_overrides.kubernetes_version, var.kubernetes_version)

  managed_nodes = try(local.upgrade_overrides.managed_nodes, var.managed_nodes)

  kubeproxy_addon = try(local.upgrade_overrides.kubeproxy_addon, var.kubeproxy_addon && length(var.kubeproxy_addon_version[local.kubernetes_version]) > 0)
  cni_addon       = try(local.upgrade_overrides.cni_addon, var.cni_addon && length(var.coredns_addon_version[local.kubernetes_version]) > 0)
  csi_addon       = try(local.upgrade_overrides.csi_addon, var.csi_addon && length(var.csi_addon_version[local.kubernetes_version]) > 0)
  coredns_addon   = try(local.upgrade_overrides.coredns_addon, var.coredns_addon && length(var.coredns_addon_version[local.kubernetes_version]) > 0)

  disable_alb_node_role = try(local.upgrade_overrides.disable_alb_node_role, var.disable_alb_node_role)
  disable_cni_node_role = try(local.upgrade_overrides.disable_cni_node_role, var.disable_cni_node_role)
  disable_csi_node_role = try(local.upgrade_overrides.disable_csi_node_role, var.disable_csi_node_role)
}
