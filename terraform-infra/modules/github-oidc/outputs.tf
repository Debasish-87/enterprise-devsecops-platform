output "github_role_arn" {
  description = "IAM Role ARN for GitHub Actions to assume"
  value       = aws_iam_role.github_actions.arn
}
