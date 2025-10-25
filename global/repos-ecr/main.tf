###############################################################################
# Module: ECR
###############################################################################
module "ecr" {
  source = "../../modules/ecr"

  region       = var.region
  bucket       = var.bucket
  github_repos = var.github_repos
}
