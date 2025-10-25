###############################################################################
# EBS CSI Outputs
###############################################################################
output "ebs_csi_role_arn" {
  description = "ARN of the EBS CSI pod identity IAM role"
  value       = aws_iam_role.ebs_csi_pod_identity.arn
}

output "ebs_csi_role_name" {
  description = "Name of the EBS CSI pod identity IAM role"
  value       = aws_iam_role.ebs_csi_pod_identity.name
}

output "ebs_csi_pod_identity_association_arn" {
  description = "ARN of the EBS CSI pod identity association"
  value       = aws_eks_pod_identity_association.ebs_csi.association_arn
}

output "ebs_csi_pod_identity_association_id" {
  description = "ID of the EBS CSI pod identity association"
  value       = aws_eks_pod_identity_association.ebs_csi.association_id
}

output "ebs_csi_addon_arn" {
  description = "ARN of the EBS CSI addon"
  value       = aws_eks_addon.ebs_csi.arn
}

output "ebs_csi_addon_version" {
  description = "Version of the EBS CSI addon"
  value       = aws_eks_addon.ebs_csi.addon_version
}

output "storage_class_created" {
  description = "Whether the default storage class was created"
  value       = var.create_default_storage_class
}

output "storage_class_name" {
  description = "Name of the created storage class"
  value       = var.create_default_storage_class ? var.storage_class_name : null
}

output "kms_key_used" {
  description = "KMS key ARN used for encryption"
  value       = var.ebs_csi_kms
  sensitive   = false
}