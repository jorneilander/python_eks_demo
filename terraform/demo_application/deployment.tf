


resource "aws_eks_fargate_profile" "demo_application" {
  cluster_name           = data.aws_eks_cluster.cluster.name
  fargate_profile_name   = "demo-application"
  pod_execution_role_arn = data.aws_iam_role.fargate.arn

  subnet_ids = data.terraform_remote_state.eks.outputs.private_subnets

  selector {
    namespace = var.helm_app_release_namespace
  }
}

resource "helm_release" "demo_application" {
  depends_on = [
    aws_eks_fargate_profile.demo_application,
    docker_registry_image.demo_application
  ]

  name             = var.helm_app_release_name
  chart            = "../../helm/eks_python_demo/"
  namespace        = var.helm_app_release_namespace
  create_namespace = true

  set {
    name  = "image.repository"
    value = local.image_repository
  }

  set {
    name  = "image.tag"
    value = local.image_tag
  }

  set {
    name = "application.response.root"
    value = var.demo_root_response
  }

  set {
    name = "application.response.api"
    value = var.demo_api_response
  }

  set {
    name = "application.version"
    value = var.demo_app_version
  }
}
