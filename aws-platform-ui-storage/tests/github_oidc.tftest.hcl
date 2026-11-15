# Pins that a deployment can reuse the account's GitHub Actions OIDC
# provider. An account holds one provider per URL, so a second deployment
# that created its own failed (tf-modules#98).

# The mock's random strings are not valid policy JSON.
mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
  override_data {
    target = data.aws_region.current
    values = { name = "us-west-2" }
  }
}
mock_provider "aws" {
  alias = "dr"
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
}
mock_provider "random" {}

variables {
  luther_env     = "env"
  luther_project = "project"
  has_github     = true
  ci_github_repos = [{
    org  = "luthersystems"
    repo = "app"
    env  = "test"
  }]
}

run "creates_the_provider_by_default" {
  command = plan

  assert {
    condition     = length(aws_iam_openid_connect_provider.github) == 1
    error_message = "Without github_oidc_provider_arn the module must create the provider."
  }

  assert {
    condition     = length(aws_iam_role.ci_role) == 1
    error_message = "The CI role must exist."
  }
}

run "reuses_an_existing_provider" {
  command = plan

  variables {
    github_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  }

  assert {
    condition     = length(aws_iam_openid_connect_provider.github) == 0
    error_message = "With github_oidc_provider_arn the module must not create a provider."
  }

  assert {
    condition     = output.github_oidc_provider_arn == "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
    error_message = "The output must name the provider that was passed in."
  }

  assert {
    condition     = length(aws_iam_role.ci_role) == 1
    error_message = "The CI role must exist."
  }
}

run "no_provider_without_github" {
  command = plan

  variables {
    has_github = false
  }

  assert {
    condition     = length(aws_iam_openid_connect_provider.github) == 0
    error_message = "Without GitHub the module must not create a provider."
  }

  assert {
    condition     = output.github_oidc_provider_arn == null
    error_message = "Without GitHub the output must be null."
  }
}

run "refuses_another_providers_arn" {
  command = plan

  variables {
    github_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/example.com"
  }

  expect_failures = [var.github_oidc_provider_arn]
}
