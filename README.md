# 🚀 Lucidity Assignment Workspace

> ☁️ Terraform + 🐳 Docker + ☸️ EKS + 🔄 Argo CD + 📊 Monitoring

This repository contains Terraform code for provisioning AWS networking and Amazon EKS infrastructure, along with application, Helm, and monitoring assets.

## 📁 Repository structure

- [`terraform/`](terraform) - Terraform modules and environment stacks.
- [`terraform/environments/dev/`](terraform/environments/dev) - Development environment with VPC, IAM, EKS, security groups, route tables, and EKS access entries.
- [`terraform/environments/prod/`](terraform/environments/prod) - Production environment with VPC and EKS resources.
- [`helm/`](helm) - Helm-related assets.
- [`app/`](app) and [`hello-world/`](hello-world) - Application source directories.
- [`monitoring/`](monitoring) - Monitoring manifests and charts.

## 🧱 Terraform layout

### Overall Architecture

```
                                  Git Repository
                                        │
            ┌───────────────────────────┴───────────────────────────┐
            │                                                       │
            ▼                                                       ▼
  terraform-bootstrap                                   terraform (EKS Platform)
  (Run Once)                                            (Run Every Deployment)
            │                                                       │
            │                                                       │
            ▼                                                       ▼
     Creates Backend                                      Uses Remote Backend
            │                                                       │
            ├───────────────────────────────────────────────────────┐
            │                                                       │
            ▼                                                       ▼
    ┌────────────────┐                                   ┌────────────────────┐
    │ S3 State Bucket│◄──────────── terraform.tfstate ───│ Terraform CLI       │
    └────────────────┘                                   └────────────────────┘
            │
            │
    ┌────────────────┐
    │ DynamoDB Lock  │
    └────────────────┘
            │
            │
    ┌────────────────┐
    │ AWS KMS Key    │
    └────────────────┘
            │
            │
    ┌────────────────┐
    │ IAM Role       │
    └────────────────┘
```

### AWS Infrastructure Provisioning

```
                         Developer / Jenkins
                                 │
                                 │
                         terraform apply
                                 │
                                 ▼
                      environments/dev or prod
                                 │
          ┌──────────────────────┴──────────────────────┐
          │                                             │
          ▼                                             ▼
     VPC Module                                   EKS Module
          │                                             │
          │                                             │
 ┌────────────────────┐                     ┌────────────────────┐
 │ VPC                │                     │ EKS Cluster        │
 │ Internet Gateway   │                     │ Control Plane      │
 │ Public Subnets     │                     │ Managed Node Groups│
 │ Private Subnets    │                     │ IAM Roles          │
 │ NAT Gateway        │                     │ EKS Add-ons        │
 │ Route Tables       │                     │ Security Groups    │
 └────────────────────┘                     └────────────────────┘
                    │
                    ▼
           AWS Kubernetes Platform
```

The development stack in [`terraform/environments/dev/main.tf`](terraform/environments/dev/main.tf) provisions:

- VPC and subnets through [`module "vpc"`](terraform/environments/dev/main.tf:1)
- Route tables through [`module "route_tables"`](terraform/environments/dev/main.tf:29)
- Network ACLs through [`module "network_acl"`](terraform/environments/dev/main.tf:59)
- Security groups through [`module "security_groups"`](terraform/environments/dev/main.tf:86)
- IAM roles through [`module "iam"`](terraform/environments/dev/main.tf:103)
- EKS access entries through [`module "eks_access"`](terraform/environments/dev/main.tf:110)
- EKS cluster and managed node groups through [`module "eks"`](terraform/environments/dev/main.tf:132)

The production stack in [`terraform/environments/prod/main.tf`](terraform/environments/prod/main.tf:1) currently provisions VPC and EKS only.

## ✅ Prerequisites

Install and configure the following:

- Terraform
- AWS CLI v2
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/)
- An AWS IAM identity with permission to manage IAM, VPC, EKS, S3 backend state, and DynamoDB state locking

Configure AWS credentials before running Terraform:

```bash
aws configure
aws sts get-caller-identity
```

## 🗂️ Terraform remote state

Both environments use an S3 backend with DynamoDB locking:

- Dev backend: [`terraform/environments/dev/backend.tf`](terraform/environments/dev/backend.tf:1)
- Prod backend: [`terraform/environments/prod/backend.tf`](terraform/environments/prod/backend.tf:1)

Configured backend resources:

- S3 bucket: `lucidity-prod-terraform-state`
- DynamoDB table: `terraform-lock`
- Region: `us-east-1`

### Terraform bootstrap steps

Instead of creating the backend resources manually, use the bootstrap stack in [`terraform-bootstrap/`](terraform-bootstrap). This stack provisions:

- A KMS key through [`module "kms"`](terraform-bootstrap/main.tf:1)
- An S3 state bucket through [`module "state_bucket"`](terraform-bootstrap/main.tf:10)
- A DynamoDB lock table through [`module "dynamodb"`](terraform-bootstrap/main.tf:21)
- A Terraform deployment IAM role through [`module "terraform_role"`](terraform-bootstrap/main.tf:30)

Bootstrap defaults are defined in [`terraform-bootstrap/terraform.tfvars`](terraform-bootstrap/terraform.tfvars:1):

- State bucket: `lucidity-prod-terraform-state`
- Lock table: `terraform-lock`
- Region: `us-east-1`
- KMS alias: `terraform-state-key`
- IAM role: `terraform-deployment-role`

### 1. Review the bootstrap configuration

Check the provider and variables in [`terraform-bootstrap/providers.tf`](terraform-bootstrap/providers.tf:1), [`terraform-bootstrap/variables.tf`](terraform-bootstrap/variables.tf:1), and [`terraform-bootstrap/terraform.tfvars`](terraform-bootstrap/terraform.tfvars:1).

### 2. Initialize the bootstrap stack

```bash
cd terraform-bootstrap
terraform init
terraform fmt -recursive
terraform validate
```

### 3. Review the execution plan

```bash
terraform plan -var-file=terraform.tfvars
```

### 4. Apply the bootstrap stack

```bash
terraform apply -var-file=terraform.tfvars
```

### 5. Confirm the backend resources were created

The bootstrap modules create the S3 bucket, KMS encryption, public access block, DynamoDB lock table, and IAM role in:

- [`terraform-bootstrap/modules/s3-state-bucket/main.tf`](terraform-bootstrap/modules/s3-state-bucket/main.tf:1)
- [`terraform-bootstrap/modules/kms-key/main.tf`](terraform-bootstrap/modules/kms-key/main.tf:1)
- [`terraform-bootstrap/modules/dynamodb-lock/main.tf`](terraform-bootstrap/modules/dynamodb-lock/main.tf:1)
- [`terraform-bootstrap/modules/iam-role/main.tf`](terraform-bootstrap/modules/iam-role/main.tf:1)

You can verify the created resources with:

```bash
aws s3api head-bucket --bucket lucidity-prod-terraform-state
aws dynamodb describe-table --table-name terraform-lock --region us-east-1
aws kms list-aliases --region us-east-1
aws iam get-role --role-name terraform-deployment-role
```

### 6. Use the provisioned backend for environment deployments

After the bootstrap stack succeeds, run [`terraform init`](terraform/environments/dev/backend.tf:1) in [`terraform/environments/dev/`](terraform/environments/dev) or [`terraform/environments/prod/`](terraform/environments/prod).

## ⚙️ Deploying with Terraform

### Development

```bash
cd terraform/environments/dev
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

### Production

```bash
cd terraform/environments/prod
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## 🔐 IAM roles created by Terraform

The IAM module creates roles from the `roles` map defined in [`terraform/environments/dev/terraform.tfvars`](terraform/environments/dev/terraform.tfvars:76) using [`aws_iam_role.this`](terraform/modules/iam/main.tf:1) and attaches AWS managed policies using [`aws_iam_role_policy_attachment.this`](terraform/modules/iam/main.tf:11).

Current development roles:

- `devops`
- `developers`
- `readonly`
- `jenkins`

The role ARNs are exposed through [`output "role_arns"`](terraform/modules/iam/outputs.tf:1) and are consumed by [`module "eks_access"`](terraform/environments/dev/main.tf:110).

## ☸️ EKS cluster access using IAM and kubeconfig

EKS access entries are created by [`aws_eks_access_entry.this`](terraform/modules/eks-access/main.tf:1) and policy associations are created by [`aws_eks_access_policy_association.this`](terraform/modules/eks-access/main.tf:12). These entries authorize IAM principals to access the cluster.

### Get the cluster name

The EKS module exports the cluster name through [`output "cluster_name"`](terraform/modules/eks/outputs.tf:1).

Example:

```bash
aws eks list-clusters --region us-east-1
```

### Option 1: direct IAM user access with kubeconfig

If an IAM user is the identity running the AWS CLI and that IAM user has been granted EKS access, generate kubeconfig with:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name dev-eks
```

Verify access:

```bash
kubectl config current-context
kubectl get nodes
kubectl get ns
```

### Option 2: assume an IAM role and generate kubeconfig

If cluster access is granted to an IAM role such as `devops`, assume the role first or use the role directly in kubeconfig generation:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name dev-eks \
  --role-arn arn:aws:iam::<account-id>:role/devops
```

Then validate:

```bash
kubectl get nodes
kubectl auth can-i get pods --all-namespaces
```

### Inspect configured EKS access entries

```bash
aws eks list-access-entries \
  --cluster-name dev-eks \
  --region us-east-1
```

## 🤖 Jenkins agent access from EC2 IAM role

The `jenkins` IAM role is declared in [`terraform/environments/dev/terraform.tfvars`](terraform/environments/dev/terraform.tfvars:103). To use this for deployments from a Jenkins agent running on EC2:

1. Create or use an EC2 instance profile that can assume or directly uses the `jenkins` role.
2. Attach the instance profile to the Jenkins agent EC2 instance.
3. Ensure the `jenkins` role is included in EKS access entries so it can authenticate to the cluster.
4. On the Jenkins agent, confirm credentials are coming from the instance metadata service:

```bash
aws sts get-caller-identity
```

5. Generate kubeconfig on the Jenkins agent:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name dev-eks \
  --role-arn arn:aws:iam::<account-id>:role/jenkins
```

6. Use [`kubectl`](https://kubernetes.io/docs/tasks/tools/) or Helm in the pipeline for deployments:

```bash
kubectl get nodes
helm list -A
```

If the EC2 instance profile is already the same IAM role authorized in EKS, the `--role-arn` argument can be omitted.

## 🧪 Deploy Application on Test Environment

Before deploying the application manually on Kubernetes, complete the Minikube setup by following the prerequisite guide:

📖 [Setting Up Minikube Kubernetes Cluster](./setup-minikube-k8s.md)

## 🌍 Manual deployment steps for the Hello World stack

The application chart is defined in [`hello-world/Chart.yaml`](hello-world/Chart.yaml:1) and its default deployment settings are in [`hello-world/values.yaml`](hello-world/values.yaml:1).

### 1. Connect to the target EKS cluster

Use the kubeconfig flow described earlier in this README and confirm cluster access:

```bash
kubectl get nodes
kubectl get ns
```

### 2. Verify Helm is installed

```bash
helm version
```

### 3. Create or confirm the target namespace

The default service target in the monitoring values points to `hello-world.default.svc.cluster.local`, so the app should be deployed into the `default` namespace unless you also update [`monitoring/prom_values.yaml`](monitoring/prom_values.yaml:1).

```bash
kubectl get namespace default || kubectl create namespace default
```

### 4. Review the Hello World chart values

Important defaults from [`hello-world/values.yaml`](hello-world/values.yaml:25):

- Service type: `ClusterIP`
- Service port: `8080`
- Image tag: `e7f8af15462b66626d103364473ac14142b229d4`
- Replicas: `2`
- Application access should be routed through the NGINX ingress endpoint `http://52.118.214.122/`

### 6. Deploy the Hello World chart

```bash
helm upgrade --install hello-world ./hello-world \
  --namespace default \
  -f ./hello-world/values.yaml
```

### 7. Verify the application deployment

```bash
kubectl get deploy,po,svc -n default
kubectl rollout status deployment/hello-world -n default
kubectl describe svc hello-world -n default
```

### 8. Test application access through NGINX Ingress

Use the shared ingress endpoint `http://52.118.214.122/` to access the Hello World application.

```bash
kubectl get svc,ingress -n default
curl http://52.118.214.122/
curl http://52.118.214.122/metrics
```

## 🐳 Docker registry secret for private image pulls

The Hello World chart is configured to use the Docker registry secret in [`imagePullSecrets`](hello-world/values.yaml:20).

### 1. Create the Docker Hub pull secret

Create the Kubernetes registry secret in the namespace where the application is deployed.

Example command used for this environment:

```bash
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=amitkumarjai \
  --docker-password='<dockerhub-token>' \
  --docker-email=jaiswarbrothers7083@gmail.com \
  -n default
```

If the secret already exists and you want to refresh it, recreate it with:

```bash
kubectl delete secret dockerhub-secret -n default
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=amitkumarjai \
  --docker-password='<dockerhub-token>' \
  --docker-email=jaiswarbrothers7083@gmail.com \
  -n default
```

### 2. Confirm the secret was created

```bash
kubectl get secret dockerhub-secret -n default
kubectl describe secret dockerhub-secret -n default
kubectl get secret dockerhub-secret -n default -o jsonpath='{.type}'
```

Expected secret type:

```text
kubernetes.io/dockerconfigjson
```

### 3. Helm values configuration

The Helm chart now references the Docker registry secret in [`hello-world/values.yaml`](hello-world/values.yaml:20):

```yaml
imagePullSecrets:
  - name: dockerhub-secret
```

### 4. Deploy or upgrade the chart

```bash
helm upgrade --install hello-world ./hello-world \
  --namespace default \
  -f ./hello-world/values.yaml
```

To verify that Helm renders the pull secret reference before applying, run:

```bash
helm template hello-world ./hello-world -f ./hello-world/values.yaml | grep -A3 imagePullSecrets
```

### 5. Verify image pulls are working

```bash
kubectl describe deployment hello-world -n default
kubectl describe pod -n default -l app.kubernetes.io/name=hello-world
kubectl get events -n default --sort-by=.metadata.creationTimestamp
```

If pods were created before the secret existed, restart the deployment after creating the secret:

```bash
kubectl rollout restart deployment/hello-world -n default
kubectl rollout status deployment/hello-world -n default
```

## 📊 Manual deployment steps for the monitoring stack

The monitoring stack uses the vendored Prometheus chart in [`monitoring/prometheus/Chart.yaml`](monitoring/prometheus/Chart.yaml:1) and the Grafana chart in [`monitoring/grafana/Chart.yaml`](monitoring/grafana/Chart.yaml:1), with overrides in [`monitoring/prom_values.yaml`](monitoring/prom_values.yaml:1) and [`monitoring/graf_values.yaml`](monitoring/graf_values.yaml:1).

### 1. Create the monitoring namespace

```bash
kubectl get namespace monitoring || kubectl create namespace monitoring
```

### 2. Deploy Prometheus

The Prometheus override file configures:

- Cluster-internal service exposure
- `2d` retention
- Static scrape target: `hello-world.default.svc.cluster.local:8080`
- `kube-state-metrics` enabled

Deploy it with:

```bash
helm upgrade --install prometheus ./monitoring/prometheus \
  --namespace monitoring \
  -f ./monitoring/prom_values.yaml
```

Verify the release:

```bash
kubectl get pods,svc -n monitoring
kubectl rollout status deployment/prometheus-server -n monitoring
```

### 3. Confirm Prometheus can scrape the Hello World app

Open Prometheus locally with port-forwarding:

```bash
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
```

Then open `http://127.0.0.1:9090` and check the target status, or query from the CLI:

```bash
kubectl get svc -n monitoring
curl http://127.0.0.1:9090/api/v1/targets
```

### 4. Deploy Grafana

The Grafana override file configures:

- `ClusterIP` service in [`monitoring/graf_values.yaml`](monitoring/graf_values.yaml:11)
- Admin credentials from the existing secret in [`monitoring/graf_values.yaml`](monitoring/graf_values.yaml:17)
- Prometheus datasource pointing to `http://prometheus-server.monitoring.svc.cluster.local`
- Preloaded dashboards from [`monitoring/grafana/dashboards/`](monitoring/grafana/dashboards)
- Subpath access behind NGINX ingress in [`monitoring/graf_values.yaml`](monitoring/graf_values.yaml:1)

Deploy it with:

```bash
helm upgrade --install grafana ./monitoring/grafana \
  --namespace monitoring \
  -f ./monitoring/graf_values.yaml
```

Verify the release:

```bash
kubectl get pods,svc -n monitoring
kubectl rollout status deployment/grafana -n monitoring
```

### 5. Access Grafana through NGINX Ingress

Use the shared ingress endpoint `http://52.118.214.122/` and access Grafana on the `/grafana/` path.

```bash
kubectl get svc,ingress -n monitoring
```

Open `http://52.118.214.122/grafana/` and log in using the credentials stored in the existing Kubernetes secret referenced by [`monitoring/graf_values.yaml`](monitoring/graf_values.yaml:17).

### 6. Validate dashboards and metrics

After login to Grafana:

1. Confirm the Prometheus datasource is healthy.
2. Open the imported `hello-world` dashboard.
3. Open the Kubernetes dashboards shipped from [`monitoring/grafana/dashboards/hello-world.json`](monitoring/grafana/dashboards/hello-world.json), [`monitoring/grafana/dashboards/kubernetes-global.json`](monitoring/grafana/dashboards/kubernetes-global.json), and [`monitoring/grafana/dashboards/kubernetes-cluster.json`](monitoring/grafana/dashboards/kubernetes-cluster.json).
4. Confirm application and cluster metrics are visible.

### 7. Useful operational commands

```bash
helm list -A
helm status hello-world -n default
helm status prometheus -n monitoring
helm status grafana -n monitoring
kubectl get all -n monitoring
kubectl logs deployment/prometheus-server -n monitoring
kubectl logs deployment/grafana -n monitoring
```

### CI/CD architecture diagram

The following architecture describes the end-to-end GitOps flow implemented by this repository:

```text
Developer
    │
    │ git push
    ▼
GitHub Repository
    │
    ▼
GitHub Actions (CI)
    ├── Test
    ├── Lint
    ├── Trivy Scan
    ├── Build Docker Image
    ├── Push Docker Image
    ├── Update Helm values.yaml
    └── Commit values.yaml
             │
             ▼
Git Repository (updated Helm chart)
             │
             ▼
Argo CD (Auto Sync)
             │
             ▼
Helm Upgrade
             │
             ▼
Kubernetes Cluster
```

This flow maps directly to [`.github/workflows/hello-world-ci.yml`](.github/workflows/hello-world-ci.yml:1), the Argo CD Application manifests in [`gitOps-CD/CD-Resource/`](gitOps-CD/CD-Resource), and the live deployment on EKS.

## 🔄 CD with Argo CD

The CD setup is stored in [`gitOps-CD/`](gitOps-CD) and applies Helm charts from this repository into the EKS cluster using Argo CD Applications.

## 🛠️ CI with GitHub Actions

The CI workflow is implemented in [`hello-world app pipeline`](.github/workflows/hello-world-ci.yml:1) and gives end users a clear path to understand how source code changes move from GitHub to Docker Hub and then into GitOps-driven deployment.

### CI repository walkthrough

The main CI assets are:

- Application source in [`app/`](app)
- Container build definition in [`app/Dockerfile`](app/Dockerfile)
- Helm chart in [`hello-world/`](hello-world)
- Monitoring charts in [`monitoring/prometheus/`](monitoring/prometheus) and [`monitoring/grafana/`](monitoring/grafana)
- GitHub Actions workflow in [`.github/workflows/hello-world-ci.yml`](.github/workflows/hello-world-ci.yml:1)

### CI workflow stages

The pipeline runs these jobs from [`.github/workflows/hello-world-ci.yml`](.github/workflows/hello-world-ci.yml:18):

1. [`test`](.github/workflows/hello-world-ci.yml:24) validates the Python app.
2. [`filesystem-scan`](.github/workflows/hello-world-ci.yml:62) runs a Trivy filesystem scan.
3. [`docker`](.github/workflows/hello-world-ci.yml:82) builds and pushes the Docker image.
4. [`image-scan`](.github/workflows/hello-world-ci.yml:124) scans the pushed image.
5. [`helm`](.github/workflows/hello-world-ci.yml:141) lints and renders the Helm charts.
6. [`update-image-tag`](.github/workflows/hello-world-ci.yml:175) updates [`hello-world/values.yaml`](hello-world/values.yaml:17) with the new image tag on `main`.

### CI images

#### GitHub Actions workflow run

![GitHub Actions CI Run](docs/images/github-actions-ci.png)

This image should show the workflow graph for the jobs defined in [`.github/workflows/hello-world-ci.yml`](.github/workflows/hello-world-ci.yml:24).

#### Docker Hub image tags

![Docker Hub Image Tags](docs/images/dockerhub-tags.png)

This image should show the pushed tags that correspond to the image publishing step in [`docker`](.github/workflows/hello-world-ci.yml:103).

### CD repository walkthrough

The main CD assets are:

- Argo CD Helm values in [`gitOps-CD/values.yaml`](gitOps-CD/values.yaml:1)
- Argo CD ingress in [`gitOps-CD/argo-cd-ingress.yaml`](gitOps-CD/argo-cd-ingress.yaml:1)
- Hello World Argo CD app in [`gitOps-CD/CD-Resource/hello-world-CD.yaml`](gitOps-CD/CD-Resource/hello-world-CD.yaml:1)
- Prometheus Argo CD app in [`gitOps-CD/CD-Resource/prometheus.yaml`](gitOps-CD/CD-Resource/prometheus.yaml:1)
- Grafana Argo CD app in [`gitOps-CD/CD-Resource/grafana-cd.yaml`](gitOps-CD/CD-Resource/grafana-cd.yaml:1)
- Hello World ingress in [`k8s-ingress.yml`](k8s-ingress.yml:1)
- Grafana ingress in [`grafana-ingress.yml`](grafana-ingress.yml:1)

### How CD works in this repository

1. GitHub Actions updates [`hello-world/values.yaml`](hello-world/values.yaml:17) with the latest image SHA.
2. Argo CD watches the `main` branch of this repository using the [`repoURL`](gitOps-CD/CD-Resource/hello-world-CD.yaml:11) configured in each Application.
3. Argo CD syncs the Helm chart paths for Hello World, Prometheus, and Grafana.
4. NGINX ingress exposes the deployed services at:
   - Hello World: [`http://52.118.214.122/`](http://52.118.214.122/)
   - Grafana: [`http://52.118.214.122/grafana/`](http://52.118.214.122/grafana/)
   - Argo CD: [`http://52.118.214.122/argocd`](http://52.118.214.122/argocd)

### CD images

#### Argo CD applications view

![Argo CD Applications](docs/images/argocd-applications.png)

This image should show the synced Argo CD Applications created from [`gitOps-CD/CD-Resource/hello-world-CD.yaml`](gitOps-CD/CD-Resource/hello-world-CD.yaml:1), [`gitOps-CD/CD-Resource/prometheus.yaml`](gitOps-CD/CD-Resource/prometheus.yaml:1), and [`gitOps-CD/CD-Resource/grafana-cd.yaml`](gitOps-CD/CD-Resource/grafana-cd.yaml:1).

#### Hello World rollout verification

![Hello World Rollout](docs/images/hello-world-rollout.png)

This image should show rollout and event verification for the deployment managed by Argo CD.

### End-to-end CI/CD walkthrough for users

1. Start in [`app/`](app) to review the application source.
2. Check [`.github/workflows/hello-world-ci.yml`](.github/workflows/hello-world-ci.yml:1) to understand how CI validates, scans, builds, and publishes the image.
3. Review [`hello-world/values.yaml`](hello-world/values.yaml:1) to see how the image tag and Kubernetes settings are defined.
4. Review the Argo CD Applications under [`gitOps-CD/CD-Resource/`](gitOps-CD/CD-Resource) to see how Git becomes the deployment source of truth.
5. Review ingress definitions in [`k8s-ingress.yml`](k8s-ingress.yml:1), [`grafana-ingress.yml`](grafana-ingress.yml:1), and [`gitOps-CD/argo-cd-ingress.yaml`](gitOps-CD/argo-cd-ingress.yaml:1) to understand external access.
6. Open the live endpoints to validate the deployed system:
   - Hello World at [`http://52.118.214.122/`](http://52.118.214.122/)
   - Grafana at [`http://52.118.214.122/grafana/`](http://52.118.214.122/grafana/)
   - Argo CD at [`http://52.118.214.122/argocd`](http://52.118.214.122/argocd)

## 🛡️ Security posture

### Infrastructure security controls

The Terraform bootstrap stack provisions protected remote state components with the following controls:

- KMS encryption for Terraform state in [`aws_kms_key.terraform`](terraform-bootstrap/modules/kms-key/main.tf:1)
- KMS key rotation enabled in [`aws_kms_key.terraform`](terraform-bootstrap/modules/kms-key/main.tf:1)
- S3 bucket versioning enabled in [`aws_s3_bucket_versioning.versioning`](terraform-bootstrap/modules/s3-state-bucket/main.tf:9)
- S3 server-side encryption using KMS in [`aws_s3_bucket_server_side_encryption_configuration.encrypt`](terraform-bootstrap/modules/s3-state-bucket/main.tf:26)
- S3 public access blocked in [`aws_s3_bucket_public_access_block.block`](terraform-bootstrap/modules/s3-state-bucket/main.tf:49)
- DynamoDB state locking in [`aws_dynamodb_table.lock`](terraform-bootstrap/modules/dynamodb-lock/main.tf:1)

### IAM and EKS access security

Cluster access is controlled through dedicated IAM roles and EKS access entries:

- IAM roles are created centrally in [`aws_iam_role.this`](terraform/modules/iam/main.tf:1)
- IAM policies are attached explicitly in [`aws_iam_role_policy_attachment.this`](terraform/modules/iam/main.tf:11)
- EKS access is granted through [`aws_eks_access_entry.this`](terraform/modules/eks-access/main.tf:1)
- EKS policy associations are managed through [`aws_eks_access_policy_association.this`](terraform/modules/eks-access/main.tf:12)
- Jenkins deployment access is separated through the `jenkins` role in [`terraform/environments/dev/terraform.tfvars`](terraform/environments/dev/terraform.tfvars:103)

### Kubernetes service exposure security

The deployment uses internal services and ingress-based exposure instead of exposing every workload directly:

- Hello World uses `ClusterIP` service type in [`hello-world/values.yaml`](hello-world/values.yaml:25)
- Grafana uses `ClusterIP` service type in [`monitoring/graf_values.yaml`](monitoring/graf_values.yaml:11)
- Hello World is exposed through NGINX ingress in [`k8s-ingress.yml`](k8s-ingress.yml:1)
- Grafana is exposed through NGINX ingress in [`grafana-ingress.yml`](grafana-ingress.yml:1)
- Argo CD is exposed through NGINX ingress in [`gitOps-CD/argo-cd-ingress.yaml`](gitOps-CD/argo-cd-ingress.yaml:1)

### Secrets and credential handling

The repository avoids hardcoding some runtime credentials directly in Helm values and references Kubernetes secrets where configured:

- Grafana admin credentials come from an existing Kubernetes secret in [`monitoring/graf_values.yaml`](monitoring/graf_values.yaml:17)
- The Hello World chart uses the Kubernetes pull secret configured in [`hello-world/values.yaml`](hello-world/values.yaml:20)
- Docker registry credentials are consumed from GitHub Actions secrets in [`.github/workflows/hello-world-ci.yml`](.github/workflows/hello-world-ci.yml:97)
- The CI workflow uses `DOCKER_USERNAME` and `DOCKER_TOKEN` secrets in [`.github/workflows/hello-world-ci.yml`](.github/workflows/hello-world-ci.yml:100)

### CI pipeline security controls

The GitHub Actions pipeline contains multiple security checks before deployment metadata is updated:

- Filesystem vulnerability scanning with Trivy in [`filesystem-scan`](.github/workflows/hello-world-ci.yml:62)
- Container image scanning with Trivy in [`image-scan`](.github/workflows/hello-world-ci.yml:124)
- Code validation through compile, test, lint, and format checks in [`test`](.github/workflows/hello-world-ci.yml:24)
- Helm chart linting and manifest rendering in [`helm`](.github/workflows/hello-world-ci.yml:141)
- Image promotion through immutable commit SHA tags in [`docker`](.github/workflows/hello-world-ci.yml:103)

### Monitoring and observability security posture

The monitoring stack is configured to reduce unnecessary exposed surface area while keeping observability available:

- Prometheus scrape target is internal cluster DNS in [`monitoring/prom_values.yaml`](monitoring/prom_values.yaml:22)
- Alertmanager and Pushgateway are disabled in [`monitoring/prom_values.yaml`](monitoring/prom_values.yaml:29)
- Prometheus node exporter is disabled in [`monitoring/prom_values.yaml`](monitoring/prom_values.yaml:38)
- Grafana is served behind a subpath in [`monitoring/graf_values.yaml`](monitoring/graf_values.yaml:1)

### GitOps deployment safety controls

Argo CD is configured to continuously reconcile from Git and keep drift under control:

- All Argo CD apps point to the Git repository as source of truth in [`gitOps-CD/CD-Resource/hello-world-CD.yaml`](gitOps-CD/CD-Resource/hello-world-CD.yaml:11), [`gitOps-CD/CD-Resource/prometheus.yaml`](gitOps-CD/CD-Resource/prometheus.yaml:11), and [`gitOps-CD/CD-Resource/grafana-cd.yaml`](gitOps-CD/CD-Resource/grafana-cd.yaml:14)
- Automated sync with self-heal and prune is enabled in [`gitOps-CD/CD-Resource/hello-world-CD.yaml`](gitOps-CD/CD-Resource/hello-world-CD.yaml:23), [`gitOps-CD/CD-Resource/prometheus.yaml`](gitOps-CD/CD-Resource/prometheus.yaml:23), and [`gitOps-CD/CD-Resource/grafana-cd.yaml`](gitOps-CD/CD-Resource/grafana-cd.yaml:26)
- Namespace creation is controlled through `CreateNamespace=true` in the Argo CD Application manifests

## 📈 Recommended improvements

### Terraform CI/CD using EC2 IAM access

To strengthen infrastructure delivery, the next improvement is to run Terraform from a dedicated EC2-based runner that uses an attached IAM instance profile instead of long-lived user credentials. This improves auditability and reduces credential sprawl.

Recommended improvements:

- Use separate EC2 runner IAM roles for `dev` and `prod`
- Restrict Terraform apply to approved branches and operators
- Add `terraform fmt`, `terraform validate`, and `terraform plan` to CI before apply
- Save Terraform plan output as a pipeline artifact for review
- Use manual approval before applying infrastructure changes to production
- Limit the EC2 runner role permissions to only the resources Terraform manages

### Kubernetes security improvements

Recommended Kubernetes hardening improvements for this repository:

- Enforce Pod Security Standards on `default`, `monitoring`, and `argocd` namespaces
- Set non-root containers, `readOnlyRootFilesystem`, and dropped Linux capabilities in [`hello-world/values.yaml`](hello-world/values.yaml:95)
- Add NetworkPolicies for application, monitoring, and Argo CD communication paths
- Apply namespace-level resource quotas and limit ranges
- Restrict public admin surfaces such as Grafana and Argo CD with stronger access controls
- Add admission control or policy enforcement with tools such as Kyverno or OPA Gatekeeper
- Regularly scan workloads and cluster configuration with tools such as Trivy and kube-bench

### Kubeconfig management improvements

Kubeconfig should be handled as a temporary access artifact, not as a shared static file.

Recommended improvements:

- Generate kubeconfig on demand with [`aws eks update-kubeconfig`](README.md)
- Use separate kubeconfig contexts and AWS profiles for each environment
- RBAC Access management based on the service Account Access.
- Avoid committing or copying kubeconfig files between systems
- Restrict kubeconfig file permissions on operator and runner hosts
- Use IAM role assumption for short-lived cluster access
- Remove outdated EKS access entries when users or automation no longer need access

### Kubernetes secrets and KMS improvements

Secret management can be improved by reducing manual secret handling and using managed encryption.

Recommended improvements:

- Enable EKS secret encryption with AWS KMS for Kubernetes secrets at rest
- Use AWS Secrets Manager or HashiCorp Vault for secret storage instead of manual secret creation where possible
- Use External Secrets Operator to sync secrets into Kubernetes
- Rotate Docker registry, Grafana, and application credentials on a regular schedule
- Restrict secret read access through Kubernetes RBAC
- Avoid exposing secrets in Helm values, CI logs, terminal history, or documentation

### Open-source alternatives to DynamoDB for Terraform locking

This repository currently uses DynamoDB for Terraform state locking through [`terraform-bootstrap/modules/dynamodb-lock/main.tf`](terraform-bootstrap/modules/dynamodb-lock/main.tf:1). If you want open-source alternatives, the main options are:

- Redis & ETCD – High-performance key-value store suitable for distributed locking and state coordination.

Practical recommendation:

- For AWS-native deployments, keep DynamoDB because it is simpler and well-supported
- For open-source self-hosted setups, Redis is the most established direct alternative

### VPC, internet, public/private subnet, and edge security improvements

The repository already uses public and private subnets in [`terraform/environments/dev/main.tf`](terraform/environments/dev/main.tf:1) and [`terraform/environments/prod/main.tf`](terraform/environments/prod/main.tf:1). The next security improvements should focus on tighter edge and network controls.

Recommended improvements:

- Keep worker nodes and internal services only in private subnets
- Limit public subnet usage to ingress controllers, NAT, and approved public endpoints
- Enable VPC Flow Logs for audit and traffic analysis
- Tighten Security Group and Network ACL rules by traffic direction and workload role
- Disable unnecessary public IP assignment on compute resources
- Segment CI/CD runners, admin access, and workloads with separate security boundaries where needed
- Restrict egress from private workloads when required by policy

### WAF and ingress protection improvements

For publicly reachable endpoints, add stronger web edge protections.

Recommended improvements:

- Place AWS WAF in front of public ingress or load balancers
- Enable managed rule groups, IP filtering, and rate limiting
- Enforce HTTPS with ACM certificates and ingress redirects
- Protect Grafana and Argo CD behind authentication and allow lists
- Add ingress controller protections such as body size limits and secure headers

### Observability and security operations improvements

Security operations maturity can be improved by expanding monitoring, logging, and alerting.

Recommended improvements:

- Enable EKS control plane audit logs in CloudWatch
- Centralize application, ingress, and Argo CD logs
- Alert on failed image pulls, crash loops, and suspicious ingress traffic
- Monitor IAM role usage through CloudTrail and CloudWatch
- Add image signing and provenance verification for released images


## Key Points

### Docker Image Build for Hello-World

The application uses a multi-stage Docker build to separate the build environment from the runtime environment. Dependencies are installed in a builder stage and only the required artifacts are copied into a minimal Distroless runtime image. This reduces the final image size, improves security, and removes unnecessary build tools.

### Docker Layer Caching for Hello-World

The Dockerfile is optimized for build caching by copying requirements.txt before the application source code. Since dependency installation is cached, rebuilding the image after source code changes only rebuilds the application layers, significantly reducing build time.

### ArgoCD

ArgoCD continuously monitors the Git repository and automatically synchronizes Kubernetes resources, enabling secure GitOps-based deployments, automated drift detection, and easy rollback to previous application versions.

ArgoCD is deployed within the same Kubernetes cluster and manages application deployments using the GitOps approach. Each application is defined as an ArgoCD Application resource, allowing automated or manual synchronization from the Git repository to the cluster.

### Helm Charts

Helm charts are used to deploy the application and monitoring stack (Prometheus and Grafana) with configurable values, Kubernetes resource limits, health probes, RBAC, and security contexts to ensure consistent, secure, and repeatable deployments across environments.