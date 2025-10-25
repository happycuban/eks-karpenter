data "aws_iam_policy_document" "aws_lbc" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "aws_lbc" {
  name               = "example-${module.eks.cluster_name}-lbc"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc.json
}

resource "aws_iam_policy" "aws_lbc" {
  policy = file("${path.module}/iam/AWSLoadBalancerController.json")
  name   = "AWSLoadBalancerController"
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  policy_arn = aws_iam_policy.aws_lbc.arn
  role       = aws_iam_role.aws_lbc.name
}

resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_lbc.arn
}

resource "helm_release" "aws_lbc" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.13.4"

  set = [
    {
      name  = "clusterName"
      value = module.eks.cluster_name
      }, {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
      }, {
      name  = "replicaCount"
      value = 1
      }, {
      name  = "resources.requests.cpu"
      value = "100m"
      }, {
      name  = "resources.requests.memory"
      value = "128Mi"
      }, {
      name  = "resources.limits.cpu"
      value = "100m"
      }, {
      name  = "resources.limits.memory"
      value = "128Mi"
      }, {
      name  = "tolerations[0].key"
      value = "CriticalAddonsOnly"
      }, {
      name  = "tolerations[0].operator"
      value = "Exists"
      }, {
      name  = "tolerations[0].effect"
      value = "NoSchedule"
      }, {
      name  = "vpcId"
      value = module.vpc.vpc_id
  }]

  # Idempotent behavior: If release exists, this will upgrade it
  # If it doesn't exist, this will install it
  atomic          = true
  cleanup_on_fail = true

  depends_on = [
    helm_release.karpenter
  ]
}