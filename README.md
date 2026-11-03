# Axew

### Infrastructure as Code · Kubernetes · DevOps · SRE

**Axew** is a hands-on DevOps/SRE project focused on building and managing a Kubernetes platform using Infrastructure as Code (IaC).

The project aims to demonstrate infrastructure provisioning, container orchestration, workload management, observability, and automation through a reproducible local Kubernetes environment.

> **Project status:** 🚧 Under development

---

## 🎯 Project Objectives

The main goal of Axew is to build a reproducible Kubernetes environment while applying DevOps and SRE principles.

Key objectives:

- Provision Kubernetes infrastructure using Terraform.
- Deploy and manage containerized applications.
- Apply Kubernetes workload management best practices.
- Implement horizontal pod autoscaling.
- Monitor infrastructure and application metrics.
- Automate infrastructure code validation.
- Document operational procedures and troubleshooting scenarios.

---

## 🏗️ Architecture

Axew will use a modular architecture, separating cluster provisioning from workload management.

```text
                 Developer
                     |
                     v
                  GitHub
                     |
                     v
              GitHub Actions
                     |
              Code Validation
                     |
                     v
                 Terraform
                     |
                     v
              Kubernetes (Kind)
                     |
          +----------+----------+
          |          |          |
          v          v          v
       Ingress   Application  Monitoring
          |          |          |
          v          v          v
       Service   Deployment  Prometheus
                     |          |
                 +---+---+      v
                 |       |   Grafana
                 v       v
                Pod     Pod
```

_Architecture diagram represents the planned implementation._

---

## 🛠️ Technology Stack

| Technology     | Purpose                       |
| -------------- | ----------------------------- |
| Terraform      | Infrastructure as Code        |
| Kubernetes     | Container orchestration       |
| Kind           | Local Kubernetes cluster      |
| Docker         | Application containerization  |
| Helm           | Kubernetes package management |
| NGINX Ingress  | HTTP traffic management       |
| Prometheus     | Metrics collection            |
| Grafana        | Monitoring and visualization  |
| GitHub Actions | Continuous Integration        |
| Python / Flask | Sample application            |

---

## 📁 Repository Structure

```text
axew/
│
├── terraform/
│   ├── cluster/
│   └── platform/
│
├── application/
│
├── kubernetes/
│
├── monitoring/
│
├── .github/
│   └── workflows/
│
├── docs/
│
├── .gitignore
└── README.md
```

---

## ⚙️ Planned Features

- [ ] Local Kubernetes cluster provisioning with Terraform.
- [ ] Modular Terraform configuration.
- [ ] Flask application containerization.
- [ ] Kubernetes Deployments and Services.
- [ ] Ingress Controller configuration.
- [ ] ConfigMaps and Secrets management.
- [ ] Liveness and Readiness Probes.
- [ ] Resource Requests and Limits.
- [ ] Horizontal Pod Autoscaler (HPA).
- [ ] Prometheus metrics collection.
- [ ] Grafana dashboards.
- [ ] GitHub Actions validation pipeline.
- [ ] Operational runbooks and troubleshooting documentation.

---

## 📊 Observability

Axew will integrate Prometheus and Grafana to provide visibility into infrastructure and application behavior.

Planned monitoring metrics:

- Pod CPU utilization.
- Pod memory utilization.
- Container restarts.
- Available replicas.
- HTTP request metrics.
- Application health.

---

## 🔍 Reliability & SRE Practices

Beyond infrastructure provisioning, Axew aims to demonstrate fundamental Site Reliability Engineering practices.

The project will include practical failure scenarios:

| Scenario                | Expected Behavior               |
| ----------------------- | ------------------------------- |
| Pod deletion            | Automatic Pod recreation        |
| High CPU utilization    | Horizontal scaling              |
| Application failure     | Health check detection          |
| Invalid container image | Troubleshooting and recovery    |
| Service unavailability  | Network and service diagnostics |

Operational procedures will be documented through runbooks.

---

## 🚀 Getting Started

The project is currently under development.

Installation instructions, prerequisites, deployment procedures, and validation steps will be documented as implementation progresses.

---

## 📚 Documentation

| Document                               | Description                                |
| -------------------------------------- | ------------------------------------------ |
| [Architecture](docs/architecture.md)   | Infrastructure architecture and components |
| [Deployment Guide](docs/deployment.md) | Installation and deployment procedures     |
| [Runbook](docs/runbook.md)             | Operational procedures and troubleshooting |

---

## 🎓 Learning Goals

This project is designed to demonstrate practical knowledge in:

- Infrastructure as Code (IaC).
- Kubernetes administration.
- Container orchestration.
- Infrastructure automation.
- Monitoring and observability.
- Troubleshooting and incident response.
- Reliability engineering.

---

## 📌 Project Status

Axew is an evolving project. Features and documentation will be added incrementally, following a commit-based development approach.

**Built as a practical DevOps/SRE portfolio project.**
