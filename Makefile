# ==========================================================
# Enterprise DevSecOps Platform - Makefile
# ==========================================================

SHELL := /bin/bash

AWS_REGION := ap-south-1
TF_DIR := terraform-infra/environments/dev
BOOTSTRAP := bootstrap/argocd/install.sh

.DEFAULT_GOAL := help

GREEN=\033[0;32m
RED=\033[0;31m
YELLOW=\033[1;33m
BLUE=\033[0;34m
NC=\033[0m

# ==========================================================
# HELP
# ==========================================================

help:
	@echo ""
	@echo "$(GREEN)Enterprise DevSecOps Platform$(NC)"
	@echo ""
	@echo "Infrastructure"
	@echo "  make doctor"
	@echo "  make init"
	@echo "  make fmt"
	@echo "  make validate"
	@echo "  make plan"
	@echo "  make apply"
	@echo "  make destroy"
	@echo ""
	@echo "Kubernetes"
	@echo "  make kubeconfig"
	@echo "  make bootstrap"
	@echo "  make pods"
	@echo "  make nodes"
	@echo "  make services"
	@echo "  make ingress"
	@echo "  make health"
	@echo "  make logs"
	@echo ""
	@echo "Git"
	@echo "  make status"
	@echo "  make release"
	@echo ""

# ==========================================================
# DOCTOR
# ==========================================================

doctor:
	@echo "$(BLUE)Checking tools...$(NC)"
	@command -v aws >/dev/null || (echo "AWS CLI Missing" && exit 1)
	@command -v terraform >/dev/null || (echo "Terraform Missing" && exit 1)
	@command -v kubectl >/dev/null || (echo "Kubectl Missing" && exit 1)
	@command -v helm >/dev/null || (echo "Helm Missing" && exit 1)
	@command -v docker >/dev/null || (echo "Docker Missing" && exit 1)
	@command -v git >/dev/null || (echo "Git Missing" && exit 1)
	@echo "$(GREEN)All tools installed$(NC)"
	@aws sts get-caller-identity

# ==========================================================
# TERRAFORM
# ==========================================================

fmt:
	cd $(TF_DIR) && terraform fmt -recursive

init:
	cd $(TF_DIR) && terraform init

validate:
	cd $(TF_DIR) && terraform validate

plan:
	cd $(TF_DIR) && terraform plan

apply:
	cd $(TF_DIR) && terraform apply -auto-approve

destroy:
	cd $(TF_DIR) && terraform destroy

# ==========================================================
# KUBECONFIG
# ==========================================================

kubeconfig:
	aws eks update-kubeconfig \
	--name enterprise-devsecops-dev \
	--region $(AWS_REGION)

# ==========================================================
# ARGOCD
# ==========================================================

bootstrap:
	chmod +x $(BOOTSTRAP)
	bash $(BOOTSTRAP)

# ==========================================================
# CLUSTER
# ==========================================================

pods:
	kubectl get pods -A

nodes:
	kubectl get nodes -o wide

services:
	kubectl get svc -A

ingress:
	kubectl get ingress -A

namespaces:
	kubectl get ns

events:
	kubectl get events -A --sort-by=.metadata.creationTimestamp

health:
	@echo ""
	kubectl get nodes
	@echo ""
	kubectl get pods -A
	@echo ""
	kubectl top nodes || true
	@echo ""
	kubectl top pods -A || true

# ==========================================================
# LOGS
# ==========================================================

logs:
	kubectl logs -n rag deployment/rag-document-qa --tail=100

argocd-logs:
	kubectl logs -n argocd deployment/argocd-server --tail=100

# ==========================================================
# PORT FORWARD
# ==========================================================

grafana:
	kubectl port-forward svc/grafana -n monitoring 3000:80

argocd:
	kubectl port-forward svc/argocd-server -n argocd 8080:443

# ==========================================================
# VERIFY
# ==========================================================

verify:
	@echo "$(GREEN)Checking Cluster$(NC)"
	kubectl get nodes

	@echo "$(GREEN)Checking ArgoCD$(NC)"
	kubectl get pods -n argocd

	@echo "$(GREEN)Checking Monitoring$(NC)"
	kubectl get pods -n monitoring

	@echo "$(GREEN)Checking External Secrets$(NC)"
	kubectl get pods -n external-secrets

	@echo "$(GREEN)Checking Falco$(NC)"
	kubectl get pods -n falco

	@echo "$(GREEN)Checking Kyverno$(NC)"
	kubectl get pods -n kyverno

	@echo "$(GREEN)Checking Trivy$(NC)"
	kubectl get pods -A | grep trivy || true

# ==========================================================
# CLEAN
# ==========================================================

clean:
	find . -type d -name ".terraform" -exec rm -rf {} +
	find . -name "*.tfplan" -delete
	find . -name ".terraform.lock.hcl" -delete
	docker system prune -f

# ==========================================================
# GIT
# ==========================================================

status:
	git status

release:
	git status
	@echo ""
	@read -p "Commit Message: " msg; \
	git add . && \
	git commit -m "$$msg" && \
	git push origin main

# ==========================================================
# COMPLETE BOOTSTRAP
# ==========================================================

all:
	$(MAKE) doctor
	$(MAKE) init
	$(MAKE) validate
	$(MAKE) apply
	$(MAKE) kubeconfig
	$(MAKE) bootstrap
	$(MAKE) verify
	$(MAKE) health