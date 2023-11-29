terraform {
  backend "s3" {
    bucket = "emp-terraform-state-backend-prod"
    key    = "prod-deployment/terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "emp-terraform_state"

  }
}
