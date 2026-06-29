#!/usr/bin/env bash
# ============================================================
# Enterprise DevSecOps Platform
# Doctor Script
# Checks local environment before deployment
# ============================================================

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/helpers.sh"

banner
title "DevSecOps Environment Doctor"

FAILED=0

check_command() {
    local cmd="$1"

    if command -v "$cmd" >/dev/null 2>&1; then
        success "$cmd installed"
    else
        error "$cmd NOT installed"
        FAILED=1
    fi
}

check_aws() {

    section "AWS Authentication"

    if aws sts get-caller-identity >/dev/null 2>&1; then
        ACCOUNT=$(aws sts get-caller-identity \
            --query Account \
            --output text)

        USER=$(aws sts get-caller-identity \
            --query Arn \
            --output text)

        success "Authenticated"

        info "Account : $ACCOUNT"
        info "Identity: $USER"

    else

        error "AWS Login Failed"

        FAILED=1

    fi
}

check_docker() {

    section "Docker"

    if docker info >/dev/null 2>&1; then

        VERSION=$(docker --version)

        success "$VERSION"

    else

        error "Docker daemon not running"

        FAILED=1

    fi

}

check_kubernetes() {

    section "Kubernetes"

    if kubectl cluster-info >/dev/null 2>&1; then

        success "Cluster Reachable"

        kubectl get nodes -o wide

    else

        warning "Cluster not configured"

    fi

}

check_metrics() {

    section "Metrics Server"

    kubectl top nodes >/dev/null 2>&1 \
        && success "Metrics Server OK" \
        || warning "Metrics Server unavailable"

}

check_terraform() {

    section "Terraform"

    terraform version

}

check_git() {

    section "Git"

    BRANCH=$(git rev-parse --abbrev-ref HEAD)

    COMMIT=$(git rev-parse --short HEAD)

    success "Branch : $BRANCH"

    success "Commit : $COMMIT"

}

check_disk() {

    section "Disk Usage"

    df -h .

}

check_memory() {

    section "Memory"

    free -h 2>/dev/null || vm_stat || true

}

check_network() {

    section "Internet"

    curl -Is https://github.com >/dev/null \
        && success "GitHub Reachable" \
        || warning "GitHub Unreachable"

}

check_tools() {

    title "Required Tools"

    check_command aws
    check_command terraform
    check_command kubectl
    check_command helm
    check_command docker
    check_command git
    check_command jq
    check_command curl

}

check_versions() {

    title "Versions"

    aws --version || true
    terraform version || true
    kubectl version --client || true
    helm version || true
    docker --version || true
    git --version || true

}

summary() {

    title "Summary"

    if [[ "$FAILED" -eq 0 ]]; then

        success "Environment Ready"

    else

        error "Environment NOT Ready"

        exit 1

    fi

}

# ============================================================
# Execution
# ============================================================

start_timer

check_tools

check_versions

check_aws

check_docker

check_kubernetes

check_metrics

check_terraform

check_git

check_disk

check_memory

check_network

summary

end_timer