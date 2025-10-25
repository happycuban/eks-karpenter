###############################################################################
# S3 Outputs
###############################################################################
output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = module.s3.terraform_s3_bucket
}
