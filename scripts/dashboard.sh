#!/usr/bin/env bash
# ============================================================
# Enterprise DevSecOps Platform
# Dashboard Launcher
# ============================================================

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/helpers.sh"

usage() {

cat <<EOF

Usage

dashboard.sh grafana
dashboard.sh argocd
dashboard.sh prometheus
dashboard.sh otel
dashboard.sh all

EOF

exit 1

}

[[ $# -lt 1 ]] && usage

TARGET="$1"

doctor() {

    require kubectl

    cluster_check

}

kill_port() {

    local PORT=$1

    if lsof -ti:$PORT >/dev/null 2>&1; then

        warning "Port $PORT already in use."

        lsof -ti:$PORT | xargs kill -9

        sleep 2

    fi

}

grafana() {

    title "Grafana Dashboard"

    kill_port 3000

    echo ""
    echo "URL : http://localhost:3000"
    echo ""

    kubectl port-forward \
        -n monitoring \
        svc/grafana \
        3000:80

}

argocd() {

    title "ArgoCD Dashboard"

    kill_port 8080

    echo ""
    echo "URL : https://localhost:8080"
    echo ""

    kubectl port-forward \
        -n argocd \
        svc/argocd-server \
        8080:443

}

prometheus() {

    title "Prometheus Dashboard"

    kill_port 9090

    echo ""
    echo "URL : http://localhost:9090"
    echo ""

    kubectl port-forward \
        -n monitoring \
        svc/prometheus-kube-prometheus-prometheus \
        9090:9090

}

otel() {

    title "OpenTelemetry Metrics"

    kill_port 8889

    echo ""
    echo "URL : http://localhost:8889"
    echo ""

    kubectl port-forward \
        -n observability \
        svc/opentelemetry-collector \
        8889:8889

}

all_dashboards() {

    title "Launching Dashboards"

    kill_port 3000
    kill_port 8080
    kill_port 9090

    kubectl port-forward \
        -n monitoring \
        svc/grafana \
        3000:80 >/dev/null 2>&1 &

    kubectl port-forward \
        -n argocd \
        svc/argocd-server \
        8080:443 >/dev/null 2>&1 &

    kubectl port-forward \
        -n monitoring \
        svc/prometheus-kube-prometheus-prometheus \
        9090:9090 >/dev/null 2>&1 &

    echo ""
    echo "Grafana    : http://localhost:3000"
    echo "ArgoCD     : https://localhost:8080"
    echo "Prometheus : http://localhost:9090"
    echo ""

    wait

}

doctor

case "$TARGET" in

grafana)
    grafana
;;

argocd)
    argocd
;;

prometheus)
    prometheus
;;

otel)
    otel
;;

all)
    all_dashboards
;;

*)
    usage
;;

esac