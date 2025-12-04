terraform {
  required_version = ">= 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
}

# Provider de Kubernetes conectándose al cluster kind-matomo
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-matomo-cluster"
}

# Secret para MariaDB
resource "kubernetes_secret" "mariadb" {
  metadata {
    name = "mariadb-secret"
  }

  data = {
    MARIADB_ROOT_PASSWORD = var.db_root_password
    MARIADB_DATABASE      = var.db_name
    MARIADB_USER          = var.db_user
    MARIADB_PASSWORD      = var.db_password
  }


}

# PersistentVolume para MariaDB
resource "kubernetes_persistent_volume" "mariadb" {
  metadata {
    name = "mariadb-pv"
    labels = {
      type = "local"
      app  = "mariadb"
    }
  }

  spec {
    storage_class_name = "manual"
    capacity = {
      storage = "5Gi"
    }
    access_modes                     = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      host_path {
        path = "/mnt/data/mariadb"
        type = "DirectoryOrCreate"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [spec[0].claim_ref]
  }
}

# PersistentVolumeClaim para MariaDB
resource "kubernetes_persistent_volume_claim" "mariadb" {
  metadata {
    name = "mariadb-pvc"
    labels = {
      app = "mariadb"
    }
  }

  spec {
    storage_class_name = "manual"
    access_modes       = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [kubernetes_persistent_volume.mariadb]
}

# Deployment de MariaDB
resource "kubernetes_deployment" "mariadb" {
  wait_for_rollout = false

  metadata {
    name = "mariadb"
    labels = {
      app = "mariadb"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mariadb"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "mariadb"
        }
      }

      spec {
        container {
          name  = "mariadb"
          image = "mariadb:11.2"

          env {
            name = "MARIADB_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mariadb.metadata[0].name
                key  = "MARIADB_ROOT_PASSWORD"
              }
            }
          }

          env {
            name = "MARIADB_DATABASE"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mariadb.metadata[0].name
                key  = "MARIADB_DATABASE"
              }
            }
          }

          env {
            name = "MARIADB_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mariadb.metadata[0].name
                key  = "MARIADB_USER"
              }
            }
          }

          env {
            name = "MARIADB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mariadb.metadata[0].name
                key  = "MARIADB_PASSWORD"
              }
            }
          }

          port {
            container_port = 3306
            name           = "mysql"
          }

          volume_mount {
            name       = "mariadb-storage"
            mount_path = "/var/lib/mysql"
          }
        }

        volume {
          name = "mariadb-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mariadb.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_persistent_volume_claim.mariadb]
}

# Service para MariaDB
resource "kubernetes_service" "mariadb" {
  metadata {
    name = "mariadb"
    labels = {
      app = "mariadb"
    }
  }

  spec {
    type = "ClusterIP"

    port {
      port        = 3306
      target_port = 3306
      protocol    = "TCP"
      name        = "mysql"
    }

    selector = {
      app = "mariadb"
    }
  }

  depends_on = [kubernetes_deployment.mariadb]
}

# PersistentVolume para Matomo
resource "kubernetes_persistent_volume" "matomo" {
  metadata {
    name = "matomo-pv"
    labels = {
      type = "local"
      app  = "matomo"
    }
  }

  spec {
    storage_class_name = "manual"
    capacity = {
      storage = "5Gi"
    }
    access_modes                     = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      host_path {
        path = "/mnt/data/matomo"
        type = "DirectoryOrCreate"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [spec[0].claim_ref]
  }
}

# PersistentVolumeClaim para Matomo
resource "kubernetes_persistent_volume_claim" "matomo" {
  metadata {
    name = "matomo-pvc"
    labels = {
      app = "matomo"
    }
  }

  spec {
    storage_class_name = "manual"
    access_modes       = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [kubernetes_persistent_volume.matomo]
}

# Deployment de Matomo
resource "kubernetes_deployment" "matomo" {
  wait_for_rollout = false

  metadata {
    name = "matomo"
    labels = {
      app = "matomo"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "matomo"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "matomo"
        }
      }

      spec {
        container {
          name  = "matomo"
          image = var.matomo_image

          env {
            name  = "MATOMO_DATABASE_HOST"
            value = "mariadb"
          }

          env {
            name = "MATOMO_DATABASE_DBNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mariadb.metadata[0].name
                key  = "MARIADB_DATABASE"
              }
            }
          }

          env {
            name = "MATOMO_DATABASE_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mariadb.metadata[0].name
                key  = "MARIADB_USER"
              }
            }
          }

          env {
            name = "MATOMO_DATABASE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mariadb.metadata[0].name
                key  = "MARIADB_PASSWORD"
              }
            }
          }

          port {
            container_port = 80
            name           = "http"
          }

          volume_mount {
            name       = "matomo-storage"
            mount_path = "/var/www/html"
          }
        }

        volume {
          name = "matomo-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.matomo.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_persistent_volume_claim.matomo,
    kubernetes_service.mariadb
  ]
}

# Service para Matomo (NodePort)
resource "kubernetes_service" "matomo" {
  metadata {
    name = "matomo"
    labels = {
      app = "matomo"
    }
  }

  spec {
    type = "NodePort"

    port {
      port        = 80
      target_port = 80
      node_port   = 30081
      protocol    = "TCP"
      name        = "http"
    }

    selector = {
      app = "matomo"
    }
  }

  depends_on = [kubernetes_deployment.matomo]
}