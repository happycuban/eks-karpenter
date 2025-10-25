module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.0"

  for_each = toset(var.github_repos)

  repository_name = lower(each.key)

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus = "tagged",
          tagPatternList : ["v"]
          countType   = "imageCountMoreThan",
          countNumber = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}