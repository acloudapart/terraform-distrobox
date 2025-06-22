terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket-name" # Please replace with your actual S3 bucket name
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock" # Please replace with your actual DynamoDB table name
    encrypt        = true
  }
}