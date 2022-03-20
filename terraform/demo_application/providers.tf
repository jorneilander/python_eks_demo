terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }

    docker = {
      source = "kreuzwerker/docker"
      version = ">= 2.16.0"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.cluster.name
    ]
  }
}

provider "docker" {
  registry_auth {
    # address  = data.aws_ecr_repository.image_registry.repository_url
    address = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.terraform_remote_state.eks.outputs.region}.amazonaws.com"
    username = data.aws_ecr_authorization_token.demo_application_registry_token.user_name
    password = data.aws_ecr_authorization_token.demo_application_registry_token.password
  }
}