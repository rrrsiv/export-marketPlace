
resource "aws_db_instance" "default" {
  engine                 = "mysql"
  option_group_name      = aws_db_option_group.default.name
  parameter_group_name   = aws_db_parameter_group.default.name
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.default.id]
  identifier = var.identifier
  engine_version = var.engine_version
  # The DB instance class determines the computation and memory capacity of an Amazon RDS DB instance.
  # We recommend only using db.t2 instance classes for development and test servers, or other non-production servers.
  instance_class = var.instance_class
  allocated_storage = var.allocated_storage
  # The name for the master user.
  username = var.username
  # The password for the master user.
  password = var.password
  maintenance_window = var.maintenance_window
  backup_window = var.backup_window
  apply_immediately = var.apply_immediately
  # Amazon RDS provides high availability and failover support for DB instances using Multi-AZ deployments.
  # In a Multi-AZ deployment, Amazon RDS automatically provisions
  # and maintains a synchronous standby replica in a different Availability Zone.
  multi_az = var.multi_az
  # The port that you want to access the DB instance through.
  port = var.port
  # The name of the database. If this parameter is not specified, no database is created in the DB instance.
  name = var.name
  storage_type = var.storage_type
  iops = var.iops
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade
  backup_retention_period = var.backup_retention_period
  storage_encrypted = var.storage_encrypted

  # You can supply the AWS KMS key identifier for your encryption key.
  # If you don't specify an AWS KMS key identifier, then Amazon RDS uses your default encryption key.
  kms_key_id = var.kms_key_id

  # You can only delete instances that don't have deletion protection enabled.
  # To delete a DB instance that has deletion protection enabled, first modify the instance and disable deletion protection.
  deletion_protection = var.deletion_protection

  # When you delete a DB instance, you can create a final snapshot of the DB instance.
  # If omitted, no final snapshot will be made.                     
  final_snapshot_identifier = var.final_snapshot_identifier

  # A value that indicates whether a final DB snapshot is created before the DB instance is deleted.
  # If true is specified, no DB snapshot is created.
  # If false is specified, a DB snapshot is created before the DB instance is deleted.
  skip_final_snapshot = var.skip_final_snapshot

  # Specifies whether or not to create this database from a snapshot. 
  # This correlates to the snapshot ID you'd find in the RDS console, e.g: rds:production-2015-06-26-06-05.
  snapshot_identifier = var.snapshot_identifier

  # You can configure your Amazon RDS MySQL DB instance to publish log data to a log group in Amazon CloudWatch Logs.
  # Valid values (depending on engine): alert, audit, error, general, listener, slowquery, trace.
  # If omitted, no logs will be exported.
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # A smaller monitoring interval results in more frequent reporting of OS metrics and increases your monitoring cost.
  # You can be set to one of the following values: 1, 5, 10, 15, 30, or 60.
  # To disable collecting Enhanced Monitoring metrics, specify 0.
  monitoring_interval = var.monitoring_interval

  # Enhanced Monitoring requires permission to act on your behalf to send OS metric information to CloudWatch Logs.
  # You grant Enhanced Monitoring the required permissions using an IAM role.
  monitoring_role_arn = var.monitoring_role_arn
  # You can authenticate to your DB instance using IAM database authentication.
  # With this authentication method, you don't need to use a password when you connect to a DB instance.
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  # You can specify that the tags from the DB instance are copied to snapshots of the DB instance.
  copy_tags_to_snapshot = var.copy_tags_to_snapshot
  # This parameter lets you designate whether there is public access to the DB instance.
  publicly_accessible = var.publicly_accessible
  ca_cert_identifier = var.ca_cert_identifier
  license_model = var.license_model

  # A mapping of tags to assign to the resource.
  tags = merge({ "Name" = var.identifier }, var.tags)

  # The password defined in Terraform is an initial value, it must be changed after creating the RDS instance.
  # Therefore, suppress plan diff after changing the password.
#   lifecycle {
#     ignore_changes = [password]
#   }
  depends_on = [
    data.aws_vpc.emp
  ]
}

# NOTE: Any modifications to the db_option_group are set to happen immediately as we default to applying immediately.
#

resource "aws_db_option_group" "default" {
  engine_name              = "mysql"
  name                     = var.identifier
  major_engine_version     = local.major_engine_version
  option_group_description = var.description

  tags = merge({ "Name" = var.identifier }, var.tags)
}

# If major_engine_version is unspecified, then calculate major_engine_version.
# Calculate from X.Y.Z(or X.Y) to X.Y, for example 5.7.21 is calculated 5.7.
locals {
  version_elements       = split(".", var.engine_version)
  major_version_elements = [local.version_elements[0], local.version_elements[1]]
  major_engine_version   = var.major_engine_version == "" ? join(".", local.major_version_elements) : var.major_engine_version
}

# https://www.terraform.io/docs/providers/aws/r/db_parameter_group.html
resource "aws_db_parameter_group" "default" {
  name        = var.identifier
  family      = local.family
  description = var.description

  parameter {
    name         = "character_set_client"
    value        = var.character_set
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_connection"
    value        = var.character_set
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_database"
    value        = var.character_set
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_results"
    value        = var.character_set
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_server"
    value        = var.character_set
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_connection"
    value        = var.collation
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_server"
    value        = var.collation
    apply_method = "immediate"
  }

  parameter {
    name         = "time_zone"
    value        = var.time_zone
    apply_method = "immediate"
  }

#   parameter {
#     name         = "tx_isolation"
#     value        = var.tx_isolation
#     apply_method = "immediate"
#   }

  tags = merge({ "Name" = var.identifier }, var.tags)
}

locals {
  family = "mysql${local.major_engine_version}"
}

# https://www.terraform.io/docs/providers/aws/r/db_subnet_group.html
resource "aws_db_subnet_group" "default" {
  name        = var.identifier
  subnet_ids  = data.aws_subnets.private.ids
  description = var.description

  tags = merge({ "Name" = var.identifier }, var.tags)
}

# https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group" "default" {
  name   = local.security_group_name
  vpc_id = var.vpc_id

  tags = merge({ "Name" = local.security_group_name }, var.tags)
}

locals {
  security_group_name = "${var.identifier}-rds-mysql"
}

# https://www.terraform.io/docs/providers/aws/r/security_group_rule.html
resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.source_cidr_blocks
  security_group_id = aws_security_group.default.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default.id
}

################################### VPC ###################################################

data "aws_vpc" "emp" {
  id = var.vpc_id
}
# data "aws_subnet_ids" "emp_subnets" {

#   vpc_id = data.aws_vpc.emp.id
# }

# data "aws_subnet" "example" {
#   for_each = data.aws_subnet_ids.emp_subnets.ids
#   id       = each.value
# }

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    env = "dev"
  }
}