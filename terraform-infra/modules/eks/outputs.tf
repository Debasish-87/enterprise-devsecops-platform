output "cluster_name" {
  description = "EKS Cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS Cluster API server endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_arn" {
  description = "EKS Cluster ARN"
  value       = aws_eks_cluster.this.arn
}

output "cluster_certificate_authority" {
  description = "Base64 encoded cluster CA certificate"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider for IRSA"
  value       = aws_iam_openid_connect_provider.eks.url
}

output "kms_key_arn" {
  description = "KMS key ARN used for EKS secrets encryption"
  value       = aws_kms_key.eks.arn
}
