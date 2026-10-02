variable "current" {
  description = "Current Kubernetes version (MAJOR.MINOR, with optional patch or suffix); empty when no cluster exists."
  type        = string

  validation {
    condition     = var.current == "" || can(regex("^[0-9]+\\.[0-9]+", var.current))
    error_message = "current must be empty or start with MAJOR.MINOR (e.g. \"1.35\")."
  }
}

variable "desired" {
  description = "Desired Kubernetes version (MAJOR.MINOR, with optional patch or suffix)."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+", var.desired))
    error_message = "desired must start with MAJOR.MINOR (e.g. \"1.35\")."
  }
}
