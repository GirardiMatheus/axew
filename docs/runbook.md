# Axew — Operational Runbook

## 1. Purpose

This runbook provides operational procedures for diagnosing and troubleshooting common issues in the Axew Kubernetes environment.

It covers application failures, container image problems, service availability, resource consumption and Kubernetes recovery mechanisms.

The procedures are designed for a local Kind cluster managed through Terraform.

## 2. General Diagnostic Workflow

When an incident occurs, follow a structured troubleshooting process:

1. Identify the affected component.
2. Check the current Kubernetes resource status.
3. Inspect Pod events and container logs.
4. Identify the underlying cause.
5. Apply the appropriate correction.
6. Verify that the component has recovered.

### 2.1 Initial Cluster Inspection

Check the overall cluster status:

```bash
kubectl get nodes
kubectl get pods -A
```

Inspect application resources:

```bash
kubectl get all -n devops-platform
```

Inspect recent events:

```bash
kubectl get events -n devops-platform \
  --sort-by='.lastTimestamp'
```

Check resource consumption:

```bash
kubectl top nodes
kubectl top pods -n devops-platform
```

### 2.2 Important Diagnostic Commands

| Command                                                             | Purpose                                           |
| ------------------------------------------------------------------- | ------------------------------------------------- |
| `kubectl get pods -n devops-platform`                               | Check Pod status                                  |
| `kubectl describe pod <pod-name> -n devops-platform`                | Inspect Pod configuration and events              |
| `kubectl logs <pod>`                                                | Inspect container logs                            |
| `kubectl logs <pod-name> -n devops-platform -c axew-api --previous` | Inspect logs from the previous container instance |
| `kubectl get events -n devops-platform`                             | Identify recent Kubernetes events                 |
| `kubectl top pods -n devops-platform`                               | Check Pod resource consumption                    |
| `kubectl describe deployment axew-api -n devops-platform`           | Inspect Deployment status and conditions          |

## 3. CrashLoopBackOff

### Symptoms

A Pod repeatedly starts and terminates, eventually entering the `CrashLoopBackOff` state.

Check the application Pods:

```bash
kubectl get pods -n devops-platform
```

Example:

```text
NAME                         READY   STATUS             RESTARTS
axew-api-xxxxxxxxxx-xxxxx    0/1     CrashLoopBackOff   5
```

### Investigation

Identify the affected Pod and inspect its events:

```bash
kubectl describe pod <pod-name> -n devops-platform
```

Inspect the current container logs:

```bash
kubectl logs <pod-name> -n devops-platform \
  -c axew-api
```

If the container has already restarted, inspect its previous logs:

```bash
kubectl logs <pod-name> -n devops-platform \
  -c axew-api --previous
```

### Possible Causes

- Application startup errors.
- Invalid environment variables or configuration.
- Missing or incorrect Secret values.
- Failed liveness or startup probes.
- Container permission issues.
- Application process terminating unexpectedly.
- Container termination due to memory limits (`OOMKilled`).

### Resolution

1. Identify the error in the container logs.
2. Check the ConfigMap and Secret configuration.
3. Verify the application configuration and container startup command.
4. Inspect probe settings and resource limits.
5. Correct the source configuration in the repository.
6. Apply the changes through Terraform when they involve Terraform-managed resources.

Verify the recovery:

```bash
kubectl get pods -n devops-platform -w
```

The expected result is a Pod in the `Running` state with all containers ready (`READY 1/1`) and no repeated restarts.

## 4. ImagePullBackOff

### Symptoms

A Pod cannot start because Kubernetes is unable to retrieve the container image.

Check the application Pods:

```bash
kubectl get pods -n devops-platform
```

Example:

```text
NAME                         READY   STATUS             RESTARTS
axew-api-xxxxxxxxxx-xxxxx    0/1     ImagePullBackOff   0
```

### Investigation

Inspect the affected Pod events:

```bash
kubectl describe pod <pod-name> -n devops-platform
```

Check the image configured in the Deployment:

```bash
kubectl get deployment axew-api -n devops-platform \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
echo
```

Inspect the container image availability in Kind nodes:

```bash
for node in $(kind get nodes --name axew); do
  echo "Checking $node"
  docker exec "$node" crictl images | grep axew-api
done
```

### Possible Causes

- Incorrect image name or tag.
- Image not loaded into the Kind cluster.
- Image unavailable in the configured container registry.
- Incorrect image pull policy.
- Deployment referencing an outdated image version.

### Resolution

1. Verify the image name and tag configured in Terraform.
2. Confirm that the expected image exists locally.
3. Load the image into the Kind cluster:

```bash
kind load docker-image axew-api:1.1 --name axew
```

4. Verify that the image is available in all cluster nodes.
5. Correct the image configuration in the repository if necessary.
6. Apply the changes through Terraform.

### Verification

Monitor the Deployment rollout:

```bash
kubectl rollout status deployment/axew-api \
  -n devops-platform
```

Check the Pod status:

```bash
kubectl get pods -n devops-platform
```

The expected result is that the application Pods reach the `Running` state with all containers ready.

## 5. Application Unavailable

### Symptoms

The Axew API is unreachable or returns unexpected HTTP responses.

Possible symptoms include:

- Connection refused.
- HTTP 502 or 503 responses.
- Requests timing out.
- Application Pods not ready.
- Ingress routing failures.

### Investigation

#### 1. Check Application Pods

Verify whether the application Pods are running and ready:

```bash
kubectl get pods -n devops-platform
```

Inspect the Deployment:

```bash
kubectl describe deployment axew-api -n devops-platform
```

#### 2. Check Service and Endpoints

Verify that the application Service exists:

```bash
kubectl get service axew-api -n devops-platform
```

Inspect the Service configuration:

```bash
kubectl describe service axew-api -n devops-platform
```

Check whether the Service has healthy endpoints:

```bash
kubectl get endpoints axew-api -n devops-platform
```

An empty endpoint list may indicate that no ready Pods match the Service selector.

#### 3. Check Ingress Configuration

Inspect the Ingress resource:

```bash
kubectl get ingress -n devops-platform
kubectl describe ingress axew-api -n devops-platform
```

Verify that the configured hostname is `platform.local` and that the backend references the correct Service and port.

#### 4. Check Traefik

Verify whether the Traefik Pods are running:

```bash
kubectl get pods -n traefik
```

Inspect Traefik logs:

```bash
kubectl logs -n traefik \
  deployment/traefik --tail=100
```

Check whether the Traefik Service is available:

```bash
kubectl get service traefik -n traefik
```

### 5. Test Application Connectivity

Forward a local port to the Traefik Service:

```bash
kubectl port-forward -n traefik \
  svc/traefik 8080:80
```

In another terminal, test the application:

```bash
curl -i -H "Host: platform.local" \
  http://127.0.0.1:8080/
```

Check the health endpoint:

```bash
curl -i -H "Host: platform.local" \
  http://127.0.0.1:8080/health
```

### Possible Causes

- Application Pods are not ready.
- Service selector does not match Pod labels.
- Service target port is incorrect.
- Ingress references an incorrect Service or port.
- Traefik is unavailable or failing to route requests.
- Application process is not listening on the expected port.
- Network connectivity problems between Kubernetes components.

### Resolution

1. Restore application Pod availability if necessary.
2. Verify Service selectors and target ports.
3. Confirm that the Ingress references the correct backend.
4. Check Traefik Pod status and logs.
5. Correct the configuration in the repository.
6. Apply changes through Terraform when they involve Terraform-managed resources.

### Verification

Check application Pod availability:

```bash
kubectl get pods -n devops-platform
```

Verify that the Service has registered endpoints:

```bash
kubectl get endpoints axew-api -n devops-platform
```

Inspect EndpointSlices to verify endpoint addresses and readiness conditions:

```bash
kubectl get endpointslices -n devops-platform \
  -l kubernetes.io/service-name=axew-api \
  -o yaml
```

Verify that the endpoints have `ready: true`.

Finally, confirm that the application responds successfully:

```bash
curl -i -H "Host: platform.local" \
  http://127.0.0.1:8080/health

curl -i -H "Host: platform.local" \
  http://127.0.0.1:8080/ready
```

The expected result is HTTP `200 OK` from both health and readiness endpoints, with the application returning the expected JSON responses.

## 6. High CPU and HPA Scaling

### 6.1 Symptoms

High CPU utilization may affect application performance and trigger Horizontal Pod Autoscaler (HPA) scaling.

Common symptoms include:

- Increased application response times.
- High CPU utilization across application Pods.
- HPA increasing the number of replicas.
- HPA unable to scale despite high CPU utilization.
- HPA displaying `<unknown>` for CPU metrics.

### 6.2 Investigation

Start by checking resource utilization:

```bash
kubectl top pods -n devops-platform
kubectl top nodes
```

Inspect the Horizontal Pod Autoscaler:

```bash
kubectl get hpa -n devops-platform
kubectl describe hpa axew-api -n devops-platform
```

Monitor scaling activity:

```bash
kubectl get hpa -n devops-platform -w
```

Check the Deployment and its replicas:

```bash
kubectl get deployment axew-api -n devops-platform
kubectl get pods -n devops-platform -o wide
```

Inspect recent namespace events:

```bash
kubectl get events -n devops-platform \
  --sort-by='.lastTimestamp'
```

### 6.3 Understanding HPA Behavior

The Axew API uses a Horizontal Pod Autoscaler configured with:

| Parameter              | Configuration   |
| ---------------------- | --------------- |
| Minimum replicas       | 2               |
| Maximum replicas       | 5               |
| CPU utilization target | 70%             |
| Scaling metric         | CPU utilization |

The HPA calculates CPU utilization based on the CPU resource requests configured for the application containers.

When average CPU utilization exceeds the configured target, Kubernetes may increase the number of replicas.

When utilization decreases, the HPA may reduce the number of replicas, respecting its stabilization behavior.

Scaling is asynchronous. Changes are not necessarily immediate.

### 6.4 Possible Causes

| Symptom                          | Possible Cause                                             |
| -------------------------------- | ---------------------------------------------------------- |
| HPA displays `<unknown>`         | Metrics API unavailable or CPU metrics not being collected |
| HPA does not scale               | CPU utilization below target                               |
| HPA cannot calculate utilization | Missing CPU resource requests                              |
| Replicas remain at maximum       | CPU demand remains high or maximum replica limit reached   |
| CPU usage remains high           | Application workload exceeds available resources           |
| `kubectl top` fails              | Metrics Server unavailable or unhealthy                    |

### 6.5 Resolution

If CPU metrics are unavailable:

1. Check whether Metrics Server is running:

```bash
kubectl get pods -n kube-system | grep metrics-server
```

2. Check the Metrics API:

```bash
kubectl get apiservices | grep metrics.k8s.io
```

3. Test whether Kubernetes can retrieve resource metrics:

```bash
kubectl top pods -n devops-platform
```

If the HPA cannot calculate CPU utilization:

1. Inspect the Deployment resource configuration.
2. Confirm that CPU requests are defined for the application container.
3. Check the HPA events using `kubectl describe hpa`.
4. Correct the Terraform configuration if necessary.

If the application reaches the maximum replica count:

1. Inspect CPU utilization across application Pods.
2. Review the configured CPU requests and limits.
3. Investigate whether the workload requires optimization.
4. Evaluate whether increasing the maximum replica count is appropriate.

Apply infrastructure changes through Terraform rather than manually modifying Terraform-managed resources with `kubectl edit`.

### 6.6 Verification

After resolving the issue, verify that metrics are available:

```bash
kubectl top pods -n devops-platform
```

Check the HPA status:

```bash
kubectl get hpa -n devops-platform
```

Inspect the Deployment:

```bash
kubectl get deployment axew-api -n devops-platform
```

Expected behavior:

- CPU metrics are available.
- HPA reports a valid CPU utilization value.
- The Deployment maintains at least two replicas.
- Replica count increases when CPU utilization remains above the configured target, up to the maximum of five.
- Replica count can decrease when utilization drops and stabilization conditions allow it.

## 7. Pod Recovery

### 7.1 Overview

Kubernetes provides self-healing capabilities through controllers such as Deployments and ReplicaSets.

In the Axew platform, the Deployment manages the desired number of application replicas.

If a Pod is deleted or becomes unavailable, the ReplicaSet detects the difference between the desired and current replica counts and creates a replacement Pod.

This helps maintain application availability without requiring manual intervention.

### 7.2 Simulate Pod Failure

List the application Pods:

```bash
kubectl get pods -n devops-platform
```

Select one Pod and delete it:

```bash
kubectl delete pod <pod-name> -n devops-platform
```

Monitor the recovery process:

```bash
kubectl get pods -n devops-platform -w
```

A replacement Pod should be created automatically.

### 7.3 Investigation

Inspect the Deployment:

```bash
kubectl describe deployment axew-api -n devops-platform
```

Check the ReplicaSet:

```bash
kubectl get replicasets -n devops-platform
```

Inspect recent events:

```bash
kubectl get events -n devops-platform \
  --sort-by='.lastTimestamp'
```

Check the status of all application Pods:

```bash
kubectl get pods -n devops-platform -o wide
```

### 7.4 Expected Behavior

After deleting a Pod:

- Kubernetes detects that the current replica count is below the desired count.
- The ReplicaSet creates a replacement Pod.
- The new Pod goes through its scheduling and startup process.
- Readiness probes determine when the Pod can receive traffic.
- The Service automatically includes the replacement Pod when it becomes ready.

The recovery process is automatic and does not require manually creating another Pod.

### 7.5 Verification

Verify that the Deployment has the expected number of available replicas:

```bash
kubectl get deployment axew-api -n devops-platform
```

Check the application endpoints:

```bash
kubectl get endpointslices -n devops-platform \
  -l kubernetes.io/service-name=axew-api
```

Test application health:

```bash
kubectl port-forward -n traefik svc/traefik 8080:80
```

In another terminal:

```bash
curl -i -H "Host: platform.local" \
  http://127.0.0.1:8080/health
```

Expected result: HTTP 200 and a healthy application response.
