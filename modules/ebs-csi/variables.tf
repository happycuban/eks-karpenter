###############################################################################
# Environment Variables
###############################################################################
variable "region" {
  type        = string
  description = "AWS region where resources will be created"

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
# EKS Cluster Configuration
###############################################################################
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster where EBS CSI will be deployed"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.cluster_name))
    error_message = "Cluster name must start and end with alphanumeric characters and can contain hyphens."
  }
}

###############################################################################
# EBS CSI Configuration
###############################################################################
variable "ebs_csi_kms" {
  type        = string
  description = "KMS key ARN for EBS CSI encryption. If not provided, default EBS encryption will be used."
  default     = null

  validation {
    condition     = var.ebs_csi_kms == null || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]+:key/[a-f0-9-]+$", var.ebs_csi_kms))
    error_message = "KMS key ARN must be a valid AWS KMS key ARN format."
  }
}

variable "create_default_storage_class" {
  type        = bool
  description = "Whether to create a default GP3 storage class with encryption"
  default     = true
}

variable "storage_class_name" {
  type        = string
  description = "Name of the default storage class to create"
  default     = "gp3-default"
}

variable "storage_type" {
  type        = string
  description = "EBS volume type for the storage class"
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "sc1", "st1"], var.storage_type)
    error_message = "Storage type must be one of: gp2, gp3, io1, io2, sc1, st1."
  }
}

###############################################################################
# Kubectl Provider Configuration
###############################################################################
variable "cluster_endpoint" {
  type        = string
  description = "EKS cluster endpoint for kubectl provider"

  validation {
    condition     = can(regex("^https://", var.cluster_endpoint))
    error_message = "Cluster endpoint must be a valid HTTPS URL."
  }
}

variable "cluster_certificate_authority_data" {
  type        = string
  description = "Base64 encoded certificate authority data for EKS cluster"
  sensitive   = true

  validation {
    condition     = can(base64decode(var.cluster_certificate_authority_data))
    error_message = "Certificate authority data must be valid base64 encoded data."
  }
}
