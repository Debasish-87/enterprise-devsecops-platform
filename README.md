# 🚀 Enterprise Cloud DevSecOps Platform

**AWS + EKS + ArgoCD + GitOps + Security-First Architecture**

> Ek production-ready DevSecOps platform jo RAG (Retrieval-Augmented Generation) Document QA application ko securely AWS pe deploy karta hai.

---

## 🏗️ Architecture Overview

```
GitHub → GitHub Actions CI/CD → Amazon ECR
                                     ↓
                              GitOps Repo (Image Tag Update)
                                     ↓
                              ArgoCD (GitOps Sync)
                                     ↓
                         AWS EKS (Kubernetes Cluster)
                                     ↓
                    ┌────────────────┼────────────────┐
                    │                │                │
              RAG App (rag ns)  Platform Tools   Security Stack
                    │                │                │
              ALB Ingress      Prometheus       Kyverno Policies
                    │            Grafana          Falco (Runtime)
                               OpenTelemetry    Trivy Operator
                               Karpenter        External Secrets
```

---

## 📁 Project Structure

```
enterprise-devsecops-platform/
├── .github/
│   └── workflows/
│       ├── ci-cd.yaml            # Main CI/CD pipeline
│       └── terraform-plan.yaml   # Terraform PR validation
│
├── bootstrap/
│   ├── main.tf                   # S3 state bucket + DynamoDB lock
│   ├── versions.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── argocd/
│       └── install.sh            # One-time ArgoCD bootstrap
│
├── terraform-infra/
│   ├── environments/
│   │   └── dev/                  # Dev environment config
│   │       ├── main.tf           # Module wiring
│   │       └── versions.tf       # Backend + provider
│   └── modules/
│       ├── vpc/                  # VPC + subnets + flow logs
│       ├── eks/                  # EKS cluster + KMS + IRSA
│       ├── ecr/                  # Container registry
│       ├── github-oidc/          # Keyless GitHub Auth
│       └── iam/
│           ├── alb-controller/   # ALB IRSA role
│           └── external-secrets/ # Secrets IRSA role
│
├── gitops-repo/                  # ArgoCD manages this
│   ├── kustomization.yaml        # Root kustomization
│   ├── environments/
│   │   └── dev/root.yaml         # Root App of Apps
│   ├── platform/                 # Platform tools
│   │   ├── argocd/
│   │   ├── alb-controller/
│   │   ├── prometheus/
│   │   ├── grafana/
│   │   ├── kyverno/              # + security policies
│   │   ├── falco/
│   │   ├── trivy-operator/
│   │   ├── external-secrets/
│   │   ├── opentelemetry/
│   │   └── karpenter/
│   └── applications/
│       └── rag-document-qa/      # Main application
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           ├── hpa.yaml
│           └── pdb.yaml
│
└── application/
    ├── Dockerfile                # Multi-stage, hardened
    └── scripts/
        └── clone-rag.sh
```

---

## 🛡️ Security Features

| Layer | Tool | What it does |
|-------|------|-------------|
| IaC Scanning | Checkov | Terraform security misconfigs |
| Image Scanning | Trivy (CI + Operator) | CVE detection in Docker images |
| Policy Enforcement | Kyverno | No `latest` tag, resource limits, non-root |
| Runtime Security | Falco (eBPF) | Detect suspicious syscalls at runtime |
| Secrets Management | External Secrets + AWS SM | No secrets in Git, ever |
| IAM | IRSA + OIDC | Workload-level IAM, no static keys |
| Network | VPC Flow Logs + SGs | Traffic auditing |
| Encryption | KMS | EKS secrets + ECR images encrypted |
| Nodes | IMDSv2 enforced | Metadata API hardened |

---

## 🚦 CI/CD Pipeline Flow

```
1. Developer pushes code
        ↓
2. GitHub Actions triggers
        ↓
3. STAGE 1: Lint
   - Hadolint (Dockerfile)
   - Checkov (Terraform IaC)
        ↓
4. STAGE 2: Build
   - Clone app source
   - Authenticate to ECR via OIDC (no keys!)
   - Build Docker image
   - Trivy vulnerability scan → SARIF to GitHub Security
   - Push to ECR with SHA tag
        ↓
5. STAGE 3: GitOps Update
   - Update deployment.yaml with new image SHA
   - Commit + push to repo
        ↓
6. ArgoCD detects Git change → syncs to EKS automatically
```

---

## 🚀 Deployment Steps

### Step 1: Bootstrap Terraform State
```bash
cd bootstrap/
terraform init
terraform apply -var="state_bucket_name=<YOUR_ACCOUNT_ID>-devsecops-tf-state"
```

### Step 2: Deploy AWS Infrastructure
```bash
cd terraform-infra/environments/dev/
terraform init
terraform apply -var="aws_region=ap-south-1"
```

### Step 3: Configure kubectl
```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name enterprise-devsecops-dev
```

### Step 4: Bootstrap ArgoCD
```bash
chmod +x bootstrap/argocd/install.sh
./bootstrap/argocd/install.sh
```

### Step 5: Create Required Secrets in AWS Secrets Manager
```bash
aws secretsmanager create-secret \
  --name rag/gemini-api-key \
  --secret-string '{"GEMINI_API_KEY":"your-key-here"}'

aws secretsmanager create-secret \
  --name rag/api-token \
  --secret-string '{"API_TOKEN":"your-token-here"}'

aws secretsmanager create-secret \
  --name grafana/admin-user \
  --secret-string '{"admin-user":"admin"}'

aws secretsmanager create-secret \
  --name grafana/admin-password \
  --secret-string '{"admin-password":"your-secure-password"}'
```

### Step 6: Apply Root App (triggers all GitOps)
```bash
kubectl apply -f gitops-repo/environments/dev/root.yaml
```

---

## ⚙️ GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| `AWS_ACCOUNT_ID` | AWS Account ID |
| `GITOPS_TOKEN` | GitHub PAT with repo write access |

---

## 📊 Observability Stack

- **Prometheus** — Metrics collection (7d retention, 10Gi storage)
- **Grafana** — Dashboards (secrets via External Secrets from AWS SM)
- **OpenTelemetry** — Distributed tracing (OTLP receiver)
- **Falco** — Runtime security alerts
- **Trivy Operator** — Continuous vulnerability reports in cluster

---

## 🔧 Platform Components

| Component | Namespace | Purpose |
|-----------|-----------|---------|
| ArgoCD | argocd | GitOps controller |
| ALB Controller | kube-system | AWS Load Balancer provisioning |
| Karpenter | karpenter | Node autoscaling |
| Prometheus | monitoring | Metrics |
| Grafana | monitoring | Dashboards |
| Kyverno | kyverno | Policy enforcement |
| Falco | falco | Runtime security |
| Trivy Operator | trivy-system | Image scanning |
| External Secrets | external-secrets | Secret sync from AWS SM |
| OpenTelemetry | observability | Tracing |

---

## 📝 License

MIT — Free to use and modify for your own DevSecOps platform.
