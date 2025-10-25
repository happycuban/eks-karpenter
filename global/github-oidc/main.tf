###############################################################################
# Module: S3
###############################################################################
module "s3" {
  source = "../../modules/s3"

  region = var.region
  bucket = var.bucket
}

###############################################################################
# Module: GITHUB-OIDC
###############################################################################
module "github_oidc" {
  source = "../../modules/github-oidc-provider"

  region       = var.region
  bucket       = var.bucket
  github_repos = var.github_repos
}
