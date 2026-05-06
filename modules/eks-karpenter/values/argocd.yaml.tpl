---
configs:
  params:
    server.insecure: true
  cmd:
    server.additional.args:
      - --insecure

server:
  # Use ClusterIP since we're using Traefik IngressRoute
  service:
    type: ClusterIP
  
  # Configure ArgoCD to work behind Traefik proxy
  config:
    url: https://argocd.${domain_name}
    application.instanceLabelKey: argocd.argoproj.io/instance
  
  # Additional server configuration for proxy
  extraArgs:
    - --insecure
