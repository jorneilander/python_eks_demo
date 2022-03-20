
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
    shell = {
      source = "scottwinkler/shell"
      version = "1.7.10"
    }
  }
}
