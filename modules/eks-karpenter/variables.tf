###############################################################################
# Environment Variables
###############################################################################
variable "region" {
  type        = string
  description = "AWS region where the EKS cluster will be created"

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
  description = "Name of the EKS cluster"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.cluster_name))
    error_message = "Cluster name must start and end with alphanumeric characters and can contain hyphens."
  }
}

variable "hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for DNS management"

  validation {
    condition     = can(regex("^Z[A-Z0-9]+$", var.hosted_zone_id))
    error_message = "Hosted zone ID must be a valid Route53 zone ID format (starts with Z followed by alphanumeric characters)."
  }
}

###############################################################################
# VPC Subnet Configuration
###############################################################################
variable "private_subnets" {
  type        = list(string)
  description = "Private subnet CIDR blocks for EKS worker nodes"

  validation {
    condition     = length(var.private_subnets) >= 2
    error_message = "At least 2 private subnets are required for EKS high availability."
  }

  validation {
    condition = alltrue([
      for cidr in var.private_subnets : can(cidrhost(cidr, 0))
    ])
    error_message = "All private subnet values must be valid CIDR blocks."
  }
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnet CIDR blocks for load balancers"

  validation {
    condition     = length(var.public_subnets) >= 2
    error_message = "At least 2 public subnets are required for load balancer high availability."
  }

  validation {
    condition = alltrue([
      for cidr in var.public_subnets : can(cidrhost(cidr, 0))
    ])
    error_message = "All public subnet values must be valid CIDR blocks."
  }
}

variable "intra_subnets" {
  type        = list(string)
  description = "Intra subnet CIDR blocks for internal services"

  validation {
    condition = alltrue([
      for cidr in var.intra_subnets : can(cidrhost(cidr, 0))
    ])
    error_message = "All intra subnet values must be valid CIDR blocks."
  }
}

###############################################################################
# Security Configuration
###############################################################################
variable "base_allowed_ips" {
  type        = list(string)
  description = "Base IP addresses/CIDR blocks allowed to access AWS resources (defined in module)"
  default = []

  validation {
    condition = alltrue([
      for ip in var.base_allowed_ips : can(cidrhost(ip, 0))
    ])
    error_message = "All base allowed IPs must be valid CIDR blocks (e.g., 1.2.3.4/32 for single IP or 1.2.3.0/24 for subnet)."
  }
}

variable "additional_allowed_ips" {
  type        = list(string)
  description = "Additional environment-specific IP addresses/CIDR blocks allowed to access AWS resources"
  default     = []

  validation {
    condition = alltrue([
      for ip in var.additional_allowed_ips : can(cidrhost(ip, 0))
    ])
    error_message = "All additional allowed IPs must be valid CIDR blocks (e.g., 1.2.3.4/32 for single IP or 1.2.3.0/24 for subnet)."
  }
}

variable "restrict_cluster_access" {
  type        = bool
  description = "Enable IP restrictions for cluster access. When true, only allowed IPs can access the cluster. When false, all IPs are allowed."
  default     = false
}

###############################################################################
# DNS Configuration
###############################################################################
variable "domain_name" {
  type        = string
  description = "Domain name for external DNS records (e.g., happycuban-example.dk)"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$", var.domain_name))
    error_message = "Domain name must be a valid domain format (e.g., happycuban-example.dk, sub.happycuban-example.dk)."
  }
}

variable "subject_alternative_names" {
  description = "(Optional) FQDN to create the certificate for Traefik and Route53 record"
  type        = string
}


