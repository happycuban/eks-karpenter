###############################################################################
# EKS Outputs
###############################################################################
output "eks_cluster_info" {
  description = "Comprehensive EKS cluster information"
  value       = module.eks_karpenter.eks_cluster_info
  sensitive   = true
}
