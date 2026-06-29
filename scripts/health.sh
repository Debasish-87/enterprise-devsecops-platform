#!/usr/bin/env bash
# ============================================================
# Enterprise DevSecOps Platform
# Health Check Script
# ============================================================

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/scripts/helpers.sh"

FAILED=0

banner
title "Cluster Health Check"

doctor() {

    require kubectl

    cluster_check

}

cluster_info() {

    title "Cluster Information"

    kubectl cluster-info

    echo ""

    kubectl version --short || true

}

node_health() {

    title "Nodes"

    kubectl get nodes -o wide

    echo ""

    kubectl top nodes || true

}

pod_health() {

    title "Pods"

    kubectl get pods -A

    echo ""

    NOT_READY=$(kubectl get pods -A --no-headers | awk '$4!="Running" && $4!="Completed"')

    if [[ -z "$NOT_READY" ]]; then

        success "All Pods Healthy"

    else

        warning "Some Pods Need Attention"

        echo "$NOT_READY"

    fi

}

deployment_health() {

    title "Deployments"

    kubectl get deployment -A

}

service_health() {

    title "Services"

    kubectl get svc -A

}

ingress_health() {

    title "Ingress"

    kubectl get ingress -A || true

}

hpa_health() {

    title "Horizontal Pod Autoscaler"

    kubectl get hpa -A || true

}

pdb_health() {

    title "Pod Disruption Budget"

    kubectl get pdb -A || true

}

namespace_health() {

    title "Namespaces"

    kubectl get ns

}

storage_health() {

    title "Persistent Volumes"

    kubectl get pv || true

    echo ""

    kubectl get pvc -A || true

}

secret_health() {

    title "External Secrets"

    kubectl get externalsecret -A 2>/dev/null || true

}

event_health() {

    title "Recent Events"

    kubectl get events -A \
        --sort-by=.metadata.creationTimestamp \
        | tail -30 || true

}

resource_usage() {

    title "Resource Usage"

    kubectl top nodes || true

    echo ""

    kubectl top pods -A || true

}

argocd_health() {

    title "ArgoCD"

    kubectl get pods -n argocd

    echo ""

    kubectl get applications -n argocd 2>/dev/null || true

}

rag_health() {

    title "RAG Application"

    kubectl get deployment -n rag

    echo ""

    kubectl get svc -n rag

    echo ""

    kubectl get ingress -n rag || true

}

system_health() {

    title "System Components"

    COMPONENTS=(
        argocd
        monitoring
        kyverno
        falco
        external-secrets
        trivy-system
        observability
        karpenter
    )

    for ns in "${COMPONENTS[@]}"
    do

        if kubectl get ns "$ns" >/dev/null 2>&1; then

            READY=$(kubectl get pods -n "$ns" \
                --no-headers 2>/dev/null | \
                grep Running | wc -l)

            TOTAL=$(kubectl get pods -n "$ns" \
                --no-headers 2>/dev/null | wc -l)

            printf "%-25s %s/%s Ready\n" "$ns" "$READY" "$TOTAL"

        fi

    done

}

summary() {

    title "Health Summary"

    echo ""

    kubectl get nodes

    echo ""

    kubectl get pods -A | tail -10

    echo ""

    kubectl get ingress -A || true

    echo ""

    kubectl get hpa -A || true

    echo ""

    success "Health Check Completed"

}

start_timer

doctor

cluster_info

namespace_health

node_health

resource_usage

pod_health

deployment_health

service_health

ingress_health

hpa_health

pdb_health

storage_health

secret_health

argocd_health

rag_health

system_health

event_health

summary

end_timer