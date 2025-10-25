###############################################################################
# EFS CSI Outputs
###############################################################################
output "efs_csi_role_arn" {
  description = "ARN of the EFS CSI pod identity IAM role"
  value       = aws_iam_role.efs_csi_pod_identity.arn
}

output "efs_csi_role_name" {
  description = "Name of the EFS CSI pod identity IAM role"
  value       = aws_iam_role.efs_csi_pod_identity.name
}

output "efs_csi_pod_identity_association_arn" {
  description = "ARN of the EFS CSI pod identity association"
  value       = aws_eks_pod_identity_association.efs_csi.association_arn
}

output "efs_csi_pod_identity_association_id" {
  description = "ID of the EFS CSI pod identity association"
  value       = aws_eks_pod_identity_association.efs_csi.association_id
}

output "efs_csi_addon_arn" {
  description = "ARN of the EFS CSI addon"
  value       = aws_eks_addon.efs_csi.arn
}

output "efs_csi_addon_version" {
  description = "Version of the EFS CSI addon"
  value       = aws_eks_addon.efs_csi.addon_version
}

###############################################################################
# EFS File System Outputs
###############################################################################
output "efs_file_system_id" {
  description = "ID of the EFS file system"
  value       = aws_efs_file_system.main.id
}

output "efs_file_system_arn" {
  description = "ARN of the EFS file system"
  value       = aws_efs_file_system.main.arn
}

output "efs_file_system_dns_name" {
  description = "DNS name of the EFS file system"
  value       = aws_efs_file_system.main.dns_name
}

output "efs_mount_target_ids" {
  description = "List of EFS mount target IDs"
  value       = aws_efs_mount_target.main[*].id
}

output "efs_mount_target_ips" {
  description = "List of EFS mount target IP addresses"
  value       = aws_efs_mount_target.main[*].ip_address
}

output "efs_security_group_id" {
  description = "ID of the security group for EFS mount targets"
  value       = aws_security_group.efs_mount_target.id
}

###############################################################################
# Access Point Outputs
###############################################################################
output "efs_access_point_ids" {
  description = "List of EFS access point IDs"
  value       = aws_efs_access_point.access_points[*].id
}

output "efs_access_point_arns" {
  description = "List of EFS access point ARNs"
  value       = aws_efs_access_point.access_points[*].arn
}

###############################################################################
# Storage Class Outputs
###############################################################################
output "storage_class_created" {
  description = "Whether the default storage class was created"
  value       = var.create_default_storage_class
}

output "storage_class_name" {
  description = "Name of the created EFS storage class"
  value       = var.create_default_storage_class ? var.storage_class_name : null
}

output "access_point_storage_class_name" {
  description = "Name of the access point storage class (if created)"
  value       = length(var.access_points) > 0 ? "${var.storage_class_name}-ap" : null
}

###############################################################################
# Encryption Outputs
###############################################################################
output "kms_key_used" {
  description = "KMS key ARN used for EFS encryption"
  value       = var.efs_csi_kms
  sensitive   = false
}

output "efs_encrypted" {
  description = "Whether the EFS file system is encrypted"
  value       = aws_efs_file_system.main.encrypted
}

###############################################################################
# Performance Configuration Outputs
###############################################################################
output "efs_performance_mode" {
  description = "Performance mode of the EFS file system"
  value       = aws_efs_file_system.main.performance_mode
}

output "efs_throughput_mode" {
  description = "Throughput mode of the EFS file system"
  value       = aws_efs_file_system.main.throughput_mode
}

output "efs_provisioned_throughput" {
  description = "Provisioned throughput in MiB/s (if applicable)"
  value       = aws_efs_file_system.main.provisioned_throughput_in_mibps
}