module "eks" {
  source                               = "terraform-aws-modules/eks/aws"
  version                              = "18.11.0"
  cluster_name                         = var.eks_cluster_name
  cluster_version                      = "1.21"
  subnet_ids                           = module.vpc.private_subnets
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.public_access_cidrs

  vpc_id = module.vpc.vpc_id

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  # I had to add a managed node to run core-dns due to an issue in AWS Faregate in combination with core-dns
  # !TODO: https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1286
  eks_managed_node_groups = {
    bottlerocket = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      create_launch_template = false
      launch_template_name   = ""

      ami_type       = "BOTTLEROCKET_x86_64"
      platform       = "bottlerocket"
      instance_types = ["t3.micro"]
      desired_size   = 1
    }
  }


  # Fargate profile for kube-system not needed until fix for issue mentioned above
  fargate_profiles = {
    aws-load-balancer-controller = {
      name = "aws-load-balancer-controller"
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            "app.kubernetes.io/name" = "aws-load-balancer-controller"
          }
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
