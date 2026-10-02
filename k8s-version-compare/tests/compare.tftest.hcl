# Regression coverage for GitHub issue #74: prevent accidental EKS rollbacks.

run "minor_downgrade" {
  command = plan

  variables {
    current = "1.35"
    desired = "1.34"
  }

  assert {
    condition     = output.is_downgrade == true
    error_message = "Expected 1.35 -> 1.34 to have is_downgrade = true."
  }
}

run "minor_upgrade" {
  command = plan

  variables {
    current = "1.34"
    desired = "1.35"
  }

  assert {
    condition     = output.is_downgrade == false
    error_message = "Expected 1.34 -> 1.35 to have is_downgrade = false."
  }
}

run "same_version" {
  command = plan

  variables {
    current = "1.35"
    desired = "1.35"
  }

  assert {
    condition     = output.is_downgrade == false
    error_message = "Expected 1.35 -> 1.35 to have is_downgrade = false."
  }
}

run "no_existing_cluster" {
  command = plan

  variables {
    current = ""
    desired = "1.30"
  }

  assert {
    condition     = output.is_downgrade == false
    error_message = "Expected no cluster -> 1.30 to have is_downgrade = false."
  }
}

run "numeric_minor_downgrade" {
  command = plan

  variables {
    current = "1.10"
    desired = "1.9"
  }

  assert {
    condition     = output.is_downgrade == true
    error_message = "Expected 1.10 -> 1.9 to have is_downgrade = true."
  }
}

run "numeric_minor_upgrade" {
  command = plan

  variables {
    current = "1.9"
    desired = "1.10"
  }

  assert {
    condition     = output.is_downgrade == false
    error_message = "Expected 1.9 -> 1.10 to have is_downgrade = false."
  }
}

run "major_downgrade" {
  command = plan

  variables {
    current = "2.0"
    desired = "1.35"
  }

  assert {
    condition     = output.is_downgrade == true
    error_message = "Expected 2.0 -> 1.35 to have is_downgrade = true."
  }
}

run "patch_ignored" {
  command = plan

  variables {
    current = "1.35.2"
    desired = "1.35"
  }

  assert {
    condition     = output.is_downgrade == false
    error_message = "Expected 1.35.2 -> 1.35 to have is_downgrade = false."
  }
}

run "major_upgrade_with_lower_minor" {
  command = plan

  variables {
    current = "1.35"
    desired = "2.0"
  }

  assert {
    condition     = output.is_downgrade == false
    error_message = "Expected 1.35 -> 2.0 to have is_downgrade = false."
  }
}

run "suffix_ignored" {
  command = plan

  variables {
    current = "1.35-eks-build"
    desired = "1.35"
  }

  assert {
    condition     = output.is_downgrade == false
    error_message = "Expected 1.35-eks-build -> 1.35 to have is_downgrade = false."
  }
}

run "desired_patch_and_suffix_ignored" {
  command = plan

  variables {
    current = "1.35"
    desired = "1.34.9-eks-build"
  }

  assert {
    condition     = output.is_downgrade == true
    error_message = "Expected 1.35 -> 1.34.9-eks-build to have is_downgrade = true."
  }
}

run "rejects_malformed_desired" {
  command = plan

  variables {
    current = "1.35"
    desired = "1"
  }

  expect_failures = [var.desired]
}
