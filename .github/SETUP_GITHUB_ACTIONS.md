# GitHub CI/CD Configuration Guide

Este documento explica cómo configurar el CI/CD de Helm para ms_payments en GitHub.

## Prerequisitos

1. **Cuenta de Docker Hub**

   - Usuario y token de acceso en Docker Hub
   - Repositorio creado: `https://hub.docker.com/r/edygc1988/ms_payments`

2. **Cluster de Kubernetes**

   - Acceso a un cluster (EKS, GKE, AKS, o local)
   - `kubectl` configurado localmente

3. **GitHub Repository**
   - Repositorio en GitHub con este código
   - Permisos para gestionar Secrets

## Configuración de Secrets en GitHub

### Paso 1: Acceder a los Settings del Repositorio

1. Ve a tu repositorio en GitHub
2. Click en **Settings** → **Secrets and variables** → **Actions**

### Paso 2: Crear Secrets para Docker Hub

**Secret 1: DOCKER_USERNAME**

- Name: `DOCKER_USERNAME`
- Value: Tu usuario de Docker Hub

**Secret 2: DOCKER_PASSWORD**

- Name: `DOCKER_PASSWORD`
- Value: Tu token de acceso de Docker Hub (no la contraseña)
  - Cómo obtenerlo:
    1. Ve a https://hub.docker.com/settings/security
    2. Click en "New Access Token"
    3. Dale un nombre descriptivo (ej: "GitHub Actions")
    4. Copia el token

### Paso 3: Crear Secret para Kubernetes (KUBECONFIG)

Este secret es necesario solo si quieres que GitHub depliegue automáticamente a tu cluster.

**Obtener el contenido de tu kubeconfig:**

```bash
# Obtener el contenido del archivo kubeconfig
cat ~/.kube/config

# O si usas un contexto específico
kubectl config view --raw --flatten
```

**Crear el secret:**

1. Name: `KUBECONFIG`
2. Value: Pega el contenido completo de tu `~/.kube/config`

**Alternativa segura (recomendado):**

En lugar de usar el kubeconfig completo, considera usar:

```bash
# Para EKS
aws eks get-token --cluster-name <cluster-name>

# Para GKE
gcloud auth application-default print-access-token

# Para AKS
az account get-access-token
```

Luego, en el workflow, usa esas credenciales para configurar kubectl.

## Estructura de los Workflows

### `helm-cicd.yml` - Pipeline Completo

Ejecutado automáticamente en:

- **Push a `main`**: Valida, construye imagen, hace security scan y despliega
- **Push a `develop`**: Solo valida y construye imagen (sin deploy)
- **Pull Requests**: Solo valida el Helm chart

**Jobs:**

1. `validate-helm` - Valida el chart con helm lint y kubeval
2. `build-image` - Construye y pushea imagen a Docker Hub
3. `security-scan` - Escanea vulnerabilidades con Trivy
4. `deploy-helm` - Despliega a Kubernetes (solo en main)

### `helm-validation.yml` - Validación en PRs

Ejecutado en Pull Requests para cambios en `helm-recype/`:

- Valida helm chart
- Verifica contra esquema de Kubernetes
- Busca APIs deprecadas
- Comenta resultados en el PR

## Ejecución Manual de Workflows

### Opción 1: Trigger automático

```bash
# Push a main despliega automáticamente
git push origin main

# Push a develop solo construye imagen
git push origin develop
```

### Opción 2: Trigger manual desde GitHub UI

1. Ve a **Actions** en tu repositorio
2. Selecciona el workflow `helm-cicd.yml`
3. Click en **Run workflow**
4. Selecciona rama y click en **Run workflow**

## Monitoreo de Deployments

### Ver logs del workflow

1. Ve a **Actions** en tu repositorio
2. Click en el run que quieres inspeccionar
3. Selecciona el job específico para ver detalles

### Monitoreo post-deployment en Kubernetes

```bash
# Ver estado del deployment
kubectl get deployment ms-payments -n default

# Ver pods
kubectl get pods -n default -l app=ms-payments

# Ver logs
kubectl logs -f deployment/ms-payments -n default

# Ver eventos
kubectl describe deployment ms-payments -n default
```

## Troubleshooting

### Error: "DOCKER_USERNAME secret not found"

**Solución:** Verifica que los secrets estén correctamente configurados en Settings → Secrets

### Error: "Unable to connect to Kubernetes cluster"

**Solución:** Verifica que el secret `KUBECONFIG` está correctamente configurado con tu kubeconfig

### Image push failed

**Solución:**

1. Verifica credenciales de Docker Hub
2. Asegúrate de que el repositorio existe: `edygc1988/ms_payments`
3. Verifica que el token de acceso está activo

### Helm deployment stuck in pending

**Solución:**

```bash
# Ver qué está pasando
kubectl describe pod <pod-name> -n default

# Ver eventos del cluster
kubectl get events -n default --sort-by='.lastTimestamp'
```

## Variables de Entorno en CI/CD

El workflow utiliza las siguientes variables:

```yaml
REGISTRY: docker.io
IMAGE_NAME: ${{ github.repository_owner }}/ms_payments
HELM_CHART_PATH: ./helm-recype
```

Puedes customizarlas editando el archivo `helm-cicd.yml`.

## Actualizaciones del Chart en Producción

Para actualizar el chart en producción:

1. **Cambios en `helm-recype/`:**

   ```bash
   # Edita values.yaml o templates
   git add helm-recype/
   git commit -m "Update Helm chart"
   git push origin main
   ```

   El workflow automáticamente despliega los cambios.

2. **Cambios en código:**

   ```bash
   # Modifica main.py, etc
   git add main.py
   git commit -m "Update application code"
   git push origin main
   ```

   Se construye nueva imagen y se despliega con imagen updated.

3. **Control de versiones de imagen:**
   ```bash
   # Para usar tag específico en lugar de 'latest'
   git tag v1.0.0
   git push origin v1.0.0
   ```

## Rollback de Deployments

Si necesitas rollback después de un deployment:

```bash
# Ver histórico
helm history ms-payments

# Rollback a versión anterior
helm rollback ms-payments

# Rollback a versión específica
helm rollback ms-payments 2
```

## Próximos Pasos

1. Configura los secrets en GitHub
2. Verifica que el Helm chart valida correctamente:
   ```bash
   ./scripts/helm-deploy.sh validate
   ```
3. Haz un push a `develop` para probar el build
4. Verifica que la imagen se construye correctamente en Docker Hub
5. Cuando esté listo, merge a `main` para disparar el deployment automático

## Soporte

Para más información:

- [Documentación de Helm](https://helm.sh/docs/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Kubernetes](https://kubernetes.io/docs/)
