resource "kubernetes_namespace" "demo_application" {
  metadata {
    annotations = {
      name = "demo-application"
    }

    name = "demo-application"
  }
}

resource "aws_eks_fargate_profile" "demo_application" {
  depends_on = [
    kubernetes_namespace.demo_application
  ]

  cluster_name           = data.aws_eks_cluster.cluster.name
  fargate_profile_name   = "demo-application"
  pod_execution_role_arn = data.aws_iam_role.fargate.arn

  subnet_ids = data.terraform_remote_state.eks.outputs.private_subnets

  selector {
    namespace = "demo-application"
  }
}

resource "kubernetes_deployment" "demo_application" {
  timeouts {
    create= "2m"
    update= "2m"
    delete= "5m"
  }

  depends_on = [
    aws_eks_fargate_profile.demo_application,
    docker_registry_image.demo_application
  ]
  metadata {
    name = "demo-application"
    labels = {
      app = "demo-application"
    }
    namespace = "demo-application"
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "demo-application"
      }
    }
    template {
      metadata {
        labels = {
          app = "demo-application"
        }
      }
      spec {
        container {
          image = "${docker_registry_image.demo_application.name}"
          name  = "demo-application"

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}