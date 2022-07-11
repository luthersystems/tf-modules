data "aws_caller_identity" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  restart_arn = "arn:aws:swf:${var.aws_region}:${local.account_id}:action/actions/AWS_EC2.InstanceId.Reboot/1.0"
  recover_arn = "arn:aws:automate:${var.aws_region}:ec2:recover"
  recovery_actions = compact([
    local.recover_arn,
    var.aws_autorecovery_sns_arn,
  ])
  restart_actions = compact([
    local.restart_arn,
    var.aws_autorecovery_sns_arn,
  ])
}

resource "aws_cloudwatch_metric_alarm" "auto_recovery_alarm" {
  count                     = length(var.aws_instance_ids)
  alarm_name                = "AutoRecoveryAlarm-${var.instance_names[count.index]}-${var.aws_instance_ids[count.index]}"
  alarm_description         = "Auto recover the EC2 instance if Status Check (System) fails."
  namespace                 = "AWS/EC2"
  metric_name               = "StatusCheckFailed_System"
  statistic                 = "Minimum"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = "1"
  period                    = "60"
  evaluation_periods        = "5"
  datapoints_to_alarm       = "2"
  actions_enabled           = var.aws_cloudwatch_alarm_actions_enabled
  alarm_actions             = local.recovery_actions
  insufficient_data_actions = local.recovery_actions
  treat_missing_data        = "breaching"

  dimensions = {
    InstanceId = var.aws_instance_ids[count.index]
  }

}

resource "aws_cloudwatch_metric_alarm" "auto_restart_alarm" {
  count                     = length(var.aws_instance_ids)
  alarm_name                = "AutoRestartAlarm-${var.instance_names[count.index]}-${var.aws_instance_ids[count.index]}"
  alarm_description         = "Auto restart the EC2 instance if Status Check (Instance) fails."
  namespace                 = "AWS/EC2"
  metric_name               = "StatusCheckFailed_Instance"
  statistic                 = "Minimum"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = "1"
  period                    = "60"
  evaluation_periods        = "5"
  datapoints_to_alarm       = "3"
  treat_missing_data        = "breaching"
  actions_enabled           = var.aws_cloudwatch_alarm_actions_enabled
  alarm_actions             = local.restart_actions
  insufficient_data_actions = local.restart_actions

  dimensions = {
    InstanceId = var.aws_instance_ids[count.index]
  }
}
