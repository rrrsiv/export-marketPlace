terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.3.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.9.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
  required_version = "~>1.3"
  
}

provider "aws" {
  region = "ap-south-1"
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.id]
      command     = "aws"
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = "emp-prod-eks-cluster"
}

output "endpoint" {
  value = data.aws_eks_cluster.cluster.endpoint
}