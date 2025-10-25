###############################################################################
# S3 Outputs
###############################################################################
output "s3_bucket_name" {
  description = "Terraform state S3 bucket name"
  value       = module.s3.terraform_s3_bucket
}

###############################################################################
# ECR Outputs
###############################################################################
output "ecr_repository_arns" {
  description = "ARNs of all ECR repositories"
  value       = module.ecr.repository_arns
}

output "ecr_repository_urls" {
  description = "URLs of all ECR repositories"
  value       = module.ecr.repository_urls
}

###############################################################################
# EKS Outputs
###############################################################################
output "eks_cluster_info" {
  description = "Comprehensive EKS cluster information"
  value       = module.eks_karpenter.eks_cluster_info
  sensitive   = true
}
