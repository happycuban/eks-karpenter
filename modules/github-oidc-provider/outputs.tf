output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions.name
}

output "github_actions_policy_arn" {
  description = "ARN of the GitHub Actions IAM policy"
  value       = aws_iam_policy.github_actions.arn
}

output "github_actions_policy_name" {
  description = "Name of the GitHub Actions IAM policy"
  value       = aws_iam_policy.github_actions.name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "oidc_provider_url" {
  description = "URL of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.url
}

output "configured_repos" {
  description = "List of GitHub repositories configured for OIDC access"
  value       = var.github_repos
}
