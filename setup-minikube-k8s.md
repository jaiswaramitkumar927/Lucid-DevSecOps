# Prerequisites

Before deploying the application, ensure the following software is installed on your local machine or VM.

| Tool | Version |
|------|----------|
| Docker | 24.x or later |
| Minikube | v1.35+ |
| kubectl | v1.32+ |
| Helm | v3.17+ |
| Git | Latest |
| GitHub Account | Required for CI/CD |
| Docker Hub Account | Required for image registry |

---

# Environment Requirements

Minimum recommended specifications:

| Resource | Recommended |
|----------|-------------|
| CPU | 4 vCPU |
| Memory | 8 GB RAM |
| Storage | 40 GB |
| Operating System | Ubuntu 22.04 LTS |

---

# Install Docker

```bash
sudo apt update

sudo apt install -y docker.io

sudo systemctl enable docker

sudo systemctl start docker

sudo usermod -aG docker $USER
```

Verify:

```bash
docker --version
```

---

# Install kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl

sudo mv kubectl /usr/local/bin/
```

Verify:

```bash
kubectl version --client
```

---

# Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Verify:

```bash
helm version
```

---

# Install Minikube

Download Minikube:

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

Verify:

```bash
minikube version
```

---

# Start Minikube

Start the Kubernetes cluster using the Docker driver.

```bash
minikube start \
  --driver=docker \
  --cpus=4 \
  --memory=8192
```

Verify cluster status:

```bash
minikube status
```

Expected output:

```text
minikube: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

---

# Verify Kubernetes Cluster

```bash
kubectl get nodes
```

Expected output:

```text
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1m    v1.32.x
```

---

# Enable Required Minikube Add-ons

Enable the Ingress Controller:

```bash
minikube addons enable ingress
```

Verify:

```bash
kubectl get pods -n ingress-nginx
```

Expected output:

```text
ingress-nginx-controller    Running
```

---

# Verify Helm Connectivity

```bash
helm ls -A
```

---

# Verify Cluster Information

```bash
kubectl cluster-info
```

---

# Repository Setup

Clone the repository:

```bash
git clone https://github.com/jaiswaramitkumar927/lucidity-assignment-workspace.git

cd lucidity-assignment-workspace
```

---

# Verify Environment

Run the following commands before deployment:

```bash
docker --version

kubectl version --client

helm version

minikube version

kubectl get nodes

kubectl get pods -A
```

If all commands execute successfully, the environment is ready for deployment.