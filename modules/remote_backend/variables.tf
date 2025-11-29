# Remote Backend Module Variables

variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  type        = string
}

variable "region" {
  description = "AWS region for the remote backend resources"
  type        = string
}