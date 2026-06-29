#!/usr/bin/env bash
# ============================================================
# Enterprise DevSecOps Platform
# Logs Utility
# ============================================================

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/helpers.sh"

LINES=200

usage() {

cat <<EOF

Usage:

logs.sh argocd
logs.sh rag
logs.sh alb
logs.sh external-secrets
logs.sh prometheus
logs.sh grafana
logs.sh kyverno
logs.sh falco
logs.sh trivy
logs.sh otel
logs.sh karpenter
logs.sh all

Optional

logs.sh rag 500

EOF

exit 1

}

[[ $# -lt 1 ]] && usage

COMPONENT="$1"

[[ $# -ge 2 ]] && LINES="$2"

doctor() {

    require kubectl

    cluster_check

}

get_logs() {

    local namespace="$1"

    local selector="$2"

    section "Namespace : ${namespace}"

    POD=$(kubectl get pods \
        -n "${namespace}" \
        -l "${selector}" \
        -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [[ -z "$POD" ]]; then

        warning "No pod found."

        return

    fi

    success "$POD"

    kubectl logs \
        -n "${namespace}" \
        "$POD" \
        --tail="${LINES}" \
        -f

}

case "$COMPONENT" in

argocd)

    doctor

    get_logs argocd app.kubernetes.io/name=argocd-server

;;

rag)

    doctor

    get_logs rag app=rag-document-qa

;;

alb)

    doctor

    get_logs kube-system app.kubernetes.io/name=aws-load-balancer-controller

;;

external-secrets)

    doctor

    get_logs external-secrets app.kubernetes.io/name=external-secrets

;;

prometheus)

    doctor

    get_logs monitoring app.kubernetes.io/name=prometheus

;;

grafana)

    doctor

    get_logs monitoring app.kubernetes.io/name=grafana

;;

kyverno)

    doctor

    get_logs kyverno app.kubernetes.io/name=kyverno

;;

falco)

    doctor

    get_logs falco app.kubernetes.io/name=falco

;;

trivy)

    doctor

    get_logs trivy-system app.kubernetes.io/name=trivy-operator

;;

otel)

    doctor

    get_logs observability app.kubernetes.io/name=opentelemetry-collector

;;

karpenter)

    doctor

    get_logs karpenter app.kubernetes.io/name=karpenter

;;

all)

    doctor

    kubectl get pods -A

;;

*)

    usage

;;

esac