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
        container {
          name              = "axew-api"
          image             = var.application_image
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
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