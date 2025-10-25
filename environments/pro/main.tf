###############################################################################
# Module: S3
###############################################################################
module "s3" {
  source = "../../modules/s3"

  region = var.region
  bucket = var.bucket
}

###############################################################################
# Module: ECR
###############################################################################
module "ecr" {
  source = "../../modules/ecr"

  region       = var.region
  bucket       = var.bucket
  github_repos = var.github_repos
}

###############################################################################
# Module: EKS Karpenter
###############################################################################
module "eks_karpenter" {
  source = "../../modules/eks-karpenter"

  region                    = var.region
  env                       = var.environment
  cluster_name              = var.cluster_name
  hosted_zone_id            = var.hosted_zone_id
  private_subnets           = var.private_subnets
  public_subnets            = var.public_subnets
  intra_subnets             = var.intra_subnets
  additional_allowed_ips    = var.additional_allowed_ips
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  restrict_cluster_access   = var.restrict_cluster_access
}

###############################################################################
# Module: KMS Key
###############################################################################
module "kms-key" {
  source = "../../modules/kms-key"

  region       = var.region
  env          = var.environment
  cluster_name = var.cluster_name
}

###############################################################################
# Module: EBS CSI
###############################################################################
module "ebs_csi" {
  source = "../../modules/ebs-csi"

  region                              = var.region
  env                                 = var.environment
  cluster_name                        = var.cluster_name
  ebs_csi_kms                         = module.kms-key.key_arn
  create_default_storage_class        = true
  cluster_endpoint                    = module.eks_karpenter.cluster_endpoint
  cluster_certificate_authority_data  = module.eks_karpenter.cluster_certificate_authority_data
}

