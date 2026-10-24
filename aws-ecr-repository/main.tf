resource "aws_ecr_repository" "main" {
  name = var.name

  # Scan each image for known CVEs when it is pushed, so a vulnerable image
  # shows in the ECR console before anything pulls it. Basic scanning is
  # free, and the setting changes in place on an existing repository. An
  # account with a registry-level scanning configuration uses that instead,
  # so a caller there can set scan_on_push = false to match it.
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }
}

output "arn" {
  value = aws_ecr_repository.main.arn
}

output "name" {
  value = aws_ecr_repository.main.name
}

output "registry_id" {
  value = aws_ecr_repository.main.registry_id
}

output "repository_url" {
  value = aws_ecr_repository.main.repository_url
}

# A policy is only included if either ro_principals or rw_principals is
# non-empty.
resource "aws_ecr_repository_policy" "main" {
  count      = length(var.ro_principals) + length(var.rw_principals) == 0 ? 0 : 1
  repository = aws_ecr_repository.main.name
  policy     = local.policy
}
