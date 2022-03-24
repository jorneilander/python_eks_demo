variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "eks_cluster_name" {
  type    = string
  default = "eks_python_demo"
}

variable "public_access_cidrs" {
  type = list(string)
}

variable "vpc_name" {
  type    = string
  default = "eks_python_demo"
}
