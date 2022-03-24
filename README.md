# Python EKS Demo

The purpose of this repository is to demonstrate the combination of several technologies in order to automate the deployment of a Python application onto AWS [EKS](https://aws.amazon.com/eks/).

The repository is set up to my personal workflow, which includes the use of [`direnv`](https://direnv.net/).
`direnv` will try to setup a Python [`venv`](https://docs.python.org/3/library/venv.html) in `.venv/` and install all packages required to run and test the Python FastAPI application found in [./demo_application](./demo_application).

## Small warning

Prior to this I had _no_ experience with AWS nor Terraform.
Therefor this repository is doing most of the heavy lifting using Terraform, even when not pragmatic... (looking at you `docker` and `helm`)

## tl;dr

- Clone this repository
- Add AWS credentials to `run.conf`
- Execute `run.sh`

## Components

### run.sh

[`run.conf`](./run.conf) will try to determine whether all prerequisites are available on the machine and execute the following steps in order using the configuration found in `run.conf`:

- Deploy the AWS EKS cluster
- Deploy the application
- Download and enable the `kubeconfig` configuration for the cluster
- Show the URLs to access the application's endpoints
- Update the app version via user entry
- Remove the entire setup from AWS

It does so by requesting user input at every relevant stage using the `confirm_action()` function.

```TXT
Usage:
    run.sh                        Deploy all components as assigned
    run.sh deploy-cluster         Deploy the AWS EKS cluster
    run.sh deploy-application     Deploy the application onto the AWS EKS cluster
    run.sh set-kubectl-context    Get and enable AWS EKS configuration for kubectl
    run.sh get-hostname           Get the hostname for the deployed application
    run.sh update-responses       Update the responses for the deployed application and redeploy
    run.sh update-version         Update application version
    run.sh destroy-cluster        Destroy AWS EKS cluster
    run.sh destroy-application    Destroy deployed application
    run.sh destroy-all            Destroy all components
    run.sh help                   Display this help message.
```

#### Design decisions

- Verification
  The script determines whether all requirements for using the script are in place (e.g., AWS credentials, `kubectl`, running `docker` service), and whether the script is run from the directory.
- Configurable
  The primary configuration for the script is offloaded to `run.conf`, allowing the configuration to remain simple.
- Step-by-step
  By asking for user input in between important stages of running the script (e.g., deploying the cluster) it acts as a guided journey through the actions it performs.
  
### run.conf

The file [`run.conf`](./run.conf) contains a set of required variables needed in order to succesfully run all scripts.

| Key                     | Required | Default                   | Description                                                   |
| ----------------------- | -------- | ------------------------- | ------------------------------------------------------------- |
| `AWS_ACCESS_KEY_ID`     | Yes      | ""                        | AWS IAM user access key id                                    |
| `AWS_SECRET_ACCESS_KEY` | Yes      | ""                        | AWS IAM secret access key associated with `AWS_ACCESS_KEY_ID` |
| `AWS_REGION`            | Yes      | "_eu-central-1_"          | AWS region in which the cluster will be spun up               |
| `DEMO_ROOT_RESPONSE`    | Yes      | "_Welcome to ReaQta_"     | Application response message for `http://{URL}/`              |
| `DEMO_API_RESPONSE`     | Yes      | "_Welcome to ReaQta API_" | Application response message for `http://{URL}/api`           |
| `AWS_EKS_CLUSTER_NAME`  | Yes      | "_eks_python_demo_"       | AWS EKS cluster name                                          |
| `HELM_APP_NAMESPACE`    | Yes      | "_demo-application_"      | Namespace in which the application will be deployed           |
| `HELM_APP_RELEASE_NAME` | Yes      | "_demo-application_"      | Helm release name used during deployment                      |

### Python - Demo Application

Found in in [./demo_application](./demo_application/), it's a small [FastAPI](https://fastapi.tiangolo.com/) based service with three endpoints:, `/`, `/api`, `/metrics`.
The application is configurable using the [`config.ini`](./demo_application/config.ini) file, which lists the keys used to determine the output for the `/`, and `/api` endpoints.
This defaults to the environment variables `DEMO_ROOT_RESPONSE`, and `DEMO_API_RESPONSE`, since this allows us to easily manipulate them using [Helm](https://helm.sh/) after deployment.

The `/metrics` endpoint is created using the [`starlette_exporter`](https://github.com/stephenhillier/starlette_exporter) module, which automagically adds all relevant metrics for FastAPI endpoints.
In an actual production environment with up- and/or downstream dependencies a [`/health` endpoint](https://datatracker.ietf.org/doc/html/draft-inadarei-api-health-check) should be created to be used by [Kubernetes](https://kubernetes.io/) probes to determine the status of the application.

#### Design decisions

- Environment variables  
  Since the assignment requires manipulation of the response given by the `/` and `/api` endpoints an easy method is to use environment variables and restart pods.
  Two other methods would be to have an `/update/{endpoint}` endpoint and have the application communicate with the cluster to update itself and all other instances.
  This can be arranged by updating a `ConfigMap` and reload the configuration every x-amount of seconds.
- Metrics endpoint  
  Metrics are key to keep track of the statistics of a running application, not specific to containers.
- Testing  
  By testing all functionality it becomes apparent when regression occurs during development.
  Test are made using [`pytest`](https://docs.pytest.org/).

### Helm - Chart

Located in [./helm/eks_python_demo](./helm/eks_python_demo), it allows for the deployment of the application onto any container platform.

#### Design decisions

- Missing image repository  
  Considering the image repository is generated during the deployment of the application by [Terraform](https://www.terraform.io/) the actual URL is unknown at time of defining the values.
  It could potentially be predicted by getting user ID's via `aws`.
- Sane defaults  
  Simply because it's good practice and allows for an easy example for other engineers.
- Security settings  
  Even though this is a simple application, standard security practices still apply.
  Enforcing `securityContexts` such as `runAsRoot: False` ensure an added layer of security is added.
  When running multiple applications inside the same `namespace` would warrant seperate `serviceAccounts` with specific privileges, but for this specific use case it's not required.

#### Terraform - Cluster

This deploys an EKS cluster using the `terraform-aws-modules/eks/aws` module, including [`vpc`](https://aws.amazon.com/vpc/), [`kms`](https://aws.amazon.com/kms/) key, and [application load balancer](https://aws.amazon.com/elasticloadbalancing/) with corresponding `fargate`-profile.

The cluster was initially meant to only be using [`fargate`](https://aws.amazon.com/fargate/) since it allows for efficiency in automated scaling of resources, but this wasn't possible to a an issue with AWS's deployment for `core-dns`.
The annotations for `core-dns` require for it to be deployed on an [`EC2`](https://aws.amazon.com/ec2/) node, which isn't available during deployment.
This means the deployment will fail, and Terraform will not be able to continue.

Therefor an added `EC2` managed node group is added to allow for it to be deployed, using a [`bottlerocket`](https://aws.amazon.com/bottlerocket/) image.

##### Design decisions

- Environment variables  
  Using environment variables it allows for certain settings to be synchronized between components in this repository.
- Application Load Balancer  
  Since we're not using groups of classic `EC2`-hosts, an ALB allows for further finegrained forwarding of traffic than an ELB.
- Security Group Rules  
  The implemented modules uses the [AWS recommended standards](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html) + [NTP](https://en.wikipedia.org/wiki/Network_Time_Protocol)/HTTPS for `EC2`, which I deem secure enough for this exercise.

#### Terraform - Application

This Terraform creates an [`ECR`](https://aws.amazon.com/ecr/) for the demo application, builds the image locally using `docker` and pushes it afterwards.
Before deploying the application, an added `fargate` is created, after which the application is deployed using Helm.
Using Docker and Helm via Terraform was a nice experiment but proofs to be a hassle when encountering issues within the image.

For some reason the Terraform module is unable to determin whether changes to the Dockerfile have been created, or whether the image hash of the local image is different from the one in the `ECR`.
This means any changes aren't propagated to the cluster.
It also doesn't allow for multiple tags for uploaded images.
I'll have to change it out for building and deploying using the `run.sh` script eventually.

After having deployed the application initially, `run.sh` will ask for user input to modify the messages returned by the `/` and `/api` endpoints.
It will rerun the module and redeploy it with the new settings.

##### Design decisions

- Small and secure base image using [distroless](https://github.com/GoogleContainerTools/distroless)
  Using a `nonroot-distroless` base image allows for an even greater level of security, since it lacks most of the standard tools found on a distro based image.
  The Python version does contain a shell though, making it slightly less secure than then the Java one.
  At the time of writing, the `ECR` did not register any known vulnerabilities in the image.

## Known issues

### Full Fargate deployment

Full Fargate deployment is currently impossible due to [an issue](https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-gs-coredns) with deploying `core-dns` on EKS clusters using `fargate`.

### Unpragmatic application versioning output and upgrading

The use of the [`kreuzwerker/docker`](https://github.com/kreuzwerker/terraform-provider-docker) Terraform provider for building and releasing the application by indirectly calling `docker` and `helm` has proven to be suboptimal at best.
It lacks the ability to keep a decent set of states, allow for multiple tags, etc.
It will have to be redesigned to use Docker and Helm directly.

Updating the responses of the application in combination with version in the application is also suboptimal.
This is basically a direct cause of using `kreuzwerker/docker` Terraform provider, updating environment variables for the deployed pod was easier.
This will have to be redesigned to rebuild the image, tag it with a new version, update the `appVersion` in the Helm chart and use this for version.
