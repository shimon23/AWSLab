# AWSLab Demo Project

This repository contains all the code, configuration, and documentation for the **AWSLab** GitOps demo application, deployed on Amazon EKS with ArgoCD and a CI/CD pipeline via AWS CodePipeline and CodeBuild.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Repository Structure](#repository-structure)
5. [Infrastructure Setup (Phase 1)](#infrastructure-setup-phase-1)
6. [Application Deployment with ArgoCD](#application-deployment-with-argocd)
7. [CI/CD Pipeline (Phase 2)](#cicd-pipeline-phase-2)
8. [Working Locally](#working-locally)
9. [Helm Chart Configuration](#helm-chart-configuration)
10. [Troubleshooting & Tips](#troubleshooting--tips)

---

## Project Overview

The AWSLab demo project showcases a full GitOps workflow on AWS:

* **Amazon EKS** cluster for Kubernetes workloads
* **ArgoCD** for declarative, GitOps-based application delivery
* **Helm** charts to package and manage Kubernetes manifests
* **AWS CodePipeline** & **CodeBuild** for CI/CD: building Docker images, pushing to ECR, and triggering deployments
* **RDS (MySQL)** for persistent data storage
* A simple Node.js + NGINX "Hello Commit" application with a `/db` endpoint that reads from the database

---

## Architecture

```
+-----------+      +---------------+      +-------------+
| Developer |➔ Push to GitHub Repo ➔ CodePipeline ➔ CodeBuild |
+-----------+      +---------------+      +-------------+
                               |                         |
                               ▼                         ▼
                     +----------------+          +----------------+
                     | ECR Repository |◀─ push ─┤ RDS MySQL DB    |
                     +----------------+          +----------------+
                               |
                               ▼
                    +------------------+
                    | ArgoCD (helm)    |
                    | Ingress at /argo |─────▶ Kubernetes EKS (2 nodes)
                    +------------------+
                               |
                               ▼
                    +------------------+
                    | AWSLab App Pods  |
                    +------------------+
```

---

## Prerequisites

* AWS CLI configured with admin privileges
* `kubectl`, `eksctl`, `helm` installed and in PATH (PowerShell or Bash)
* An existing EKS cluster (Phase 1 completion)
* Node.js & Docker (for local development)

---

## Repository Structure

```
/                   # project root
├── buildspec.yml          # AWS CodeBuild spec
├── Dockerfile             # Node.js / NGINX app image
├── app.js                 # ExpressJS + MySQL code
├── public/                # Static assets (index.html, logo.png)
├── AWSLab-chart/          # Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
├── infrastructure/        # Infra-as-code snippets
│   └── argocd-server-ingress.yaml
└── pipeline.json          # CodePipeline definition template
```

---

## Infrastructure Setup (Phase 1)

1. **VPC & Networking**:

   ```bash
   eksctl create cluster \
     --name eks-lab-4 \
     --region eu-north-1 \
     --vpc-private-subnets=<subnet-ids> \
     --vpc-public-subnets=<subnet-id> \
     --nodes 2 --node-type t3.medium
   ```
2. **ArgoCD Installation**:

   ```bash
   helm repo add argo https://argoproj.github.io/argo-helm
   helm repo update
   helm install argocd argo/argo-cd \
     --namespace argocd --create-namespace
   ```
3. **Expose ArgoCD via Ingress**:

   ```bash
   kubectl apply -f infrastructure/argocd-server-ingress.yaml
   ```

---

## Application Deployment with ArgoCD

1. **Package & Push Helm chart** to GitHub repo
2. **Create ArgoCD Application**:

   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: awslab-app
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: https://github.com/your-org/AWSLab.git
       targetRevision: master
       path: AWSLab-chart
     destination:
       server: https://kubernetes.default.svc
       namespace: default
     syncPolicy:
       automated: {}
   ```
3. **Sync & Verify**:

   ```bash
   argocd app sync awslab-app
   argocd app list
   ```

---

## CI/CD Pipeline (Phase 2)

1. **CodePipeline & CodeBuild**:

   * Source: GitHub repo with webhook
   * Build: `buildspec.yml` builds Docker image, tags by commit SHA, pushes to ECR
   * Deploy stage (GitOps): triggers ArgoCD sync or updates `values.yaml` with new tag

2. **buildspec.yml**:

   * `pre_build`: AWS ECR login & TAG extraction
   * `build`: `docker build -t $ECR_REPO:$TAG .`
   * `post_build`: push images to ECR

---

## Working Locally

* **Run app**:

  ```bash
  docker build -t aws-lab:test .
  docker run -p 3000:3000 aws-lab:test
  # browse http://localhost:3000/ and http://localhost:3000/db
  ```

* **Kubectl Port-Forward ArgoCD**:

  ```bash
  kubectl port-forward svc/argocd-server -n argocd 8080:443
  # browse https://localhost:8080/argo
  ```

---

## Helm Chart Configuration

* **values.yaml** controls:

  * `image.repository`, `image.tag`
  * `service.type`, `service.port`
  * `ingress.enabled`, `ingress.hosts[]`, `ingress.annotations`
  * `db.host`, `db.port`, `db.name`, `db.secretName`

* **Templates**:

  * `deployment.yaml`: sets env vars for DB
  * `service.yaml`: ClusterIP on port 80
  * `ingress.yaml`: path `/` → awslab-service

---

## Troubleshooting & Tips

* **ArgoCD UI Loop**: ensure `--rootpath=/argo` and matching Ingress prefix
* **Docker build errors**: test locally with `docker build .`
* **CodeBuild permissions**: add S3 `PutObject` policy
* **Cache issues**: clear browser cache & disable caching in DevTools

---

**Enjoy your GitOps journey!**
