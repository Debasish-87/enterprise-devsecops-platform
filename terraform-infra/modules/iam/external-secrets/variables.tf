variable "oidc_provider" {
  description = "EKS OIDC provider URL (without https://)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}
