output "role_arn" {
  description = "IAM Role ARN for ALB Controller IRSA"
  value       = aws_iam_role.alb_controller.arn
}
