###############################################################################
# KMS Key Outputs
###############################################################################
output "key_arn" {
  description = "The Amazon Resource Name (ARN) of the key"
  value       = module.kms.key_arn
}

output "key_id" {
  description = "The globally unique identifier for the key"
  value       = module.kms.key_id
}

output "key_alias" {
  description = "The alias for the KMS key"
  value       = module.kms.aliases
}