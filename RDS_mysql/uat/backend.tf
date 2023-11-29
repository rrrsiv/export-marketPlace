terraform {
  backend "s3" {
    bucket = "emp-terraform-state-backend"
    key    = "rds-mysql-uat/terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "emp-terraform_state"

  }
}
