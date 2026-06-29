variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-1"
}

variable "state_bucket_name" {
  description = "Terraform State S3 Bucket Name"
  type        = string
}

variable "lock_table_name" {
  description = "Terraform State Lock DynamoDB Table Name"
  type        = string
  default     = "terraform-state-lock"
}
