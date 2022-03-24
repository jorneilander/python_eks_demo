variable "helm_app_release_namespace" {
  description = "Namespace for application Helm release"
  type = string
}

variable "helm_app_release_name" {
  description = "Helm release name"
  type = string
}

variable "image_repository_name" {
  description = "Application image repository name"
  type    = string
  default = "demo_application"
}

variable "demo_root_response" {
  description = "Application response on '{URL}/'"
  type    = string
  default = "Welcome to ReaQta"
}

variable "demo_api_response" {
  description = "Application response on '{URL}/api"
  type    = string
  default = "Welcome to ReaQta API"
}

variable "demo_app_version" {
  description = "Application version"
  type    = string
  default = "1"
}
