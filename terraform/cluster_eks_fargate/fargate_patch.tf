# Provider configuration
# provider "shell" {
#   interpreter = ["/bin/bash", "-c"]
#   sensitive_environment = {
#     KUBECTL_CONFIG = base64encode(module.eks.kubeconfig)
#   }
# }

# Configures coredns to run on Fargate.
# Per default coredns runs with EC2.
# The Terraform eks module does not offer any inputs to set the compute type of coredns to Fargate.
# See: https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1286
# Therefore, we are using the kubectl to patch coredns using the Kubernetes API.
# resource "shell_script" "coredns_fargate_patch" {
#   lifecycle_commands {
#     create = file("${path.module}/scripts/patch_coredns_for_fargate.sh")
#   }

#   # Wait for the EKS module to get provisioned completely including the kube-system Fargate profile.
#   depends_on = [module.eks]
# }
