#!/usr/bin/env bash
# ============================================================
# Enterprise DevSecOps Platform
# Cleanup Script
# ============================================================

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/helpers.sh"

banner
title "Cleanup"

doctor() {

    require find
    require rm

}

terraform_cleanup() {

    section "Terraform"

    find "$ROOT_DIR" -type d -name ".terraform" -exec rm -rf {} +

    find "$ROOT_DIR" -name ".terraform.lock.hcl" -delete

    find "$ROOT_DIR" -name "*.tfplan" -delete

    find "$ROOT_DIR" -name "*.tfstate.backup" -delete

    success "Terraform cache removed"

}

docker_cleanup() {

    section "Docker"

    if command -v docker >/dev/null 2>&1; then

        docker image prune -f || true

        docker container prune -f || true

        docker network prune -f || true

        docker builder prune -f || true

        success "Docker cache cleaned"

    else

        warning "Docker not installed"

    fi

}

kubernetes_cleanup() {

    section "Kubernetes"

    kubectl delete pod \
        --field-selector=status.phase==Succeeded \
        -A \
        --ignore-not-found=true || true

    kubectl delete pod \
        --field-selector=status.phase==Failed \
        -A \
        --ignore-not-found=true || true

    success "Completed/Failed Pods removed"

}

logs_cleanup() {

    section "Logs"

    find "$ROOT_DIR" \
        -type f \
        \( \
        -name "*.log" \
        -o -name "*.tmp" \
        -o -name "*.bak" \
        -o -name "*.old" \
        \) \
        -delete

    success "Logs removed"

}

reports_cleanup() {

    section "Reports"

    find "$ROOT_DIR" \
        -type f \
        \( \
        -name "*.sarif" \
        -o -name "*.out" \
        -o -name "*.report" \
        -o -name "*.json" \
        \) \
        -delete

    success "Reports removed"

}

graph_cleanup() {

    section "Terraform Graph"

    find "$ROOT_DIR" \
        -type f \
        \( \
        -name "graph.dot" \
        -o -name "graph.png" \
        \) \
        -delete

}

python_cleanup() {

    section "Python"

    find "$ROOT_DIR" \
        -type d \
        -name "__pycache__" \
        -exec rm -rf {} +

    find "$ROOT_DIR" \
        -name "*.pyc" \
        -delete

    success "Python cache removed"

}

git_cleanup() {

    section "Git"

    git clean -fdX

    success "Ignored files removed"

}

summary() {

    title "Cleanup Finished"

    du -sh "$ROOT_DIR" || true

}

main() {

    start_timer

    doctor

    terraform_cleanup

    docker_cleanup

    kubernetes_cleanup

    logs_cleanup

    reports_cleanup

    graph_cleanup

    python_cleanup

    git_cleanup

    summary

    end_timer

}

main "$@"