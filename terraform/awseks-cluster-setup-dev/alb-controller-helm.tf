resource "helm_release" "loadbalancer_controller" {
  depends_on = [aws_iam_role.oidc_iam_role]            
  name       = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  namespace = "kube-system"     

  # Value changes based on your Region (Below is for us-east-1)
      

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "${aws_iam_role.oidc_iam_role.arn}"
  }

  set {
    name  = "vpcId"
    value = "${data.aws_vpc.emp.id}"
  }  

  set {
    name  = "region"
    value = "ap-south-1"
  }    

  set {
    name  = "clusterName"
    value = "${var.project}-${var.env}-eks-cluster"
  }    
    
}
