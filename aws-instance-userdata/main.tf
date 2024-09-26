locals {
  s3_root = "https://s3.${var.aws_region}.amazonaws.com/amazoncloudwatch-agent-${var.aws_region}"

  cloudwatch_sources = {
    amazon_linux = "${local.s3_root}/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm",
    ubuntu       = "${local.s3_root}/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb",
  }

  package_install = {
    amazon_linux = "rpm -U"
    ubuntu       = "dpkg -i -E"
  }

  stream_prefix = "cwagent-${var.log_namespace}/{instance_id}"

  cloudwatch_agent_config = var.run_as_user == null ? {} : {
    agent = {
      run_as_user = "cwagent"
    }
  }

  collect_list_ts = [
    for log_file in var.timestamped_log_files :
    {
      file_path        = log_file.path,
      log_group_name   = var.cloudwatch_log_group,
      log_stream_name  = "${local.stream_prefix}${log_file.path}",
      timestamp_format = log_file.timestamp_format,
      timezone         = "UTC",
    }
  ]

  collect_list_no_ts = [
    for path in var.log_files :
    {
      file_path       = path,
      log_group_name  = var.cloudwatch_log_group,
      log_stream_name = "${local.stream_prefix}${path}",
    }
  ]

  cloudwatch_logs_config = {
    logs = {
      logs_collected = {
        files = {
          collect_list = concat(
            local.collect_list_ts,
            local.collect_list_no_ts,
          )
        },
      },
      log_stream_name = "${local.stream_prefix}/other",
    }
  }

  cloudwatch_config = merge(local.cloudwatch_agent_config, local.cloudwatch_logs_config)

  inspector_gpg_key  = file("${path.module}/files/inspector.gpg")
  cloudwatch_gpg_key = file("${path.module}/files/cloudwatch.gpg")

  user_data_vars = {
    inspector_gpg_key_base64  = base64encode(local.inspector_gpg_key),
    cloudwatch_gpg_key_base64 = base64encode(local.cloudwatch_gpg_key),
    cloudwatch_config_base64  = base64encode(jsonencode(local.cloudwatch_config)),
    cloudwatch_package_source = local.cloudwatch_sources[var.distro]
    package_install           = local.package_install[var.distro]
    custom_script             = var.custom_script
  }
}

output "cloudwatch_config" {
  value = local.cloudwatch_config
}

output "cloudwatch_config_json" {
  value = jsonencode(local.cloudwatch_config)
}

output "user_data" {
  value = templatefile("${path.module}/files/userdata.sh.tmpl", local.user_data_vars)
}
