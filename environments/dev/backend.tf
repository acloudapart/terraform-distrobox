terraform {
  backend "s3" {
    bucket         = "terraform-aca-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}