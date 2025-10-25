###############################################################################
# Admin IP Whitelist Middleware
###############################################################################
resource "kubectl_manifest" "admin_ip_whitelist" {
  provider  = kubectl.alekc
  yaml_body = <<-YAML
    apiVersion: traefik.io/v1alpha1
    kind: Middleware
    metadata:
      name: admin-ip-whitelist
      namespace: kube-system
      labels:
        app.kubernetes.io/managed-by: terraform
    spec:
      ipWhiteList:
        sourceRange:
%{for ip in local.allowed_ips~}
          - "${ip}"
%{endfor~}
  YAML

  depends_on = [helm_release.traefik]
}