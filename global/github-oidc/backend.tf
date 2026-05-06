terraform {
  required_version = ">= 1.0"

  # Configure with: terraform init -backend-config=backend.hcl
  backend "s3" {}
}
