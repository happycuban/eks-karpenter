###############################################################################
# Environment Variables
###############################################################################
variable "region" {
  type        = string
  description = "AWS region to provision ECR repositories"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-central-1)."
  }
}

###############################################################################
# Storage Configuration
###############################################################################
variable "bucket" {
  type        = string
  description = "S3 bucket for terraform state storage"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket))
    error_message = "S3 bucket name must start and end with lowercase alphanumeric characters and can contain hyphens."
  }

  validation {
    condition     = length(var.bucket) >= 3 && length(var.bucket) <= 63
    error_message = "S3 bucket name must be between 3 and 63 characters long."
  }
}

###############################################################################
# Repository Configuration
###############################################################################
variable "github_repos" {
  type        = list(string)
  description = "List of GitHub repositories for which to create ECR repositories"

  validation {
    condition     = length(var.github_repos) > 0
    error_message = "At least one GitHub repository must be specified."
  }

  validation {
    condition = alltrue([
      for repo in var.github_repos : can(regex("^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$", repo))
    ])
    error_message = "GitHub repositories must be in 'owner/repo' format with valid characters."
  }
}