#!/usr/bin/env bash
# ============================================================
# Enterprise DevSecOps Platform
# Common Helper Functions
# ============================================================

set -Eeuo pipefail

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# ------------------------------------------------------------
# Icons
# ------------------------------------------------------------

OK="✔"
FAIL="✘"
INFO="➜"
WARN="⚠"

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------

title() {
    echo ""
    echo -e "${MAGENTA}=================================================${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${MAGENTA}=================================================${NC}"
}

section() {
    echo ""
    echo -e "${BLUE}[$INFO] $1${NC}"
}

success() {
    echo -e "${GREEN}[$OK] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$WARN] $1${NC}"
}

error() {
    echo -e "${RED}[$FAIL] $1${NC}"
}

info() {
    echo -e "${CYAN}$1${NC}"
}

# ------------------------------------------------------------
# Exit Handler
# ------------------------------------------------------------

die() {
    error "$1"
    exit 1
}

# ------------------------------------------------------------
# Command Checker
# ------------------------------------------------------------

require() {

    command -v "$1" >/dev/null 2>&1 \
        || die "$1 is not installed."

}

# ------------------------------------------------------------
# File Checker
# ------------------------------------------------------------

require_file() {

    [[ -f "$1" ]] || die "Missing file: $1"

}

# ------------------------------------------------------------
# Directory Checker
# ------------------------------------------------------------

require_dir() {

    [[ -d "$1" ]] || die "Missing directory: $1"

}

# ------------------------------------------------------------
# Run Command
# ------------------------------------------------------------

run() {

    info "$*"

    "$@"

}

# ------------------------------------------------------------
# Retry Command
# ------------------------------------------------------------

retry() {

    local retries=5

    local count=0

    until "$@"; do

        count=$((count+1))

        if [[ $count -ge $retries ]]; then
            die "Command failed after ${retries} attempts."
        fi

        warning "Retry ${count}/${retries}..."

        sleep 5

    done

}

# ------------------------------------------------------------
# Spinner
# ------------------------------------------------------------

spinner() {

    local pid=$!

    local delay=0.1

    local spin='|/-\'

    while ps -p $pid >/dev/null 2>&1; do

        for i in $(seq 0 3); do

            printf "\r[%c] Working..." "${spin:$i:1}"

            sleep $delay

        done

    done

    printf "\r"

}

# ------------------------------------------------------------
# Wait For Deployment
# ------------------------------------------------------------

wait_deployment() {

    local namespace=$1

    local deployment=$2

    section "Waiting for Deployment: ${deployment}"

    kubectl rollout status deployment/${deployment} \
        -n ${namespace} \
        --timeout=300s

}

# ------------------------------------------------------------
# Wait For Pods
# ------------------------------------------------------------

wait_pods() {

    local namespace=$1

    section "Waiting for Pods in ${namespace}"

    kubectl wait \
        --for=condition=Ready \
        pods \
        --all \
        -n ${namespace} \
        --timeout=300s

}

# ------------------------------------------------------------
# Namespace Exists
# ------------------------------------------------------------

namespace_exists() {

    kubectl get ns "$1" >/dev/null 2>&1

}

# ------------------------------------------------------------
# Resource Exists
# ------------------------------------------------------------

resource_exists() {

    kubectl get "$1" "$2" -n "$3" >/dev/null 2>&1

}

# ------------------------------------------------------------
# AWS Login Check
# ------------------------------------------------------------

aws_login() {

    aws sts get-caller-identity >/dev/null 2>&1 \
        || die "AWS authentication failed."

}

# ------------------------------------------------------------
# Kubernetes Check
# ------------------------------------------------------------

cluster_check() {

    kubectl cluster-info >/dev/null 2>&1 \
        || die "Kubernetes cluster unreachable."

}

# ------------------------------------------------------------
# Docker Check
# ------------------------------------------------------------

docker_check() {

    docker info >/dev/null 2>&1 \
        || die "Docker daemon is not running."

}

# ------------------------------------------------------------
# Confirm Prompt
# ------------------------------------------------------------

confirm() {

    read -rp "$1 (y/N): " ans

    case "$ans" in
        y|Y|yes|YES)
            return 0
            ;;
        *)
            return 1
            ;;
    esac

}

# ------------------------------------------------------------
# Banner
# ------------------------------------------------------------

banner() {

cat <<'EOF'

=========================================================
 Enterprise DevSecOps Platform
 Terraform | EKS | GitOps | ArgoCD | Kubernetes
=========================================================

EOF

}

# ------------------------------------------------------------
# Timer
# ------------------------------------------------------------

start_timer() {

    START_TIME=$(date +%s)

}

end_timer() {

    END_TIME=$(date +%s)

    ELAPSED=$((END_TIME-START_TIME))

    success "Completed in ${ELAPSED} seconds."

}

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

cleanup() {

    rm -f /tmp/*.tmp 2>/dev/null || true

}

trap cleanup EXIT