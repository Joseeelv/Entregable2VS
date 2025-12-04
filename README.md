# Kubernetes + Terraform + CI/CD - Despliegue de Aplicaciones

## [El Repositorio](https://github.com/Joseeelv/Entregable2VS)

[![Docker Build](https://github.com/Joseeelv/Entregable2VS/actions/workflows/docker-build.yml/badge.svg)](https://github.com/Joseeelv/Entregable2VS/actions/workflows/docker-build.yml)
[![Terraform](https://img.shields.io/badge/Terraform-%235835CC.svg?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-%23326ce5.svg?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Kind](https://img.shields.io/badge/Kind-Local%20Cluster-blue)](https://kind.sigs.k8s.io/)

Este repositorio contiene dos ejercicios prácticos sobre **despliegue de aplicaciones web en Kubernetes** utilizando diferentes enfoques: manifiestos YAML tradicionales y aprovisionamiento con **Terraform**, además de integración continua con **GitHub Actions**.

## Tabla de Contenidos

- [Descripción General](#descripción-general)
- [Estructura del Repositorio](#estructura-del-repositorio)
- [Ejercicio 1: Drupal + MySQL en Kubernetes](#ejercicio-1-drupal--mysql-en-kubernetes)
- [Ejercicio 2: Matomo + MariaDB con Terraform](#ejercicio-2-matomo--mariadb-con-terraform)
- [Workflows de GitHub Actions](#workflows-de-github-actions)
- [Solución de Problemas](#solución-de-problemas)
- [Recursos Adicionales](#recursos-adicionales)

## Descripción General

Este proyecto demuestra dos enfoques diferentes para desplegar aplicaciones web en **Kubernetes local (Kind)**:

1. **Ejercicio 1**: Despliegue tradicional de **Drupal CMS** con **MySQL** usando manifiestos YAML
2. **Ejercicio 2**: Infraestructura como código (IaC) con **Terraform** para desplegar **Matomo Analytics** con **MariaDB**

Ambos ejercicios implementan:

- **Persistencia de datos** con PersistentVolumes
- **Gestión de secretos** para credenciales
- **Health checks** (liveness y readiness probes)
- **Configuración mediante initContainers**
- **Exposición de servicios** al host local

## Estructura del Repositorio

```
.
├── Ejercicio1/              # Drupal + MySQL en Kubernetes
│   ├── mysql-pv.yaml
│   ├── mysql-pvc.yaml
│   ├── mysql-secret.yaml
│   ├── mysql-deployment.yaml
│   ├── mysql-service.yaml
│   ├── drupal-pv.yaml
│   ├── drupal-pvc.yaml
│   ├── drupal-deployment.yaml
│   └── drupal-service.yml
├── Ejercicio2/              # Matomo + MariaDB con Terraform
│   ├── Dockerfile
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── .gitignore
└── .github/
    └── workflows/
        └── docker-build.yml # GitHub Actions para CI/CD
```

---

## Ejercicio 1: Drupal + MySQL en Kubernetes

### Descripción

Despliegue de Drupal con MySQL utilizando volúmenes persistentes y `initContainers` para la configuración inicial.

### Requisitos Previos

- Kubernetes instalado (Minikube, Kind, k3s, etc.)
- `kubectl` configurado

### Archivos del Ejercicio 1

1. **kind-config.yaml**: Configuración del cluster Kind con mapeo de puerto 8085
2. **mysql-pv.yaml**: PersistentVolume para MySQL (5Gi en `/mnt/data/mysql`)
3. **mysql-pvc.yaml**: PersistentVolumeClaim para MySQL
4. **mysql-secret.yaml**: Credenciales de MySQL (base64)
5. **mysql-deployment.yaml**: Deployment de MySQL 8.0 con probes
6. **mysql-service.yaml**: Service tipo ClusterIP para MySQL
7. **drupal-pv.yaml**: PersistentVolume para Drupal (5Gi en `/mnt/data/drupal`)
8. **drupal-pvc.yaml**: PersistentVolumeClaim para Drupal
9. **drupal-deployment.yaml**: Deployment de Drupal con initContainer
10. **drupal-service.yaml**: Service NodePort (30085 mapeado a puerto 8085 del host)

### Proceso de Despliegue

#### 1. Crear el cluster con Kind

```bash
cd Ejercicio1

# Crear cluster Kind con mapeo de puerto 8085
kind create cluster --name drupal-cluster --config kind-config.yaml

# Verificar que el cluster esté funcionando
kubectl cluster-info --context kind-drupal-cluster
```

#### 2. Crear directorios para volúmenes persistentes

```bash
# En Kind (los directorios se crean dentro del contenedor del nodo)
docker exec drupal-cluster-control-plane mkdir -p /mnt/data/mysql /mnt/data/drupal
docker exec drupal-cluster-control-plane chmod 777 /mnt/data/mysql /mnt/data/drupal
```

#### 3. Aplicar los manifiestos en orden

```bash
# 1. Crear volúmenes persistentes
kubectl apply -f mysql-pv.yaml
kubectl apply -f drupal-pv.yaml

# 2. Crear PVCs y Secret
kubectl apply -f mysql-pvc.yaml
kubectl apply -f drupal-pvc.yaml
kubectl apply -f mysql-secret.yaml

# 3. Desplegar MySQL
kubectl apply -f mysql-deployment.yaml
kubectl apply -f mysql-service.yaml

# 4. Esperar a que MySQL esté listo
kubectl wait --for=condition=ready pod -l app=mysql --timeout=120s

# 5. Desplegar Drupal
kubectl apply -f drupal-deployment.yaml
kubectl apply -f drupal-service.yaml

# 6. Esperar a que Drupal esté listo
kubectl wait --for=condition=ready pod -l app=drupal --timeout=180s
```

#### 4. Verificar el despliegue

```bash
# Ver todos los recursos
kubectl get all

# Ver volúmenes
kubectl get pv,pvc

# Ver logs
kubectl logs -l app=mysql
kubectl logs -l app=drupal
```

#### 5. Acceder a Drupal

Drupal está accesible directamente en: **http://localhost:8085**

Gracias a la configuración de Kind (`kind-config.yaml`), el puerto 30085 del NodePort se mapea automáticamente al puerto 8085 de tu máquina local.

```bash
# Verificar el mapeo de puertos
docker ps | grep drupal-cluster

# Deberías ver: 0.0.0.0:8085->30085/tcp
```

Accede a `http://localhost:8085` en tu navegador y completa la instalación de Drupal:

- **Database type**: MySQL, MariaDB, Percona Server, or equivalent
- **Database name**: drupal
- **Database username**: drupal
- **Database password**: drupalpassword
- **Host**: mysql
- **Port**: 3306

#### 6. Probar persistencia de datos

```bash
# Eliminar todos los pods
kubectl delete pod --all

# Verificar que se recrean automáticamente
kubectl get pods -w

# Los datos deben persistir después de que los pods se recreen
```

### Limpieza

```bash
cd Ejercicio1

# Eliminar todos los recursos (excluyendo kind-config.yaml)
kubectl delete -f mysql-pv.yaml -f mysql-pvc.yaml -f mysql-secret.yaml -f mysql-deployment.yaml -f mysql-service.yaml -f drupal-pv.yaml -f drupal-pvc.yaml -f drupal-deployment.yaml -f drupal-service.yaml

# Verificar que todo se eliminó
kubectl get all
kubectl get pv,pvc

# Para eliminar el cluster de Kind completamente:
kind delete cluster --name drupal-cluster
```

---

## Ejercicio 2: Matomo + MariaDB con Terraform

### Descripción

Despliegue de Matomo con MariaDB utilizando Terraform para crear la infraestructura en Kind, con imagen personalizada de Matomo construida automáticamente mediante GitHub Actions.

### Requisitos Previos

- Docker instalado
- Terraform >= 1.0
- Kind instalado
- Cuenta en Docker Hub
- Repositorio en GitHub

### Configuración Inicial

#### 1. Configurar secrets en GitHub

Ve a tu repositorio en GitHub → Settings → Secrets and variables → Actions, y crea:

- `DOCKER_USERNAME`: Tu usuario de Docker Hub
- `DOCKER_PASSWORD`: Tu token de acceso de Docker Hub

#### 2. Configurar variables de Terraform

```bash
cd Ejercicio2

# Copiar el archivo de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar terraform.tfvars y reemplazar 'tu-usuario' con tu usuario de Docker Hub
nano terraform.tfvars
```

Contenido de `terraform.tfvars`:

```hcl
cluster_name = "matomo-cluster"
kubeconfig   = "~/.kube/config-matomo"
matomo_port  = 8081

db_root_password = "rootpassword"
db_name          = "matomo"
db_user          = "matomo"
db_password      = "matomopassword"

# Reemplaza con tu usuario de Docker Hub
matomo_image = "tu-usuario/matomo-custom:latest"
```

### Proceso de Despliegue

#### 1. Construir y subir la imagen con GitHub Actions

```bash
# Hacer push del Dockerfile a la rama master
git add Ejercicio2/Dockerfile .github/workflows/docker-build.yml
git commit -m "Add custom Matomo Dockerfile"
git push origin master
```

Esto activará automáticamente el workflow de GitHub Actions que:

- Construirá la imagen personalizada de Matomo
- La subirá a Docker Hub con el tag `latest`

Puedes verificar el proceso en: `https://github.com/tu-usuario/tu-repo/actions`, en mi caso `https://github.com/Joseeelv/Entregable2VS/actions`

#### 2. Inicializar Terraform

```bash
cd Ejercicio2

# Inicializar Terraform (descarga providers)
terraform init
```

#### 3. Planificar la infraestructura

```bash
# Ver qué recursos se crearán
terraform plan
```

Esto mostrará:

- 1 Kind cluster
- 1 Secret de Kubernetes
- 2 PersistentVolumes (MariaDB y Matomo)
- 2 PersistentVolumeClaims
- 2 Deployments (MariaDB y Matomo)
- 2 Services

#### 4. Crear la infraestructura

```bash
# Aplicar la configuración
terraform apply

# Confirmar con 'yes'
```

Este proceso:

1. Crea un cluster de Kind llamado `matomo-cluster`
2. Configura port mapping (30081 → 8081)
3. Despliega MariaDB con volumen persistente
4. Despliega Matomo con la imagen personalizada
5. Configura las variables de entorno necesarias

#### 5. Verificar el despliegue

```bash
# Usar el kubeconfig generado
export KUBECONFIG=~/.kube/config-matomo

# Ver todos los recursos
kubectl get all

# Ver volúmenes persistentes
kubectl get pv,pvc

# Ver logs de MariaDB
kubectl logs -l app=mariadb -f

# Ver logs de Matomo
kubectl logs -l app=matomo -f
```

#### 6. Acceder a Matomo

Abre tu navegador en: `http://localhost:8081`

**Configuración de Matomo:**

**Paso 1 - Bienvenida**: Click en "Next"

**Paso 2 - Comprobación del sistema**:

- Verificar que todas las extensiones PHP están instaladas (según Dockerfile)
- Las configuraciones personalizadas deben aparecer:
  - `upload_max_filesize`: 128M
  - `post_max_size`: 128M
  - `memory_limit`: 256M

**Paso 3 - Configuración de base de datos**:

- Database Server: `mariadb`
- Login: `matomo`
- Password: `matomopassword`
- Database Name: `matomo`
- Table Prefix: `matomo_` (opcional)

**Paso 4 - Crear tablas**: Click en "Next"

**Paso 5 - Crear superusuario**: Completa con tus datos

**Paso 6 - Configurar sitio web**: Añade tu primer sitio web

**Paso 7 - Código de seguimiento**: Copia el código JavaScript

**Paso 8 - ¡Felicidades!**: Instalación completada

#### 7. Probar persistencia de datos

```bash
# Destruir la infraestructura de Terraform
terraform destroy

# Confirmar con 'yes'

# Los volúmenes persistentes se mantienen debido a la política 'Retain'

# Recrear la infraestructura
terraform apply

# Acceder nuevamente a http://localhost:8081
# Los datos deben estar presentes (usuarios, configuración, etc.)
```

### Información Técnica del Dockerfile

La imagen personalizada de Matomo incluye:

**Extensiones PHP adicionales:**

- gd (procesamiento de imágenes)
- opcache (caché de código)
- intl (internacionalización)
- mbstring (manejo de strings multibyte)
- zip (compresión)

**Configuraciones de rendimiento:**

- OPcache optimizado
- Límites de memoria aumentados (256M)
- Tamaño máximo de upload: 128M
- Tiempo de ejecución: 300s

**Seguridad:**

- Permisos adecuados para www-data
- Configuraciones PHP personalizadas

### Outputs de Terraform

Después de `terraform apply --auto-approve`, se mostrarán:

```
Outputs:

cluster_context = "kind-matomo"
cluster_name = "matomo"
database_info = {
  "database" = "matomo"
  "host" = "mariadb"
  "port" = "3306"
  "user" = "matomo"
}
kubeconfig_path = "~/.kube/config"
matomo_url = "http://localhost:8081"
```

### Limpieza

```bash
cd Ejercicio2

# Destruir toda la infraestructura si no tenemos persistencia
terraform destroy --auto-approve

# Destruir toda la infraestructura manteniendo la persistencia
terraform destroy \
  -target=kubernetes_deployment.mariadb \
  -target=kubernetes_deployment.matomo \
  -target=kubernetes_service.mariadb \
  -target=kubernetes_service.matomo \
  -target=kubernetes_secret.mariadb \
  -auto-approve

# Limpiar archivos de Terraform (opcional)
rm -rf .terraform .terraform.lock.hcl
```

**Nota**: Los volúmenes persistentes se mantienen en `/mnt/data/` del nodo de Kind debido a la política `Retain`.

---

## Workflows de GitHub Actions

### docker-build.yml

Este workflow se activa automáticamente cuando:

- Se hace push a las ramas `master` o `main`
- Se modifican los archivos `Ejercicio2/Dockerfile` o `.github/workflows/docker-build.yml`
- Se ejecuta manualmente desde la pestaña Actions

**Proceso:**

1. Checkout del código
2. Configuración de Docker Buildx
3. Login en Docker Hub
4. Extracción de metadatos (tags)
5. Build de la imagen
6. Push a Docker Hub con tags `latest` y `<branch>-<sha>`
7. Caché de layers para builds más rápidos

---

## Solución de Problemas

### Ejercicio 1

**Problema**: Los pods no se inician

```bash
# Verificar eventos
kubectl describe pod <pod-name>

# Ver logs
kubectl logs <pod-name>
```

**Problema**: Los PVCs no se vinculan a los PVs

```bash
# Verificar que los labels coinciden
kubectl get pv --show-labels
kubectl get pvc --show-labels
```

### Ejercicio 2

**Problema**: Terraform no puede crear el cluster

```bash
# Verificar que Kind está instalado
kind version

# Verificar que no hay conflictos de puertos
lsof -i :8081

# Si existe un cluster, eliminarlo
kind delete cluster --name <nombre-cluster>
```

**Problema**: La imagen no se encuentra en Docker Hub

```bash
# Verificar el workflow de GitHub Actions
# Asegurarse de que los secrets están configurados
# Verificar que el nombre de la imagen en terraform.tfvars es correcto
```

**Problema**: Los pods no pueden conectarse a MariaDB

```bash
# Verificar que MariaDB está running
kubectl get pods -l app=mariadb

# Ver logs de MariaDB
kubectl logs -l app=mariadb

# Verificar el service
kubectl get svc mariadb
```

**Problema**: Los datos no persisten

```bash
# Verificar la política de retain
kubectl get pv -o yaml | grep persistentVolumeReclaimPolicy

# Debe ser 'Retain', no 'Delete'
```

---

## Recursos Adicionales

- [Documentación de Drupal](https://www.drupal.org/docs)
- [Documentación de Matomo](https://matomo.org/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---
