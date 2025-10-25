output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = module.github_oidc.github_actions_role_arn
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions IAM role"
  value       = module.github_oidc.github_actions_role_name
}

output "github_actions_policy_arn" {
  description = "ARN of the GitHub Actions IAM policy"
  value       = module.github_oidc.github_actions_policy_arn
}

output "github_actions_policy_name" {
  description = "Name of the GitHub Actions IAM policy"
  value       = module.github_oidc.github_actions_policy_name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = module.github_oidc.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "URL of the GitHub OIDC provider"
  value       = module.github_oidc.oidc_provider_url
}

output "configured_repos" {
  description = "List of GitHub repositories configured for OIDC access"
  value       = module.github_oidc.configured_repos
}

###############################################################################
# S3 Outputs
###############################################################################
output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = module.s3.terraform_s3_bucket
}
