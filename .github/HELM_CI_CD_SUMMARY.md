# Helm CI/CD Configuration Summary

## ✅ Configuración Completada

Se ha integrado exitosamente Helm en el CI/CD de GitHub con la siguiente estructura:

### 📁 Archivos Creados/Modificados

#### 1. **GitHub Actions Workflows** (`.github/workflows/`)
- `helm-cicd.yml` - Pipeline completo de CI/CD
- `helm-validation.yml` - Validación en Pull Requests

#### 2. **Scripts** (`scripts/`)
- `helm-deploy.sh` - Script para deployment local
- `helm-inject-vars.sh` - Script para inyectar variables

#### 3. **Helm Values** (`helm-recype/`)
- `values.yaml` - Valores por defecto
- `values-dev.yaml` - Valores para desarrollo
- `values-prod.yaml` - Valores para producción
- `values-secrets.yaml` - Valores con secretos
  - DB_PASSWD: `curso2025`
  - API_PASSWD: `APi_PASSWD`

#### 4. **Configuración**
- `.github/helm-variables.env` - Variables globales
- `.github/SETUP_GITHUB_ACTIONS.md` - Guía de configuración
- `.github/HELM_EXAMPLES.md` - Ejemplos de uso

---

## 🔐 Secrets Requeridos en GitHub

### Configurar en: Settings → Secrets and variables → Actions

```
DOCKER_USERNAME  = tu_usuario_docker_hub
DOCKER_PASSWORD  = tu_token_docker_hub
KUBECONFIG       = contenido_de_~/.kube/config
```

---

## 🚀 Flujo de CI/CD

### En `develop` (Solo build de imagen)
1. ✅ Valida Helm chart
2. ✅ Construye imagen Docker
3. ✅ Pushea a Docker Hub
4. ❌ NO despliega

### En `main` (Full deployment)
1. ✅ Valida Helm chart
2. ✅ Construye imagen Docker
3. ✅ Pushea a Docker Hub
4. ✅ Análisis de vulnerabilidades (Trivy)
5. ✅ Despliega a Kubernetes con Helm
6. ✅ Verifica el estado del deployment

### En Pull Requests
1. ✅ Valida Helm chart
2. ✅ Verifica YAML syntax
3. ✅ Busca APIs deprecadas
4. ✅ Comenta resultado en el PR

---

## 📝 Variables de Helm

### Ubicación: `.github/helm-variables.env`

**Base de Datos:**
```env
DB_PASSWD=curso2025
DB_USER=postgres
DB_NAME=payments_db
DB_PORT=5432
```

**API:**
```env
API_PASSWD=APi_PASSWD
API_PORT=8000
```

**Aplicación:**
```env
APP_ENV=production
APP_NAME=ms_payments
APP_REPLICA_COUNT=1
```

**Imagen Docker:**
```env
IMAGE_REPOSITORY=edygc1988/ms_payments
IMAGE_TAG=latest
IMAGE_PULL_POLICY=IfNotPresent
```

**Recursos:**
```env
RESOURCES_REQUESTS_CPU=250m
RESOURCES_REQUESTS_MEMORY=250Mi
RESOURCES_LIMITS_CPU=1
RESOURCES_LIMITS_MEMORY=250Mi
```

**Health Checks:**
```env
STARTUP_PATH=/startup
LIVENESS_PATH=/liveness
READINESS_PATH=/readiness
```

**HPA (Auto-scaling):**
```env
HPA_ENABLED=true
HPA_MIN_REPLICAS=1
HPA_MAX_REPLICAS=5
HPA_TARGET_CPU_UTILIZATION=80
```

---

## 🛠️ Scripts Disponibles

### Deployment Local

```bash
# Validar chart
./scripts/helm-deploy.sh validate

# Preview (dry-run)
./scripts/helm-deploy.sh dry-run

# Desplegar
./scripts/helm-deploy.sh deploy

# Ver estado
./scripts/helm-deploy.sh status

# Ver historial
./scripts/helm-deploy.sh history

# Rollback
./scripts/helm-deploy.sh rollback
./scripts/helm-deploy.sh rollback 2  # A versión específica

# Actualizar imagen
./scripts/helm-deploy.sh update-image v1.0.0

# Desinstalar
./scripts/helm-deploy.sh uninstall
```

### Inyectar Variables

```bash
# Validar secretos
./scripts/helm-inject-vars.sh validate

# Generar archivo de valores con secretos
./scripts/helm-inject-vars.sh generate prod

# Crear secret en Kubernetes
./scripts/helm-inject-vars.sh create-secret production

# Setup completo
./scripts/helm-inject-vars.sh full prod production

# Preview (sin crear)
./scripts/helm-inject-vars.sh dry-run prod
```

---

## 📊 Validación en GitHub Actions

La validación ahora incluye:

✅ **Helm Lint** - Valida sintaxis del chart
✅ **Helm Template** - Genera manifests
✅ **YAML Validation** - Valida sintaxis Python/YAML
✅ **Structure Check** - Verifica campos requeridos
✅ **Deprecated APIs** - Busca APIs obsoletas
✅ **Image Check** - Verifica imagen Docker configurada

---

## 🔄 Flujo Completo (Ejemplo)

### 1. Desarrollo Local
```bash
# Hacer cambios en Helm chart
git checkout -b feature/update-helm
# ... editar helm-recype/values.yaml

# Validar localmente
./scripts/helm-deploy.sh validate

# Dry-run para preview
./scripts/helm-deploy.sh dry-run

# Commit
git add helm-recype/
git commit -m "Update Helm chart"
git push origin feature/update-helm
```

### 2. Pull Request
- GitHub Actions valida automáticamente
- Comenta resultado en el PR
- ✓ Si todo OK, autorizar merge

### 3. Merge a main
- Construye imagen Docker
- Pushea a Docker Hub
- Escanea vulnerabilidades
- **Despliega automáticamente** a Kubernetes

### 4. Verificar Deployment
```bash
# Ver estado
kubectl get deployment ms-payments
kubectl get pods
kubectl logs -f deployment/ms-payments
```

---

## ⚙️ Configuración de Ambientes

### Desarrollo
```bash
helm install ms-payments ./helm-recype \
  -f ./helm-recype/values-dev.yaml \
  --namespace dev
```

### Producción
```bash
helm install ms-payments ./helm-recype \
  -f ./helm-recype/values.yaml \
  -f ./helm-recype/values-prod.yaml \
  --namespace prod \
  --wait
```

---

## 🐛 Troubleshooting

### Error: DOCKER_USERNAME not found
**Solución:** Configurar secrets en Settings → Secrets and variables → Actions

### Error: KUBECONFIG not found
**Solución:** 
```bash
# Obtener kubeconfig
cat ~/.kube/config

# Crear secret en GitHub (copiar contenido completo)
```

### Deployment stuck in pending
```bash
# Ver qué está pasando
kubectl describe pod <pod-name>
kubectl get events -n default
```

### Ver logs del deployment
```bash
kubectl logs -f deployment/ms-payments
kubectl logs -f deployment/ms-payments --all-containers
```

---

## 📚 Próximos Pasos

1. ✅ Configurar secrets en GitHub
2. ✅ Hacer push a una rama feature
3. ✅ Crear PR para validación
4. ✅ Merge a `main` para deployment
5. ✅ Verificar deployment en Kubernetes

---

## 🔗 Enlaces Útiles

- [Documentación de Helm](https://helm.sh/docs/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Kubernetes](https://kubernetes.io/docs/)
- [Docker Hub API](https://docs.docker.com/docker-hub/api/overview/)

---

**Estado:** ✅ COMPLETADO
**Fecha:** 9 de Diciembre de 2025
**Versión:** 1.0
