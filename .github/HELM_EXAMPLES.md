# Helm Deployment Configuration Examples

## Despliegue en Desarrollo

```bash
# Con valores de desarrollo
./scripts/helm-deploy.sh validate
helm install ms-payments ./helm-recype \
  -f ./helm-recype/values-dev.yaml \
  --namespace development \
  --create-namespace

# Verificar
kubectl get all -n development
```

## Despliegue en Producción

```bash
# Con valores de producción
helm install ms-payments ./helm-recype \
  -f ./helm-recype/values.yaml \
  -f ./helm-recype/values-prod.yaml \
  --namespace production \
  --create-namespace \
  --wait \
  --timeout 10m

# Verificar
kubectl get all -n production
kubectl logs -f deployment/ms-payments -n production
```

## Actualizaciones de Deployment

```bash
# Actualizar a nueva versión
helm upgrade ms-payments ./helm-recype \
  -f ./helm-recype/values-prod.yaml \
  --namespace production \
  --wait

# Con cambios en imagen específicos
helm set image \
  deployment/ms-payments \
  ms-payments=edygc1988/ms_payments:v1.0.0 \
  -n production
```

## Variables de Configuración Personalizadas

Si necesitas cambiar valores sin editar los archivos YAML:

```bash
# Override de valores individuales
helm install ms-payments ./helm-recype \
  --set replicaCount=5 \
  --set image.tag=v1.0.0 \
  --set resources.requests.cpu=1 \
  --set hpa.maxReplicas=20

# Con múltiples archivos de valores
helm install ms-payments ./helm-recype \
  -f values.yaml \
  -f values-prod.yaml \
  -f values-custom.yaml \
  --namespace production
```

## Monitoreo y Troubleshooting

```bash
# Ver valores actuales del release
helm get values ms-payments -n production

# Ver manifest generado
helm get manifest ms-payments -n production

# Ver historial de cambios
helm history ms-payments -n production

# Verificar estado del Helm release
helm status ms-payments -n production

# Obtener información detallada del Pod
kubectl describe pod -l app=ms-payments -n production

# Ver logs del pod
kubectl logs -f deployment/ms-payments -n production

# Acceso remoto al pod
kubectl exec -it deployment/ms-payments -n production -- /bin/bash
```

## Configuración de Seguridad Adicional

```bash
# Crear imagePullSecret para registros privados
kubectl create secret docker-registry regcred \
  --docker-server=docker.io \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  -n production

# Crear secret genérico para credenciales
kubectl create secret generic ms-payments-secrets \
  --from-literal=API_KEY=your-api-key \
  --from-literal=DB_PASSWORD=your-db-password \
  -n production
```

## Limpieza

```bash
# Desinstalar la aplicación
helm uninstall ms-payments -n production

# Eliminar namespace (con todo su contenido)
kubectl delete namespace production
```

## Referencias

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [FastAPI on Kubernetes](https://fastapi.tiangolo.com/deployment/concepts/)
