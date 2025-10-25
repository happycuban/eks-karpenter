provider "aws" {
  shared_credentials_files = var.credentials_file
  profile                  = var.profile
  region                   = var.region
}