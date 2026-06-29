#!/usr/bin/env bash
# ============================================================
# Enterprise DevSecOps Platform
# Release Script
# ============================================================

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/scripts/helpers.sh"

DEFAULT_BRANCH="main"

banner
title "Release"

doctor() {

    require git
    require docker

}

check_branch() {

    section "Checking Branch"

    BRANCH=$(git rev-parse --abbrev-ref HEAD)

    if [[ "$BRANCH" != "$DEFAULT_BRANCH" ]]; then
        warning "Current Branch : $BRANCH"
        confirm "Continue?" || exit 1
    else
        success "Branch : $BRANCH"
    fi

}

check_changes() {

    section "Checking Changes"

    if git diff --quiet && git diff --cached --quiet; then
        warning "Nothing to commit."
        exit 0
    fi

    git status --short

}

run_checks() {

    section "Running Validation"

    if [[ -f "${ROOT_DIR}/scripts/doctor.sh" ]]; then
        bash "${ROOT_DIR}/scripts/doctor.sh"
    fi

    if [[ -f "${ROOT_DIR}/scripts/terraform.sh" ]]; then
        bash "${ROOT_DIR}/scripts/terraform.sh" fmt
        bash "${ROOT_DIR}/scripts/terraform.sh" validate
    fi

}

git_add() {

    section "Git Add"

    git add .

}

git_commit() {

    section "Commit"

    read -rp "Commit Message : " MESSAGE

    if [[ -z "$MESSAGE" ]]; then
        die "Commit message cannot be empty."
    fi

    git commit -m "$MESSAGE"

}

git_push() {

    section "Push"

    git push origin "$DEFAULT_BRANCH"

}

print_summary() {

cat <<EOF

========================================================

Release Successful

Repository : $(git remote get-url origin)

Branch     : $(git rev-parse --abbrev-ref HEAD)

Commit     : $(git rev-parse --short HEAD)

========================================================

GitHub Actions will now automatically:

✔ Lint
✔ Checkov Scan
✔ Docker Build
✔ Trivy Scan
✔ Push Image to ECR
✔ Update GitOps Manifest
✔ Trigger ArgoCD Deployment

========================================================

EOF

}

main() {

    start_timer

    doctor

    check_branch

    check_changes

    run_checks

    git_add

    git_commit

    git_push

    end_timer

    print_summary

}

main "$@"