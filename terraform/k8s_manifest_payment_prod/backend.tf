terraform {
  backend "s3" {
    bucket = "emp-terraform-state-backend-prod"
    key    = "payment-servic-prod/terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "emp-terraform_state"

  }
}
