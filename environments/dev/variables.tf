###############################################################################
# Variables
###############################################################################
variable "region" {
  type        = string
  description = "AWS region"
}

variable "bucket" {
  type        = string
  description = "S3 bucket for terraform state"
}

variable "github_repos" {
  type        = list(string)
  description = "GitHub repositories for OIDC integration"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "project_name" {
  type        = string
  description = "Project name for tagging"
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnet CIDR blocks"
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnet CIDR blocks"
}

variable "intra_subnets" {
  type        = list(string)
  description = "Intra subnet CIDR blocks"
}

variable "additional_allowed_ips" {
  type        = list(string)
  description = "Additional environment-specific IP addresses/CIDR blocks allowed to access AWS resources"
  default     = []
}

variable "domain_name" {
  type        = string
  description = "Domain name for external DNS records"
  default     = "happycuban-example.dk"
}

variable "subject_alternative_names" {
  type        = string
  description = "Subject Alternative Names for the certificate"
  default     = "*.happycuban-example.dk"
}

variable "restrict_cluster_access" {
  type        = bool
  description = "Enable IP restrictions for cluster access. When true, only allowed IPs can access the cluster. When false, all IPs are allowed."
  default     = false
}


