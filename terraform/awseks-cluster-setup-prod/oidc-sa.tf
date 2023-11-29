resource "kubectl_manifest" "oidc_sa" {
    yaml_body = <<-YAML
        apiVersion: v1
        kind: ServiceAccount
        metadata:
          annotations:
            eks.amazonaws.com/role-arn: arn:aws:iam::453708032754:role/emp-prod-oidc-iam-role
          name: aws-load-balancer-controller
          namespace: kube-system

    YAML
    depends_on = [
      aws_iam_role.oidc_iam_role
    ]
}