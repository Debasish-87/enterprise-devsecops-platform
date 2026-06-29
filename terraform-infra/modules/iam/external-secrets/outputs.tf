output "role_arn" {
  description = "IAM Role ARN for External Secrets IRSA"
  value       = aws_iam_role.external_secrets.arn
}
