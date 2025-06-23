terraform {
  backend "s3" {
    bucket         = "terraform-aca-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}