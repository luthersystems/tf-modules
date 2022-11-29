resource "aws_inspector_resource_group" "environment" {
  # The tags are OR'd, so search for the bastion name or the ASG group name
  tags = merge({
    "aws:autoscaling:groupName" = aws_autoscaling_group.eks_worker.name
  }, var.use_bastion ? { "Name" = local.bastion_name } : {})
}

module "luthername_inspector_environment" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "security"
  resource       = "inspector"
}

resource "aws_inspector_assessment_target" "environment" {
  name               = module.luthername_inspector_environment.name
  resource_group_arn = aws_inspector_resource_group.environment.arn
}

data "aws_inspector_rules_packages" "rules" {}

resource "aws_inspector_assessment_template" "environment" {
  name       = module.luthername_inspector_environment.name
  target_arn = aws_inspector_assessment_target.environment.arn
  duration   = 3600

  rules_package_arns = length(var.inspector_rules_package_arns) > 0 ? var.inspector_rules_package_arns : data.aws_inspector_rules_packages.rules.arns
}
