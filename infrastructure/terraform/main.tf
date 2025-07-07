terraform {
  required_version = ">= 1.3"
  required_providers {
    aws  = { source = "hashicorp/aws",  version = "~> 5.0" }
    helm = { source = "hashicorp/helm", version = "~> 2.10" }
  }
}

provider "aws" {
  region = "eu-north-1"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "eks-lab-4"
  cluster_version = "1.27"
  # Additional networking configuration may be required
}

module "db" {
  source = "terraform-aws-modules/rds/aws"
  engine = "mysql"
  # Configure DB parameters as needed for the application
}

module "ecr" {
  source      = "terraform-aws-modules/ecr/aws"
  repository  = "aws-lab"
  create_repo = true
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
}

resource "kubernetes_manifest" "argocd_ingress" {
  manifest = yamldecode(file("${path.module}/../argocd-server-ingress.yaml"))
}

resource "aws_iam_policy" "ecr_read" {
  name   = "ecr-read-policy"
  policy = file("${path.module}/../../ecr-read-policy.json")
}
