resource "aws_cloudwatch_metric_alarm" "auto_recovery_alarm" {
  count               = var.replication
  alarm_name          = "AutoRecoveryAlarm-${var.instance_names[count.index]}-${var.aws_instance_ids[count.index]}"
  alarm_description   = "Auto recover the EC2 instance if Status Check (System) fails."
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed_System"
  statistic           = "Minimum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "1"
  period              = "60"
  evaluation_periods  = "5"
  datapoints_to_alarm = "2"

  dimensions = {
    InstanceId = var.aws_instance_ids[count.index]
  }

  actions_enabled = var.aws_cloudwatch_alarm_actions_enabled

  alarm_actions = [
    "arn:aws:automate:${var.aws_region}:ec2:recover",
    var.aws_autorecovery_sns_arn,
  ]

  insufficient_data_actions = [
    "arn:aws:automate:${var.aws_region}:ec2:recover",
    var.aws_autorecovery_sns_arn,
  ]

  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "auto_restart_alarm" {
  count               = var.replication
  alarm_name          = "AutoRestartAlarm-${var.instance_names[count.index]}-${var.aws_instance_ids[count.index]}"
  alarm_description   = "Auto restart the EC2 instance if Status Check (Instance) fails."
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed_Instance"
  statistic           = "Minimum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "1"
  period              = "60"
  evaluation_periods  = "5"
  datapoints_to_alarm = "3"
  treat_missing_data  = "breaching"

  dimensions = {
    InstanceId = var.aws_instance_ids[count.index]
  }

  actions_enabled = var.aws_cloudwatch_alarm_actions_enabled

  alarm_actions = [
    var.aws_autorestart_arn,
    var.aws_autorecovery_sns_arn,
  ]

  insufficient_data_actions = [
    var.aws_autorestart_arn,
    var.aws_autorecovery_sns_arn,
  ]
}
