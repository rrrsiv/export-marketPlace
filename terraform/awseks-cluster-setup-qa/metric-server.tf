

resource "helm_release" "metrics-server" {
  name = "metrics-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.9.0"

  set {
    name  = "metrics.enabled"
    value = false
  }

  depends_on = [aws_eks_fargate_profile.kube-system]
}
