# resource "aws_iam_role" "eks-cluster" {
#   name = "eks-cluster-${var.cluster_name}"

#   assume_role_policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "eks.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# POLICY
# }

# resource "aws_iam_role_policy_attachment" "amazon-eks-cluster-policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.eks-cluster.name
# }


##################################### VPC #########################################

data "aws_vpc" "emp" {
  id = var.vpc_id
}

data "aws_subnet" "subnet1" {
  id = var.subnet1_id

}
data "aws_subnet" "subnet2" {
  id = var.subnet2_id

}

resource "aws_ec2_tag" "example" {

  resource_id = var.subnet2_id
  key         = "kubernetes.io/cluster/${var.project}-${var.env}-eks-cluster"
  value       = "owned"
} 
resource "aws_ec2_tag" "example1" {

  resource_id = var.subnet1_id
  key         = "kubernetes.io/cluster/${var.project}-${var.env}-eks-cluster"
  value       = "owned"
} 
resource "aws_ec2_tag" "example2" {

  resource_id = var.subnet1_id
  key         = "kubernetes.io/role/internal-elb" 
  value       = "1"
} 
resource "aws_ec2_tag" "example3" {

  resource_id = var.subnet2_id
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
} 

################################## EKS Cluster ###################################

resource "aws_eks_cluster" "cluster" {
  name     = "${var.project}-${var.env}-eks-cluster"
  version  = var.cluster_version
  role_arn = aws_iam_role.eks-cluster-role.arn
  enabled_cluster_log_types = ["api", "audit", "authenticator", "scheduler", "controllerManager"]
  
  vpc_config {

    endpoint_private_access = true
    endpoint_public_access  = false

    subnet_ids = [
      data.aws_subnet.subnet1.id,
      data.aws_subnet.subnet2.id
    ]
 
  }

  tags                      = {
    Name = "${var.project}-${var.env}-eks-cluster"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-cluster-role-policy,
    data.aws_vpc.emp
 ]

}



#### ROLE For CLUSTER ####
data "aws_iam_policy_document" "eks-cluster-role-policy-json" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["eks.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "eks-cluster-role" {
  name               = "${var.project}-${var.env}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks-cluster-role-policy-json.json
  tags               = {
    Name = "${var.project}-${var.env}-eks-cluster-role"
  }
}

resource "aws_iam_instance_profile" "eks-cluster-iamrole-instances-profile" {
  name = aws_iam_role.eks-cluster-role.name
  role = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-role-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-role-service-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-role-cnipolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-cluster-role.name
}

