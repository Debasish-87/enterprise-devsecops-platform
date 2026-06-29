#!/usr/bin/env bash
# ============================================================
# Enterprise DevSecOps Platform
# Destroy Script
# ============================================================

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/helpers.sh"

TF_SCRIPT="${ROOT_DIR}/scripts/terraform.sh"

banner
title "Destroy Infrastructure"

doctor() {

    require kubectl
    require terraform
    require aws

    aws_login

}

warning_message() {

cat <<EOF

=========================================================
WARNING

This operation will destroy:

✔ EKS Cluster
✔ Node Groups
✔ VPC
✔ Subnets
✔ NAT Gateway
✔ Security Groups
✔ ECR
✔ IAM Resources
✔ Load Balancers
✔ ArgoCD Applications

THIS ACTION CANNOT BE UNDONE

=========================================================

EOF

}

confirm_destroy() {

    echo ""

    read -rp "Type DESTROY to continue: " ANSWER

    [[ "$ANSWER" == "DESTROY" ]] || {

        warning "Cancelled."

        exit 0

    }

}

delete_argocd_apps() {

    title "Removing ArgoCD Applications"

    if kubectl get ns argocd >/dev/null 2>&1; then

        kubectl delete applications \
            --all \
            -n argocd \
            --ignore-not-found=true

        success "Applications deleted"

    else

        warning "ArgoCD not installed"

    fi

}

delete_namespaces() {

    title "Deleting Namespaces"

    NAMESPACES=(

        rag
        monitoring
        grafana
        kyverno
        falco
        external-secrets
        trivy-system
        observability
        karpenter

    )

    for ns in "${NAMESPACES[@]}"
    do

        if kubectl get ns "$ns" >/dev/null 2>&1; then

            kubectl delete namespace "$ns" \
                --ignore-not-found=true \
                --wait=false

            success "$ns"

        fi

    done

}

delete_ingress() {

    title "Removing Ingress"

    kubectl delete ingress \
        --all \
        -A \
        --ignore-not-found=true || true

}

delete_services() {

    title "Removing LoadBalancer Services"

    kubectl get svc -A \
    | awk '$4=="LoadBalancer"{print $1,$2}' \
    | while read ns svc
    do

        kubectl delete svc "$svc" \
            -n "$ns"

    done

}

terraform_destroy() {

    title "Terraform Destroy"

    bash "$TF_SCRIPT" destroy

}

remove_kubeconfig() {

    title "Cleaning kubeconfig"

    CLUSTER="enterprise-devsecops-dev"

    kubectl config delete-context "$CLUSTER" \
        >/dev/null 2>&1 || true

    kubectl config delete-cluster "$CLUSTER" \
        >/dev/null 2>&1 || true

    kubectl config unset users."$CLUSTER" \
        >/dev/null 2>&1 || true

    success "kubeconfig cleaned"

}

docker_cleanup() {

    title "Docker Cleanup"

    docker image prune -f || true

    docker builder prune -f || true

}

summary() {

cat <<EOF

=========================================================

Infrastructure Destroyed

Verify

aws eks list-clusters

terraform state list

kubectl config get-contexts

=========================================================

EOF

}

main() {

    start_timer

    doctor

    warning_message

    confirm_destroy

    delete_argocd_apps

    delete_ingress

    delete_services

    delete_namespaces

    terraform_destroy

    remove_kubeconfig

    docker_cleanup

    end_timer

    summary

}

main "$@"