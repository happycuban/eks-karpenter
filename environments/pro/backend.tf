###############################################################################
# Terraform Backend Configuration
###############################################################################
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket       = "terraform-state-2025"
    key          = "pro/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}
