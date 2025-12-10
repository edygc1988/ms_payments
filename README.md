# ms_payments

Microservicio FastAPI para procesamiento de pagos con soporte para Helm, Docker y Kubernetes.

## CI/CD Pipeline with Helm

El sistema CI/CD integra Helm para validación, construcción y despliegue automático a Kubernetes.

### GitHub Actions Workflows

Se han creado dos workflows principales:

#### 1. `helm-cicd.yml` - Pipeline completo

Ejecutado en pushes a `main` y `develop`:

- **Validate Helm**: lint y validación de templates
- **Build Image**: construcción y push a Docker Hub
- **Security Scan**: análisis de vulnerabilidades con Trivy
- **Deploy Helm**: despliegue automático a Kubernetes (solo en `main`)

#### 2. `helm-validation.yml` - Validación en Pull Requests

Ejecutado en PRs para validar cambios en Helm charts:

- Helm lint stricto
- Validación de templates
- Validación contra esquema de Kubernetes
- Búsqueda de APIs deprecadas

### Secrets requeridos en GitHub

Configura los siguientes secrets en `Settings → Secrets and variables → Actions`:

**Docker Hub:**

- `DOCKER_USERNAME`: tu usuario de Docker Hub
- `DOCKER_PASSWORD`: tu token de acceso de Docker Hub

**Kubernetes (para deployment):**

- `KUBECONFIG`: contenido completo del archivo `~/.kube/config` (base64 encoded)

**Opcional:**

- `HELM_REGISTRY_USERNAME`: usuario para registros privados de Helm (si aplica)
- `HELM_REGISTRY_PASSWORD`: contraseña para registros privados de Helm (si aplica)

### Estructura del Helm Chart

```
helm-recype/
├── Chart.yaml              # Metadatos del chart
├── values.yaml             # Valores por defecto
├── values-prod.yaml        # Valores para producción (opcional)
├── values-dev.yaml         # Valores para desarrollo (opcional)
└── templates/
    ├── deployment.yaml     # Deployment de la aplicación
    ├── service.yaml        # Service para exponer la aplicación
    ├── hpa.yaml           # Horizontal Pod Autoscaler
    ├── secret.yaml        # Secretos (si aplica)
    ├── configmap.yaml     # ConfigMaps (si aplica)
    └── _helpers.tpl       # Templates de ayuda
```

### Deployment Manual

Usa el script `scripts/helm-deploy.sh` para operaciones locales:

```bash
# Validar el chart
./scripts/helm-deploy.sh validate

# Dry-run (preview del despliegue)
./scripts/helm-deploy.sh dry-run

# Desplegar
./scripts/helm-deploy.sh deploy

# Ver estado del despliegue
./scripts/helm-deploy.sh status

# Ver historial de releases
./scripts/helm-deploy.sh history

# Rollback a versión anterior
./scripts/helm-deploy.sh rollback
./scripts/helm-deploy.sh rollback 2  # A versión específica

# Actualizar imagen
./scripts/helm-deploy.sh update-image v1.0.0

# Desinstalar
./scripts/helm-deploy.sh uninstall
```

### Despliegue en diferentes namespaces

```bash
# Desplegar en namespace específico
NAMESPACE=production ./scripts/helm-deploy.sh deploy

# Con archivos de valores personalizados
helm upgrade --install ms-payments ./helm-recype \
  --namespace production \
  --values ./helm-recype/values-prod.yaml \
  --wait
```

### Customización de valores

Crea archivos `values-{env}.yaml` para diferentes ambientes:

```yaml
# values-prod.yaml
replicaCount: 3

image:
  tag: "v1.0.0"

resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "2"
    memory: "1Gi"

hpa:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
```

Luego desplegar con:

```bash
helm upgrade --install ms-payments ./helm-recype \
  --namespace production \
  --values ./helm-recype/values.yaml \
  --values ./helm-recype/values-prod.yaml
```

### Prerequisitos

- Docker (para construir imágenes)
- Helm 3.x
- kubectl configurado con acceso a tu cluster de Kubernetes
- Docker Hub account (para almacenar imágenes)

### Instalación local

1. **Clonar el repositorio:**

```bash
git clone https://github.com/edygc1988/ms_payments.git
cd ms_payments
```

2. **Instalar Helm (si no está instalado):**

```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

3. **Validar el Helm chart:**

```bash
./scripts/helm-deploy.sh validate
```

4. **Desplegar a tu cluster:**

```bash
./scripts/helm-deploy.sh deploy
```

### Monitoreo post-despliegue

```bash
# Ver logs del pod
kubectl logs -f deployment/ms-payments

# Ver eventos del deployment
kubectl describe deployment ms-payments

# Port-forward para acceso local
kubectl port-forward svc/ms-payments 8000:80
```

Luego accede a `http://localhost:8000`

### Troubleshooting

**El deployment está en estado pending:**

```bash
kubectl describe pod <pod-name>
kubectl get events
```

**Revisar values utilizados en el deployment:**

```bash
helm get values ms-payments
```

**Revisar el manifest generado:**

```bash
helm template ms-payments ./helm-recype
```

**Verificar logs del pod:**

```bash
kubectl logs deployment/ms-payments -f
```

### Notas adicionales

- El workflow de CI/CD solo deploya automáticamente en pushes a la rama `main`
- Los pushes a `develop` solo construyen y validan la imagen
- Todos los cambios en `helm-recype/` disparan la validación
- El script soporta namespaces personalizados vía variable `NAMESPACE`
