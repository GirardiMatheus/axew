data "kubernetes_namespace_v1" "default" {
  metadata {
    name = "default"
  }
}

resource "kubernetes_namespace_v1" "platform" {
  metadata {
    name = "devops-platform"

    labels = {
      app         = "axew"
      environment = "development"
      managed-by  = "terraform"
    }
  }
}

resource "kubernetes_deployment_v1" "application" {
  metadata {
    name      = "axew-api"
    namespace = kubernetes_namespace_v1.platform.metadata[0].name

    labels = {
      app = "axew-api"
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].replicas
    ]
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "axew-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "axew-api"
        }
      }

      spec {
        # Pod Security Context
        security_context {
          run_as_non_root = true
          run_as_user     = 10001
          run_as_group    = 10001
          fs_group        = 10001

          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name              = "axew-api"
          image             = var.application_image
          image_pull_policy = "IfNotPresent"

          # Environment variables from ConfigMap
          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.application.metadata[0].name
            }
          }

          # Environment variables from Secret
          env_from {
            secret_ref {
              name = kubernetes_secret_v1.application.metadata[0].name
            }
          }

          # Container Security Context
          security_context {
            allow_privilege_escalation = false
            privileged                 = false
            read_only_root_filesystem  = true
            run_as_non_root            = true
            run_as_user                = 10001

            capabilities {
              drop = ["ALL"]
            }
          }

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }

          # Temporary writable directory
          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }

          liveness_probe {
            http_get {
              path   = "/health"
              port   = 8080
              scheme = "HTTP"
            }

            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 2
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path   = "/ready"
              port   = 8080
              scheme = "HTTP"
            }

            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 2
            failure_threshold     = 3
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }

            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }
        }

        # Temporary volume for writable application files
        volume {
          name = "tmp"

          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "application" {
  metadata {
    name      = "axew-api"
    namespace = kubernetes_namespace_v1.platform.metadata[0].name

    labels = {
      app = "axew-api"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "axew-api"
    }

    port {
      name        = "http"
      port        = 80
      target_port = "http"
      protocol    = "TCP"
    }
  }
}

resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = "42.3.0"

  namespace        = "traefik"
  create_namespace = true

  values = [
    file("${path.module}/traefik-values.yaml")
  ]

  wait    = true
  timeout = 300
}

resource "kubernetes_ingress_v1" "application" {
  metadata {
    name      = "axew-api"
    namespace = kubernetes_namespace_v1.platform.metadata[0].name
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = "platform.local"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.application.metadata[0].name

              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map_v1" "application" {
  metadata {
    name      = "axew-api-config"
    namespace = kubernetes_namespace_v1.platform.metadata[0].name

    labels = {
      app        = "axew-api"
      managed-by = "terraform"
    }
  }

  data = {
    APP_NAME    = "axew-api"
    APP_VERSION = "1.0.0"
    LOG_LEVEL   = "INFO"
  }
}

resource "kubernetes_secret_v1" "application" {
  metadata {
    name      = "axew-api-secret"
    namespace = kubernetes_namespace_v1.platform.metadata[0].name

    labels = {
      app        = "axew-api"
      managed-by = "terraform"
    }
  }

  type = "Opaque"

  data = {
    DEMO_API_TOKEN = base64encode(var.demo_secret_value)
  }
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.14.0"

  namespace = "kube-system"

  values = [
    file("${path.module}/metrics-server-values.yaml")
  ]

  wait    = true
  timeout = 300
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "application" {
  metadata {
    name      = "axew-api"
    namespace = kubernetes_namespace_v1.platform.metadata[0].name

    labels = {
      app        = "axew-api"
      managed-by = "terraform"
    }
  }

  spec {
    min_replicas = 2
    max_replicas = 5

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.application.metadata[0].name
    }

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
  }
}

resource "helm_release" "monitoring_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "92.10.0"

  namespace        = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/../../monitoring/values.yaml")
  ]

  wait    = true
  timeout = 600
}

resource "kubernetes_manifest" "application_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "axew-api"
      namespace = kubernetes_namespace_v1.platform.metadata[0].name

      labels = {
        app        = "axew-api"
        managed-by = "terraform"
      }
    }

    spec = {
      selector = {
        matchLabels = {
          app = "axew-api"
        }
      }

      namespaceSelector = {
        matchNames = [
          "devops-platform"
        ]
      }

      endpoints = [
        {
          port     = "http"
          path     = "/metrics"
          interval = "15s"
        }
      ]
    }
  }

  depends_on = [
    kubernetes_service_v1.application
  ]
}

resource "kubernetes_config_map_v1" "grafana_axew_dashboard" {
  metadata {
    name      = "grafana-axew-api-dashboard"
    namespace = "monitoring"

    labels = {
      grafana_dashboard = "1"
      app               = "axew"
      managed-by        = "terraform"
    }
  }

  data = {
    "axew-api.json" = file("${path.module}/../../monitoring/dashboards/axew-api.json")
  }

  depends_on = [
    helm_release.monitoring_stack
  ]
}

resource "kubernetes_config_map_v1" "grafana_hpa_dashboard" {
  metadata {
    name      = "grafana-kubernetes-hpa-dashboard"
    namespace = "monitoring"

    labels = {
      grafana_dashboard = "1"
      app               = "axew"
      managed-by        = "terraform"
    }
  }

  data = {
    "kubernetes-hpa.json" = file("${path.module}/../../monitoring/dashboards/kubernetes-hpa.json")
  }

  depends_on = [
    helm_release.monitoring_stack
  ]
}