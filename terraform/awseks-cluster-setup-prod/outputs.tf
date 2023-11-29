
output "subnet1" {
  value       = data.aws_subnet.subnet1.id
}
output "subnet2" {
  value       = data.aws_subnet.subnet2.id
}
output "eks-sg" {
  value       = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

output "oidc-role-name" {
  value       = aws_iam_role.oidc_iam_role.name
}

