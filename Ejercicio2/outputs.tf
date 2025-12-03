output "cluster_name" {
  description = "Nombre del cluster de Kind creado"
  value       = kind_cluster.matomo.name
}

output "kubeconfig_path" {
  description = "Ruta al archivo kubeconfig"
  value       = kind_cluster.matomo.kubeconfig_path
}

output "matomo_url" {
  description = "URL para acceder a Matomo"
  value       = "http://localhost:${var.matomo_port}"
}

output "cluster_endpoint" {
  description = "Endpoint del cluster de Kubernetes"
  value       = kind_cluster.matomo.endpoint
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
