resource "aws_efs_file_system" "eks" {
  creation_token = "${var.project}-${var.env}-efs"

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  # lifecycle_policy {
  #   transition_to_ia = "AFTER_30_DAYS"
  # }

  tags = {
    Name = "${var.project}-${var.env}-efs"
  }
}

resource "aws_efs_mount_target" "zone-a" {
  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = data.aws_subnet.subnet1.id
  security_groups = [aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id]
}

resource "aws_efs_mount_target" "zone-b" {
  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = data.aws_subnet.subnet2.id
  security_groups = [aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id]
}
