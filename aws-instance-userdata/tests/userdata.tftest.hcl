# Pins that the user data starts the SSM agent, through which Amazon
# Inspector (v2) scans the instance (tf-modules#97).

variables {
  aws_region           = "us-west-2"
  cloudwatch_log_group = "logs"
  log_namespace        = "test"
}

run "ubuntu_uses_the_ssm_agent_snap" {
  command = plan

  variables {
    distro = "ubuntu"
  }

  assert {
    condition     = strcontains(output.user_data, "snap install amazon-ssm-agent --classic")
    error_message = "Ubuntu user data must install the SSM agent snap when it is missing."
  }

  assert {
    condition     = strcontains(output.user_data, "systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service")
    error_message = "Ubuntu user data must start the SSM agent."
  }

  assert {
    condition     = !strcontains(output.user_data, "yum install")
    error_message = "Ubuntu user data must not use yum."
  }
}

run "amazon_linux_uses_the_ssm_agent_rpm" {
  command = plan

  variables {
    distro = "amazon_linux"
  }

  assert {
    condition     = strcontains(output.user_data, "yum install -y amazon-ssm-agent")
    error_message = "Amazon Linux user data must install the SSM agent when it is missing."
  }

  assert {
    condition     = strcontains(output.user_data, "systemctl enable --now amazon-ssm-agent.service")
    error_message = "Amazon Linux user data must start the SSM agent."
  }

  assert {
    condition     = !strcontains(output.user_data, "snap ")
    error_message = "Amazon Linux user data must not use snap."
  }
}

run "unknown_distro_is_refused" {
  command = plan

  variables {
    distro = "debian"
  }

  expect_failures = [var.distro]
}
