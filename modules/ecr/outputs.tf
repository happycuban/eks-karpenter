output "repository_arns" {
  description = "ARNs of all ECR repositories"
  value       = { for k, v in module.ecr : k => v.repository_arn }
}

output "repository_urls" {
  description = "URLs of all ECR repositories"
  value       = { for k, v in module.ecr : k => v.repository_url }
}
