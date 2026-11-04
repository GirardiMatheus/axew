# Axew — Deployment Guide

## 1. Overview

This guide describes how to provision, deploy, access, validate, and destroy the Axew local DevOps platform.

The deployment is divided into two Terraform stages:

1. Cluster provisioning using Kind.
2. Platform provisioning using Kubernetes and Helm providers.

The application is built locally with Docker and loaded into the Kind cluster.

## 2. Prerequisites

The following tools must be installed on the host machine:

| Tool               | Purpose                             |
| ------------------ | ----------------------------------- |
| Git                | Repository cloning                  |
| Docker             | Application image building          |
| Kind               | Local Kubernetes cluster management |
| kubectl            | Kubernetes resource management      |
| Terraform >= 1.9.0 | Infrastructure provisioning         |
| curl               | HTTP endpoint testing               |

Docker must be running before building the application image.

## 3. Clone the Repository

Clone the repository and enter the project directory:

```bash
git clone <repository-url>
cd axew
```

## 4. Provision the Kubernetes Cluster

Navigate to the cluster Terraform module:

```bash
cd terraform/cluster
```

Initialize Terraform:

```bash
terraform init
```

Review the execution plan:

```bash
terraform plan
```

Provision the cluster:

```bash
terraform apply
```

Confirm the cluster context:

```bash
kubectl config get-contexts
kubectl config use-context kind-axew
```

Verify the cluster nodes:

```bash
kubectl get nodes
```

The expected topology is:

- One control-plane node.
- One worker node.

The cluster name is `axew`, and the default Kubernetes node image is `kindest/node:v1.34.0`.

Return to the repository root:

```bash
cd ../..
```

## 5. Build the Application Image

Build the Axew API Docker image:

```bash
docker build -t axew-api:1.1 ./application
```

Verify the image:

```bash
docker images axew-api
```

Load the image into the Kind cluster:

```bash
kind load docker-image axew-api:1.1 --name axew
```

Verify that the image is available on the cluster nodes:

```bash
for node in $(kind get nodes --name axew); do
  docker exec "$node" crictl images | grep axew-api
done
```

The image must be available on both nodes before deploying the application.

## 6. Deploy the Platform

Navigate to the platform Terraform module:

```bash
cd terraform/platform
```

Initialize Terraform:

```bash
terraform init
```

The platform module manages:

- Application Namespace and Deployment.
- Kubernetes Service and Ingress.
- ConfigMaps and Secrets.
- Traefik Ingress Controller.
- Metrics Server.
- Horizontal Pod Autoscaler.
- Prometheus and Grafana.
- ServiceMonitor and dashboard ConfigMaps.

### 6.1 Configure the Demonstration Secret

The platform requires the `demo_secret_value` Terraform variable.

Provide a dummy value through an environment variable:

```bash
export TF_VAR_demo_secret_value="replace-with-a-demo-value"
```

This value is only intended to demonstrate Kubernetes Secret integration.

Do not use production credentials in this laboratory environment.

### 6.2 Review and Apply

Review the Terraform execution plan:

```bash
terraform plan
```

Apply the platform configuration:

```bash
terraform apply
```

After successful provisioning, remove the environment variable:

```bash
unset TF_VAR_demo_secret_value
```

## 7. Validate the Deployment

Confirm the application namespace:

```bash
kubectl get namespace devops-platform
```

Check application Pods:

```bash
kubectl get pods -n devops-platform
```

Check the Deployment:

```bash
kubectl get deployment -n devops-platform
```

Check the Service and Ingress:

```bash
kubectl get svc -n devops-platform
kubectl get ingress -n devops-platform
```

Check the HPA:

```bash
kubectl get hpa -n devops-platform
```

The application should initially run with two available replicas.

## 8. Access the Application

The application is exposed through the Traefik Ingress Controller using the hostname:

`platform.local`

The Traefik Service is a ClusterIP Service. To access it from the host machine, create a temporary port-forward:

```bash
kubectl port-forward -n traefik svc/traefik 8080:80
```

Keep this terminal running.

In another terminal, test the application:

```bash
curl -H "Host: platform.local" http://127.0.0.1:8080/
```

Test the health endpoint:

```bash
curl -i -H "Host: platform.local" http://127.0.0.1:8080/health
```

Test the readiness endpoint:

```bash
curl -i -H "Host: platform.local" http://127.0.0.1:8080/ready
```

The health and readiness endpoints should return HTTP 200 when the application is functioning correctly.

## 9. Access Grafana

Grafana is exposed internally through a ClusterIP Service.

Create a port-forward:

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

Open the following address in a browser:

`http://localhost:3000`

The default username is:

`admin`

Retrieve the configured password from the Kubernetes Secret:

```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath='{.data.admin-password}' | base64 -d

echo
```

The following dashboards should be available:

- Axew API.
- Kubernetes HPA.
- Kubernetes Overview.

Dashboard definitions are maintained as JSON files under `monitoring/dashboards/` and provisioned through Terraform-managed ConfigMaps.

## 10. Access Prometheus

Create a port-forward:

```bash
kubectl port-forward -n monitoring \
  svc/kube-prometheus-stack-prometheus 9090:9090
```

Open:

`http://localhost:9090`

Useful PromQL queries include:

```promql
up{namespace="devops-platform"}
```

```promql
sum(rate(http_requests_total[5m]))
```

```promql
container_memory_working_set_bytes{
  namespace="devops-platform",
  container="axew-api"
} / 1024 / 1024
```

## 11. Destroy the Environment

The infrastructure must be destroyed in reverse provisioning order.

### 11.1 Destroy the Platform

Navigate to the platform module:

```bash
cd terraform/platform
```

Run:

```bash
export TF_VAR_demo_secret_value="replace-with-a-demo-value"
terraform destroy
unset TF_VAR_demo_secret_value
cd ../..
```

Confirm the destruction when prompted.

### 11.2 Destroy the Cluster

Navigate to the cluster module:

```bash
cd ../cluster
```

Run:

```bash
terraform destroy
```

Confirm the destruction when prompted.

Verify that the Axew cluster no longer exists:

```bash
kind get clusters
```

Only the cluster managed by this Terraform module should be destroyed.

**Do not use `kind delete clusters --all`**, because it can remove unrelated Kind clusters.

## 12. Important Considerations

- Terraform state is stored locally in each module.
- Terraform state files must not be committed to Git.
- Kubernetes Secrets may be stored in Terraform state. Protect local state files accordingly.
- The application image must be loaded into Kind before deployment.
- Grafana persistence is disabled, so dashboard data and other runtime changes are not retained after recreation.
- Metrics Server uses `--kubelet-insecure-tls` as a laboratory-specific workaround.
- The environment is intended for development, testing, and technical demonstration purposes.
