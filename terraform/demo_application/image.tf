resource "aws_ecr_repository" "demo_application" {
  name                 = "demo_application"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key = data.terraform_remote_state.eks.outputs.aws_kms_key.arn
  }
}


resource "docker_registry_image" "demo_application" {
  name = "${aws_ecr_repository.demo_application.repository_url}:${formatdate("DDMMMYYYYhhmm", timestamp())}"
  build {
    context = "../../demo_application"
    labels = {
      author : "Jorn Eilander"
    }
    platform = "linux/amd64"
  }
}