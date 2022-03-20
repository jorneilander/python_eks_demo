module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "18.11.0"
  cluster_name    = local.name
  cluster_version = "1.21"
  subnet_ids      = module.vpc.private_subnets
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = ["31.201.206.242/32"]

  vpc_id = module.vpc.vpc_id

  cluster_encryption_config = [{
    provider_key_arn    = aws_kms_key.eks.arn
    resources   = ["secrets"]
  }]

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  fargate_profiles = {
    core-dns = {
      name = "core-dns"
      pod_execution_role_arn = aws_iam_role.fargate
      selectors = [
        {
          namespace = "kube-system"
          # labels = {
          #   k8s-app = "kube-dns"
          # }
        }
      ]
    }
  }

}

resource "aws_iam_role" "fargate" {
  name = "eks-fargate-profile"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "fargate-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate.name
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.tags
}

