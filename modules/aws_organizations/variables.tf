variable "credentials_file" {
  type        = list(string)
  description = "PATH to credentials file"

  validation {
    condition     = length(var.credentials_file) > 0
    error_message = "At least one credentials file path must be provided."
  }
}

variable "profile" {
  type        = string
  description = "Profile of AWS credential"

  validation {
    condition = (
      length(var.profile) >= 1 &&
      length(var.profile) <= 64 &&
      can(regex("^[a-zA-Z0-9._-]+$", var.profile))
    )
    error_message = "Profile name must be 1-64 characters and contain only alphanumeric characters, periods, underscores, and hyphens."
  }
}

variable "region" {
  type        = string
  description = "AWS Region"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-1, ap-southeast-2)."
  }
}