terraform {
  required_version = ">= 1.0"

  backend "s3" {
    region       = "eu-central-1"
    bucket       = "terraform-state-2025"
    key          = "global/github-oidc/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}