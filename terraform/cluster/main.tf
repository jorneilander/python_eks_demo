locals {
  cluster_version = "1.21"

  tags = {
    cluster    = var.eks_cluster_name
    GithubRepo = "python_eks_demo"
    GithubOrg  = "jorneilander"
  }
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.tags
}
