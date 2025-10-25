###############################################################################
# Environment Variables
###############################################################################
variable "region" {
  type        = string
  description = "AWS region where the KMS key will be created"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-central-1)."
  }
}

variable "env" {
  type        = string
  description = "Environment name (dev, staging, prod)"

  validation {
    condition     = contains(["dev", "sta", "pro", "tes"], var.env)
    error_message = "Environment must be one of: dev, sta, pro, tes."
  }
}

###############################################################################
# KMS Key Configuration
###############################################################################
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster - used for KMS key alias and resource tagging"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.cluster_name))
    error_message = "Cluster name must start and end with alphanumeric characters and can contain hyphens."
  }
}