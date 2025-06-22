terraform {
  backend "s3" {
    bucket         = "terraform-state-aca-dev" # Please replace with your actual S3 bucket name
    key            = "dev/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-state-locking" # Please replace with your actual DynamoDB table name
    encrypt        = true
  }
}