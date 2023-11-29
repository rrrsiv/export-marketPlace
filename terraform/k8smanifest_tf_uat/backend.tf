terraform {
  backend "s3" {
    bucket = "emp-terraform-state-backend"
    key    = "uat-deployment/terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "emp-terraform_state"

  }
}
