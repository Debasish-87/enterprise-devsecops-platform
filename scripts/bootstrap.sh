#!/usr/bin/env bash
# ============================================================
# Enterprise DevSecOps Platform
# Bootstrap Script
# ============================================================

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/scripts/helpers.sh"

ARGO_SCRIPT="${ROOT_DIR}/bootstrap/argocd/install.sh"

banner
title "Enterprise DevSecOps Bootstrap"

doctor() {

    section "Checking Requirements"

    require kubectl
    require helm
    require terraform
    require aws
    require git

    aws_login
    cluster_check

}

install_argocd() {

    title "Installing ArgoCD"

    require_file "$ARGO_SCRIPT"

    chmod +x "$ARGO_SCRIPT"

    bash "$ARGO_SCRIPT"

}

wait_argocd() {

    title "Waiting for ArgoCD"

    kubectl rollout status deployment/argocd-server \
        -n argocd \
        --timeout=600s

    kubectl wait \
        --for=condition=Ready \
        pod \
        --all \
        -n argocd \
        --timeout=600s

    success "ArgoCD Ready"

}

show_password() {

    title "ArgoCD Admin Password"

    PASSWORD=$(kubectl \
        -n argocd \
        get secret argocd-initial-admin-secret \
        -o jsonpath="{.data.password}" | base64 -d)

    echo ""
    echo "Username : admin"
    echo "Password : $PASSWORD"
    echo ""

}

sync_status() {

    title "GitOps Applications"

    kubectl get applications -n argocd || true

}

verify_platform() {

    title "Platform Status"

    kubectl get ns

    echo ""

    kubectl get pods -A

    echo ""

    kubectl get svc -A

    echo ""

    kubectl get ingress -A || true

}

verify_components() {

    title "Component Status"

    COMPONENTS=(
        argocd
        kube-system
        monitoring
        kyverno
        falco
        trivy-system
        external-secrets
        observability
        karpenter
    )

    for ns in "${COMPONENTS[@]}"
    do

        if kubectl get ns "$ns" >/dev/null 2>&1; then

            success "$ns"

        else

            warning "$ns not deployed yet"

        fi

    done

}

print_next_steps() {

cat <<EOF

========================================================

Bootstrap Completed

Next Commands

make verify

make health

make logs

make release

========================================================

EOF

}

main() {

    start_timer

    doctor

    install_argocd

    wait_argocd

    show_password

    sync_status

    verify_components

    verify_platform

    end_timer

    print_next_steps

}

main "$@"