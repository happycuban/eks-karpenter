terraform {
  backend "s3" {
    region       = "us-west-2"
    bucket       = "terraform-state-2025"
    key          = "demo/eks-karpenter/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}