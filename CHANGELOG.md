# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.1] - 2022-03-24

### Added

- `README.md` explaining details of this repository and its use
- Python FastAPI demo application including
- Helm chart for deploying demo application
- Terraform module to deploy AWS EKS cluster with application load balancer, `fargate`-profile, and one EC2 host
- Terraform module to deploy demo application onto AWS EKS cluster
- `run.sh` to streamline deployment of all components
