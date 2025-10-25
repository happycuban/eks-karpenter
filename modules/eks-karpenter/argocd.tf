###############################################################################
# INSTALL ARGOCD USING HELM
# Idempotent: Works whether ArgoCD exists or not
###############################################################################

resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "8.5.8"

  values = [file("${path.module}/values/argocd.yaml")]

  depends_on = [
    helm_release.traefik
  ]

  # Idempotent behavior: If release exists, this will upgrade it
  # If it doesn't exist, this will install it
  atomic          = true
  cleanup_on_fail = true
}

###############################################################################
# ARGOCD TRAEFIK INGRESSROUTE
###############################################################################
resource "kubectl_manifest" "argocd-ingressroute" {
  provider  = kubectl.alekc
  yaml_body = <<-YAML
    apiVersion: traefik.io/v1alpha1
    kind: IngressRoute
    metadata:
      name: example-argocd-ingress
      annotations:
        kubernetes.io/ingress.class: traefik
        # external-dns.alpha.kubernetes.io/hostname: example-argocd.happycuban-example.dk
      namespace: argocd
      labels:
        app.kubernetes.io/name: traefik
        app.kubernetes.io/instance: traefik
        app.kubernetes.io/managed-by: terraform
    spec:
      entryPoints:
        - web
        - websecure
      routes:
        - match: Host(`example-argocd.${var.domain_name}`)
          kind: Rule
          middlewares:
            - name: admin-ip-whitelist
              namespace: kube-system
            - name: http-to-https
              namespace: argocd
          services:
            - name: argocd-server
              port: 80
  YAML

  depends_on = [
    helm_release.argocd,
    helm_release.traefik,
    kubectl_manifest.traefik-default-certificate-tls
  ]
}

###############################################################################
# ARGOCD HTTP TO HTTPS REDIRECT MIDDLEWARE
###############################################################################
resource "kubectl_manifest" "argocd-http-to-https" {
  provider  = kubectl.alekc
  yaml_body = <<-YAML
    apiVersion: traefik.io/v1alpha1
    kind: Middleware
    metadata:
      name: http-to-https
      namespace: argocd
    spec:
      redirectScheme:
        scheme: https
        permanent: true
  YAML

  depends_on = [helm_release.argocd]
}