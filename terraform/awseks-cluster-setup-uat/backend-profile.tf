resource "aws_eks_fargate_profile" "be" {
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "backend"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile.arn

  # These subnets must have the following resource tag: 
  # kubernetes.io/cluster/<CLUSTER_NAME>.
  subnet_ids = [
    data.aws_subnet.subnet1.id,
    data.aws_subnet.subnet2.id
  ]

  selector {
    namespace = "backend"
  }
}

##################### backend namespace #################
resource "kubectl_manifest" "backend" {
    yaml_body = <<-YAML
        apiVersion: v1
        kind: Namespace
        metadata:
          name: backend
    YAML
    depends_on = [
      aws_eks_fargate_profile.be
    ]
}   