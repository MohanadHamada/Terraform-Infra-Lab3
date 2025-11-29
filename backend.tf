#NOTE: before running terraform apply for the first time make sure to hash this file first and the unhash it and reinitialize the folder
# Remote Backend Configuration
terraform {
  backend "s3" {
    bucket         = "terraform-iti-s3-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-multi-tier-proxy"
    encrypt        = true
  }
}