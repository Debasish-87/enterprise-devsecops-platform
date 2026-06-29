#!/usr/bin/env bash
# ============================================================
# Enterprise DevSecOps Platform
# Verification Script
# ============================================================

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/scripts/helpers.sh"

FAILED=0

banner
title "Platform Verification"

# ------------------------------------------------------------
# Generic Verification Function
# ------------------------------------------------------------

verify_namespace() {

    local ns=$1

    if kubectl get namespace "$ns" >/dev/null 2>&1; then

        success "Namespace [$ns]"

    else

        error "Namespace [$ns] Missing"

        FAILED=1

    fi

}

verify_pods() {

    local ns=$1

    section "Checking Pods : $ns"

    if ! kubectl get namespace "$ns" >/dev/null 2>&1; then

        warning "$ns namespace not found"

        FAILED=1

        return

    fi

    kubectl get pods -n "$ns"

    NOT_READY=$(kubectl get pods -n "$ns" \
        --no-headers 2>/dev/null | \
        awk '$2!=$3')

    if [[ -z "$NOT_READY" ]]; then

        success "All Pods Ready"

    else

        error "Pods Not Ready"

        echo "$NOT_READY"

        FAILED=1

    fi

}

verify_deployment() {

    local ns=$1

    local deploy=$2

    if kubectl get deployment "$deploy" -n "$ns" >/dev/null 2>&1; then

        READY=$(kubectl get deployment "$deploy" \
            -n "$ns" \
            -o jsonpath='{.status.readyReplicas}')

        DESIRED=$(kubectl get deployment "$deploy" \
            -n "$ns" \
            -o jsonpath='{.status.replicas}')

        success "$deploy [$READY/$DESIRED]"

    else

        error "$deploy Missing"

        FAILED=1

    fi

}

verify_service() {

    local ns=$1

    local svc=$2

    if kubectl get svc "$svc" -n "$ns" >/dev/null 2>&1; then

        success "Service [$svc]"

    else

        error "Service [$svc] Missing"

        FAILED=1

    fi

}

verify_ingress() {

    local ns=$1

    local ingress=$2

    if kubectl get ingress "$ingress" -n "$ns" >/dev/null 2>&1; then

        success "Ingress [$ingress]"

    else

        warning "Ingress [$ingress] Missing"

    fi

}

verify_hpa() {

    if kubectl get hpa -A >/dev/null 2>&1; then

        success "HPA Found"

        kubectl get hpa -A

    else

        warning "No HPA"

    fi

}

verify_pdb() {

    if kubectl get pdb -A >/dev/null 2>&1; then

        success "PDB Found"

        kubectl get pdb -A

    else

        warning "No PDB"

    fi

}

verify_nodes() {

    title "Cluster"

    kubectl get nodes -o wide

}

verify_argocd() {

    title "ArgoCD"

    verify_namespace argocd

    verify_pods argocd

    verify_deployment argocd argocd-server

}

verify_platform() {

    title "Platform Components"

    COMPONENTS=(

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

        verify_namespace "$ns"

        verify_pods "$ns"

    done

}

verify_application() {

    title "Application"

    verify_namespace rag

    verify_pods rag

    verify_deployment rag rag-document-qa

    verify_service rag rag-service

    verify_ingress rag rag-ingress

}

verify_storage() {

    title "Persistent Volumes"

    kubectl get pvc -A || true

}

verify_secret() {

    title "Secrets"

    kubectl get secret -n rag rag-secret >/dev/null 2>&1 \
        && success "rag-secret"

}

verify_metrics() {

    title "Metrics"

    kubectl top nodes || true

    echo ""

    kubectl top pods -A || true

}

summary() {

    title "Summary"

    if [[ "$FAILED" -eq 0 ]]; then

        success "Verification Successful"

    else

        error "Verification Failed"

        exit 1

    fi

}

# ============================================================

start_timer

doctor() {

    require kubectl

    cluster_check

}

doctor

verify_nodes

verify_argocd

verify_platform

verify_application

verify_hpa

verify_pdb

verify_storage

verify_secret

verify_metrics

summary

end_timer