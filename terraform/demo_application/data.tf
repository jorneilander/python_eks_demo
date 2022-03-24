data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "../cluster/terraform.tfstate"
  }
}

# Retrieve EKS cluster information
provider "aws" {
  region = data.terraform_remote_state.eks.outputs.region
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

data "aws_iam_role" "fargate" {
  name = data.terraform_remote_state.eks.outputs.fargate_aws_iam_role.name
}

data "aws_ecr_authorization_token" "demo_application_registry_token" {
  registry_id = aws_ecr_repository.demo_application.registry_id
}

data "aws_caller_identity" "current" {}
