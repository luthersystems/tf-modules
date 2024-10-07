moved {
  from = module.aws_bastion
  to   = module.aws_bastion[0]
}

moved {
  from = aws_secretsmanager_secret.slack_alerts_web_hook_url
  to   = aws_secretsmanager_secret.slack_alerts_web_hook_url[0]
}

moved {
  from = aws_secretsmanager_secret_version.slack_alerts_web_hook_url_secret
  to   = aws_secretsmanager_secret_version.slack_alerts_web_hook_url_secret[0]
}
