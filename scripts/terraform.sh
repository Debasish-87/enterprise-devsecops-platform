#!/usr/bin/env bash
# ============================================================
# Enterprise DevSecOps Platform
# Terraform Helper Script
# ============================================================

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/scripts/helpers.sh"

TF_DIR="${ROOT_DIR}/terraform-infra/environments/dev"

AWS_REGION="ap-south-1"

export TF_IN_AUTOMATION=true
export AWS_REGION

banner

usage() {
cat <<EOF

Usage:

terraform.sh init
terraform.sh fmt
terraform.sh validate
terraform.sh plan
terraform.sh apply
terraform.sh destroy
terraform.sh output
terraform.sh refresh
terraform.sh graph
terraform.sh clean

EOF
}

check_directory() {

    require_dir "$TF_DIR"

}

terraform_init() {

    title "Terraform Init"

    cd "$TF_DIR"

    terraform init

}

terraform_fmt() {

    title "Terraform Format"

    cd "$TF_DIR"

    terraform fmt -recursive

}

terraform_validate() {

    title "Terraform Validate"

    cd "$TF_DIR"

    terraform validate

}

terraform_plan() {

    title "Terraform Plan"

    cd "$TF_DIR"

    terraform plan \
        -var="aws_region=${AWS_REGION}"

}

terraform_apply() {

    title "Terraform Apply"

    cd "$TF_DIR"

    terraform apply \
        -auto-approve \
        -var="aws_region=${AWS_REGION}"

}

terraform_destroy() {

    title "Terraform Destroy"

    if ! confirm "Destroy Infrastructure?"; then
        warning "Cancelled."
        exit 0
    fi

    cd "$TF_DIR"

    terraform destroy \
        -auto-approve \
        -var="aws_region=${AWS_REGION}"

}

terraform_output() {

    title "Terraform Outputs"

    cd "$TF_DIR"

    terraform output

}

terraform_refresh() {

    title "Terraform Refresh"

    cd "$TF_DIR"

    terraform refresh

}

terraform_graph() {

    title "Terraform Graph"

    cd "$TF_DIR"

    terraform graph > graph.dot

    if command -v dot >/dev/null; then

        dot -Tpng graph.dot -o graph.png

        success "graph.png generated"

    else

        warning "Install graphviz to generate image"

    fi

}

terraform_clean() {

    title "Terraform Cleanup"

    find "$ROOT_DIR" -type d -name ".terraform" \
        -exec rm -rf {} +

    find "$ROOT_DIR" -name "*.tfplan" \
        -delete

    find "$ROOT_DIR" -name ".terraform.lock.hcl" \
        -delete

    success "Terraform cache removed."

}

terraform_state() {

    title "Terraform State"

    cd "$TF_DIR"

    terraform state list || true

}

terraform_providers() {

    title "Terraform Providers"

    cd "$TF_DIR"

    terraform providers

}

terraform_workspace() {

    title "Terraform Workspace"

    cd "$TF_DIR"

    terraform workspace show

}

terraform_version() {

    title "Terraform Version"

    terraform version

}

doctor() {

    require terraform

    require aws

    aws_login

    check_directory

}

main() {

    [[ $# -eq 0 ]] && usage && exit 1

    doctor

    start_timer

    case "$1" in

        init)
            terraform_init
            ;;

        fmt)
            terraform_fmt
            ;;

        validate)
            terraform_validate
            ;;

        plan)
            terraform_plan
            ;;

        apply)
            terraform_apply
            ;;

        destroy)
            terraform_destroy
            ;;

        output)
            terraform_output
            ;;

        refresh)
            terraform_refresh
            ;;

        graph)
            terraform_graph
            ;;

        state)
            terraform_state
            ;;

        providers)
            terraform_providers
            ;;

        workspace)
            terraform_workspace
            ;;

        version)
            terraform_version
            ;;

        clean)
            terraform_clean
            ;;

        *)
            usage
            exit 1
            ;;

    esac

    end_timer

}

main "$@"