bucket_name       = "emp-terraform-state-backend"
dynamodb_table_name = "emp-terraform_state"
region            = "ap-south-1"
identifier        = "emp-prod-rds-mysql"
engine            = "mysql"
engine_version    = "8.0.32"
family            = "mysql8.0"
instance_class    = "db.m5d.large"
allocated_storage = 50
max_allocated_storage = 100
username          = "root"
password          = "J23a0kJ2l2NZ"
vpc_id             = "vpc-0a2ac682628135bc7"
source_cidr_blocks = ["10.132.25.0/24", "10.132.26.0/24"]

port                                = 3306
db_name                             = ""

backup_retention_period             = 1
storage_encrypted                   = true
deletion_protection                 = false
final_snapshot_identifier           = "emp-prod-rds-mysql-final-snapshot"
skip_final_snapshot                 = true
enabled_cloudwatch_logs_exports     = ["audit", "error", "general", "slowquery"]
monitoring_interval                 = 0
monitoring_role_arn                 = ""
iam_database_authentication_enabled = false
copy_tags_to_snapshot               = true
publicly_accessible                 = false
license_model                       = "general-public-license"
major_engine_version                = "8.0"
tags = {
Environment = "Prod"
}