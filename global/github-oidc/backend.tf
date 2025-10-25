terraform {
  required_version = ">= 1.0"

  backend "s3" {
    region       = "eu-central-1"
    bucket       = "github-terraform-state-2025"
    key          = "global/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}