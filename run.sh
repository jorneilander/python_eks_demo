#!/usr/bin/env bash

# set -x
set -e

SCRIPT_PATH=$(realpath "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")
CONF_PATH="${SCRIPT_DIR}/run.conf"
WORKDIR="$(pwd)"

echo "Checking if script is run from it's directory"
[[ "${SCRIPT_DIR}" != "${WORKDIR}" ]] && (
  echo "Ensure you're running this script from it's directory ${SCRIPT_DIR}, exiting"
  exit 1
)

echo "Including configuration found in ${CONF_PATH}"
# shellcheck source=run.conf
. "${CONF_PATH}"

REQUIRED_COMMANDS=(
  docker
  terraform
  helm
  aws
  curl
  kubectl
  jq
)

REQUIRED_ENV_VARIABLES=(
  "${AWS_ACCESS_KEY_ID}"
  "${AWS_SECRET_ACCESS_KEY}"
  "${AWS_REGION}"
)

TERRAFORM_ROOT_PATH="${SCRIPT_DIR}/terraform"
TERRAFORM_EKS_CLUSTER_PATH="${TERRAFORM_ROOT_PATH}/cluster"
TERRAFORM_APPLICATION_PATH="${TERRAFORM_ROOT_PATH}/demo_application"

echo "Checking if all required CLI commands are available"
for COMMAND in "${REQUIRED_COMMANDS[@]}"; do
  command -v "${COMMAND}" 1>/dev/null 2>&1 || (
    echo "Can't find the '${COMMAND}' command, exiting"
    exit 1
  )
done

echo "Checking if all the required environment variables are available"
for ENV_VAR in "${REQUIRED_ENV_VARIABLES[@]}"; do
  [[ -z "${ENV_VAR}" ]] && (
    "Some required environment variables are not set, please check ${CONF_PATH} and try again, exiting"
    exit 1
  )
done

function check_for_running_docker() {
  echo "Checking if Docker is running"
  docker info 1>/dev/null 2>&1 || (
    echo "Please start Docker en rerun this script, exiting"
    exit 1
  )

  return 0
}

# Configuration
echo "Fetching public IP address"
PUBLIC_IP_ADDRESS=$(curl --silent ipinfo.io/ip)
[[ ! "${PUBLIC_IP_ADDRESS}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && (
  echo "Could not determine public IP-address, exiting"
  exit 1
)

## Give Terraform access to specific variables
export TF_VAR_public_access_cidrs="[\"${PUBLIC_IP_ADDRESS}/32\"]"
export TF_VAR_vpc_name="demo_application"
export TF_VAR_helm_app_release_namespace="${HELM_APP_NAMESPACE}"
export TF_VAR_image_repository_name="demo_application"
export TF_VAR_helm_app_release_name="${HELM_APP_RELEASE_NAME}"
export TF_VAR_eks_cluster_name="${AWS_EKS_CLUSTER_NAME}"
export TF_VAR_demo_root_response="${DEMO_ROOT_RESPONSE}"
export TF_VAR_demo_api_response="${DEMO_API_RESPONSE}"

# Function definitions
function confirm_action() {
  clear

  echo -e "##################################################################################"
  echo -e "${1}"
  echo -e "##################################################################################"
  echo ""
  read -n 1 -p "Press any key to continue"
  echo ""

  return 0
}

function deploy_cluster() {
  cd "${TERRAFORM_EKS_CLUSTER_PATH}" || (
    echo "Can't 'cd' into ${TERRAFORM_EKS_CLUSTER_PATH}, exiting"
    exit 1
  )

  confirm_action "Warning: This will install an EKS cluster on AWS which will cost money!"

  terraform init
  terraform apply 2>&1 || (
    echo "Terraform could not deploy the EKS cluster, exiting"
    exit 1
  )

  return 0
}

function deploy_application() {
  cd "${TERRAFORM_APPLICATION_PATH}" || (
    echo "Can't 'cd' into ${TERRAFORM_APPLICATION_PATH}, exiting"
    exit 1
  )

  check_for_running_docker

  [[ "$1" != "skip_confirmation" ]] && confirm_action "Warning: This will install the demo application onto the EKS cluster which will cost money!"

  terraform init

  terraform apply 2>&1 || (
    echo "Terraform could not deploy the application, are you sure the cluster is deployed and its state available in:"
    echo "${TERRAFORM_EKS_CLUSTER_PATH}"
    echo "exiting"
    exit 1
  )

  return 0
}

function use_context_in_kubeconfig() {
  echo "Updating 'kubeconfig' with the created cluster using 'aws'"
  aws eks update-kubeconfig --region "${AWS_REGION}" --name "${AWS_EKS_CLUSTER_NAME}"

  echo "Enabling context for kubectl with created cluster"
  kubectl config use-context "$(kubectl config get-clusters | grep ${AWS_EKS_CLUSTER_NAME})"

  return 0
}

function get_lb_app_ingress_hostname() {
  echo "Fetching ingress hostname for demo application"
  LB_APP_INGRESS_HOSTNAME=$(kubectl get ingress ${HELM_APP_RELEASE_NAME} \
    -n ${HELM_APP_NAMESPACE} \
    -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')

  [[ "$1" != "skip_confirmation" ]] && (
    confirm_action "Application endpoints can be found at:\n \
    -> http://${LB_APP_INGRESS_HOSTNAME}/ \n \
    -> http://${LB_APP_INGRESS_HOSTNAME}/api \n \
    -> http://${LB_APP_INGRESS_HOSTNAME}/metrics"
  )

  return 0
}

function destroy_cluster() {
  confirm_action "This will destroy the AWS EKS cluster!"
  cd "${TERRAFORM_EKS_CLUSTER_PATH}" || (
    echo "Can't 'cd' into ${TERRAFORM_EKS_CLUSTER_PATH}, exiting"
    exit 1
  )

  terraform destroy 2>&1 || (
    echo "Terraform could not destroy the cluster, exiting"
    exit 1
  )

  return 0
}

function destroy_application() {
  confirm_action "This will destroy the deployed application!"
  cd "${TERRAFORM_APPLICATION_PATH}" || (
    echo "Can't 'cd' into ${TERRAFORM_APPLICATION_PATH}, exiting"
    exit 1
  )

  terraform destroy 2>&1 || (
    echo "Terraform could not destroy the application, are you sure the cluster is deployed and its state available in:"
    echo "${TERRAFORM_EKS_CLUSTER_PATH}"
    echo "exiting"
    exit 1
  )

  return 0
}

function destroy_all() {
  confirm_action "This will destroy all objects created by Terraform!"

  destroy_application
  destroy_cluster

  return 0
}

function update_app_responses() {
  get_lb_app_ingress_hostname

  confirm_action "Updating responses at:
    -> http://${LB_APP_INGRESS_HOSTNAME}
    and:
    -> http://${LB_APP_INGRESS_HOSTNAME}/api"
  echo "Please provide a new response for ${LB_APP_INGRESS_HOSTNAME}"
  read -p "(currently: '$(curl --silent "${LB_APP_INGRESS_HOSTNAME}")'): "
  export TF_VAR_demo_root_response="${REPLY}"
  echo ""
  echo "Please provide news response for ${LB_APP_INGRESS_HOSTNAME}/api"
  read -p "(currently: '$(curl --silent "${LB_APP_INGRESS_HOSTNAME}"/api)'): "
  export TF_VAR_demo_api_response="${REPLY}"

  deploy_application "skip_confirmation"
  get_lb_app_ingress_hostname

  return 0
}

function update_app_version() {
  get_lb_app_ingress_hostname skip_confirmation

  confirm_action "Updating application version"

  echo "Please provide a version"
  read -p "(currently: $(curl --silent "${LB_APP_INGRESS_HOSTNAME}/api"  | jq .version)): "
  export TF_VAR_demo_app_version="${REPLY}"

  deploy_application "skip_confirmation"
  get_lb_app_ingress_hostname

  return 0
}

case "$1" in
deploy-cluster)
  deploy_cluster
  exit 0
  ;;
deploy-application)
  deploy_application
  exit 0
  ;;
set-kubectl-context)
  use_context_in_kubeconfig
  exit 0
  ;;
get-hostname)
  get_lb_app_ingress_hostname
  exit 0
  ;;
update-responses)
  update_app_responses
  exit 0
  ;;
update-version)
  update_app_version
  exit 0
  ;;
destroy-cluster)
  destroy_cluster
  exit 0
  ;;
destroy-application)
  destroy_application
  exit 0
  ;;
destroy-all)
  destroy_all
  exit 0
  ;;
help)
  echo "Usage:"
  echo "    run.sh                        Deploy all components as assigned"
  echo "    run.sh deploy-cluster         Deploy the AWS EKS cluster"
  echo "    run.sh deploy-application     Deploy the application onto the AWS EKS cluster"
  echo "    run.sh set-kubectl-context    Get and enable AWS EKS configuration for kubectl"
  echo "    run.sh get-hostname           Get the hostname for the deployed application"
  echo "    run.sh update-responses       Update the responses for the deployed application and redeploy"
  echo "    run.sh update-version         Update application version"
  echo "    run.sh destroy-cluster        Destroy AWS EKS cluster"
  echo "    run.sh destroy-application    Destroy deployed application"
  echo "    run.sh destroy-all            Destroy all components"
  echo "    run.sh help                   Display this help message."
  exit 0
  ;;
*)
  [[ -z "$1" ]] || (
    echo "Run 'run.sh help' for instructions, exiting"
    exit 1
  )
  deploy_cluster
  deploy_application
  use_context_in_kubeconfig
  get_lb_app_ingress_hostname
  update_app_version
  destroy_all
  ;;
esac
