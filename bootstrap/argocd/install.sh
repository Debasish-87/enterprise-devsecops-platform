#!/bin/bash
# ============================================================
# ArgoCD Bootstrap Script
# Installs ArgoCD and registers the root GitOps application
# ============================================================
set -euo pipefail

ARGOCD_NAMESPACE="argocd"
REPO_URL="https://github.com/Debasish-87/enterprise-devsecops-platform.git"

echo "==> Creating ArgoCD namespace..."
kubectl create namespace "${ARGOCD_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "==> Installing ArgoCD..."
kubectl apply -n "${ARGOCD_NAMESPACE}" \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "==> Waiting for ArgoCD server to be ready..."
kubectl rollout status deployment/argocd-server \
  -n "${ARGOCD_NAMESPACE}" \
  --timeout=300s

echo "==> Patching ArgoCD server to disable TLS (for ALB termination)..."
kubectl patch deployment argocd-server \
  -n "${ARGOCD_NAMESPACE}" \
  --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--insecure"}]'

echo "==> Registering Root App of Apps..."
kubectl apply -f - <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: dev-root
  namespace: ${ARGOCD_NAMESPACE}
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: HEAD
    path: gitops-repo
  destination:
    server: https://kubernetes.default.svc
    namespace: ${ARGOCD_NAMESPACE}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
YAML

echo ""
echo "============================================================"
echo " ArgoCD Bootstrap Complete!"
echo " Get initial admin password:"
echo "   kubectl -n argocd get secret argocd-initial-admin-secret \\"
echo "     -o jsonpath='{.data.password}' | base64 -d"
echo "============================================================"
