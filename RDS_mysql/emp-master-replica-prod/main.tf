provider "aws" {
  region = var.region
 }

locals {

  tags = {
    Name       = var.identifier
    Environment    = prod
  }
}

module "master" {
 source = "terraform-aws-modules/rds/aws"
 version = "5.4.2"
 instance_class                 = var.instance_class 
 allocated_storage              = var.allocated_storage    
 max_allocated_storage          = var.max_allocated_storage 
 engine                         = var.engine                     
 engine_version                 = var.engine_version                          
 db_name                        = var.db_name                                   
 username                       = var.username    
 password                       = var.pass                                           
 family                         = var.family                  
 major_engine_version           = var.major_engine_version            
 multi_az                       = true

 publicly_accessible            = false
 backup_retention_period        = var.backup_retention_period
 vpc_security_group_ids         = [module.security_group.security_group_id]
 identifier                     = var.identifier
 port                           = var.port
 skip_final_snapshot            = true
 deletion_protection            = false
 create_db_subnet_group         = true
 enabled_cloudwatch_logs_exports = ["general"]
 tags                           = local.tags
 parameter_group_name           = var.parameter_group_name
 create_random_password         = false
 apply_immediately              = true
 create_db_option_group         = false
 kms_key_id                     = data.aws_kms_key.key.arn

 maintenance_window              = "Fri:22:15-Fri:23:15"
 backup_window                   = "21:00-22:00"

 

 depends_on = [
  module.security_group
 ]

}

######################### Replica ############################

data "aws_kms_key" "key" {
  key_id = "alias/Exportmarket-RDS-Kms"
}

module "replica" {
  source = "terraform-aws-modules/rds/aws"
  version = "5.4.2"

  identifier = "${var.name}-rds-replica"

  # Source database. For cross-region use db_instance_arn
  replicate_source_db    = module.master.db_instance_id
  create_random_password = false

  engine               = var.engine
  engine_version       = var.engine_version 
  family               = var.family
  major_engine_version = var.major_engine_version
  instance_class       = var.instance_class
  kms_key_id           = data.aws_kms_key.key.arn

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  publicly_accessible   = false
  # Username and password should not be set for replicas
  username = null
  password = null
  port     = var.port
  create_db_subnet_group   = true
  multi_az               = false
  vpc_security_group_ids = [module.security_group.security_group_id]

  maintenance_window              = "Fri:22:15-Fri:23:15"
  backup_window                   = "21:00-22:00"

  enabled_cloudwatch_logs_exports = ["general"]

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = local.tags

  depends_on = [
    module.security_group
  ]
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

#############################SG###################################

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.identifier}-sg"
  description = "Replica MySQL example security group"
  vpc_id      = var.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within VPC"
      cidr_blocks = data.aws_subnets.private.ids
    },
  ]

  tags = local.tags
}



