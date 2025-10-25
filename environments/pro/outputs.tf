###############################################################################
# S3 Outputs
###############################################################################
output "s3_bucket_name" {
  description = "Terraform state S3 bucket name"
  value       = module.s3.terraform_s3_bucket
}

###############################################################################
# EKS Outputs
###############################################################################
output "eks_cluster_info" {
  description = "Comprehensive EKS cluster information"
  value       = module.eks_karpenter.eks_cluster_info
  sensitive   = true
}
