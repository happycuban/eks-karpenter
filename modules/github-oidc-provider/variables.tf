variable "region" {
  type        = string
  description = "AWS region to provision infrastructure."

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-1, ap-southeast-2)."
  }
}

variable "bucket" {
  type        = string
  description = "S3 bucket for terraform state."

  validation {
    condition = (
      length(var.bucket) >= 3 &&
      length(var.bucket) <= 63 &&
      can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket)) &&
      !can(regex("\\.\\.|\\.\\-|\\-\\.", var.bucket)) &&
      !can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", var.bucket))
    )
    error_message = "Bucket name must be 3-63 characters, start/end with alphanumeric, contain only lowercase letters, numbers, hyphens, and periods. Cannot contain consecutive periods, period-hyphen, or hyphen-period combinations, and cannot be formatted as an IP address."
  }
}

variable "github_repos" {
  type        = list(string)
  description = "GitHub repositories in owner/repo format."

  validation {
    condition = (
      length(var.github_repos) >= 1 &&
      alltrue([
        for repo in var.github_repos :
        can(regex("^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$", repo))
      ])
    )
    error_message = "GitHub repositories must be in 'owner/repo' format and at least one repository must be specified."
  }
}