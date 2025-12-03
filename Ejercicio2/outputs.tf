output "cluster_name" {
  description = "Nombre del cluster de Kind"
  value       = "matomo"
}

output "kubeconfig_path" {
  description = "Ruta al archivo kubeconfig"
  value       = "~/.kube/config"
}

output "matomo_url" {
  description = "URL para acceder a Matomo"
  value       = "http://localhost:${var.matomo_port}"
}

output "cluster_context" {
  description = "Contexto de Kubernetes"
  value       = "kind-matomo"
}

output "database_info" {
  description = "Información de conexión a la base de datos"
  value = {
    host     = "mariadb"
    port     = "3306"
    database = var.db_name
    user     = var.db_user
  }
  sensitive = false
}
