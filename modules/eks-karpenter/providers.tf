provider "aws" {
  region = var.region
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    # token                  = data.aws_eks_cluster_auth.eks.token
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.region]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  alias                  = "alekc"
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false
  # token                  = data.aws_eks_cluster_auth.eks.token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.region]
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  # token                  = data.aws_eks_cluster_auth.eks.token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.region]
  }
}

terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.53"
    }
    #kubectl = {
    # source  = "gavinbunney/kubectl"
    #  version = "~> 1.19"
    #}
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.1.3"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}