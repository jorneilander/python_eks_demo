resource "aws_ecr_repository" "demo_application" {
  name                 = var.image_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = data.terraform_remote_state.eks.outputs.aws_kms_key.arn
  }
}

locals {
  image_repository = aws_ecr_repository.demo_application.repository_url
  image_tag        = "latest"
}

resource "docker_registry_image" "demo_application" {
  depends_on = [
    aws_ecr_repository.demo_application
  ]
  name = "${local.image_repository}:${local.image_tag}"
  build {
    context      = "../../demo_application"
    force_remove = true

    labels = {
      author : "Jorn Eilander"
    }
    platform = "linux/amd64"
  }
}
