bucket_name       = "emp-terraform-state-backend"
dynamodb_table_name = "emp-terraform_state"
region            = "ap-south-1"
identifier        = "emp-uat-rds-mysql"
engine_version    = "8.0.32"
instance_class    = "db.t4g.large"
allocated_storage = 20
username          = "root"
password          = "password#1234"
subnet_ids         = ["subnet-0cae86dd6bae39b34", "subnet-07a21d3c1b0129eea"]
vpc_id             = "vpc-0e8b63a01995cc13a"
source_cidr_blocks = ["10.132.83.192/26", "10.132.83.128/26", "10.132.80.45/32", "10.132.85.64/26", "10.132.85.0/26", "10.132.85.128/26","10.132.85.192/26"]
maintenance_window                  = "mon:10:10-mon:10:40"
backup_window                       = "09:10-09:40"
apply_immediately                   = false
multi_az                            = false
port                                = 3306
name                                = ""
storage_type                        = "gp2"
iops                                = 0
auto_minor_version_upgrade          = true
allow_major_version_upgrade         = false
backup_retention_period             = 1
storage_encrypted                   = true
kms_key_id                          = ""
deletion_protection                 = false
final_snapshot_identifier           = "emp-uat-rds-mysql-final-snapshot"
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
Environment = "uat"
}