variable "matomo_port" {
  description = "Puerto del host para acceder a Matomo"
  type        = number
  default     = 8081
}

variable "db_root_password" {
  description = "Contraseña root de MariaDB"
  type        = string
  default     = "rootpassword"
  sensitive   = true
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "matomo"
}

variable "db_user" {
  description = "Usuario de la base de datos"
  type        = string
  default     = "matomo"
}

variable "db_password" {
  description = "Contraseña del usuario de la base de datos"
  type        = string
  default     = "matomopassword"
  sensitive   = true
}

variable "matomo_image" {
  description = "Imagen de Docker para Matomo personalizada"
  type        = string
  default     = "joseeelv/matomo-custom:latest"
}
