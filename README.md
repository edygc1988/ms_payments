# ms_payments

## Despliegue automático a OpenShift

El flujo de trabajo de GitHub Actions construye la imagen Docker y, si se configuran los secretos, despliega automáticamente a OpenShift.

Secrets requeridos (configurar en GitHub repo Settings → Secrets):

- `DOCKER_USERNAME` / `DOCKER_PASSWORD`: (opcional) credenciales para publicar la imagen si usas un registry privado.
- `OPENSHIFT_API_URL`: URL del API server de OpenShift (ej. `https://api.cluster.example:6443`).
- `OPENSHIFT_TOKEN`: token de servicio con permisos para hacer `oc apply` / `rollout` en el proyecto.
- `OPENSHIFT_PROJECT`: nombre del proyecto/namespace en OpenShift.
- `OPENSHIFT_DEPLOYMENT_NAME`: (opcional) nombre del `Deployment` en OpenShift. Por defecto `ms-payments`.

Archivos añadidos al repo:

- `openshift/deployment.yaml`: plantilla de `Deployment` + `Service` con los marcadores `IMAGE_PLACEHOLDER` y `DEPLOYMENT_NAME_PLACEHOLDER` que el workflow sustituye antes de aplicar.

Cómo disparar el despliegue manualmente:

1. Push a la rama `main` o
2. Desde Actions → seleccionar el workflow `Build and Push multi-arch Docker image` → `Run workflow`.

Nota: Ajusta el `containerPort` en `openshift/deployment.yaml` si tu aplicación escucha en otro puerto.
