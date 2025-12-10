#!/bin/zsh

# Script para desplegar PostgreSQL con Helm en Kubernetes
# Uso: ./deploy-postgres.sh [namespace] [release-name]

set -e

NAMESPACE=${1:-default}
RELEASE_NAME=${2:-mi-postgres}
VALUES_FILE="./helm-recype/postgresql-values.yaml"

echo "🚀 Desplegando PostgreSQL con Helm..."
echo "   Namespace: $NAMESPACE"
echo "   Release: $RELEASE_NAME"
echo "   Values: $VALUES_FILE"

# Crear namespace si no existe
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Agregar repo de Bitnami si no existe
echo "📦 Agregando repositorio Bitnami..."
helm repo add bitnami https://charts.bitnami.com/bitnami || true
helm repo update

# Desplegar PostgreSQL
echo "⏳ Desplegando PostgreSQL..."
helm upgrade --install "$RELEASE_NAME" oci://registry-1.docker.io/bitnamicharts/postgresql \
  --namespace "$NAMESPACE" \
  --values "$VALUES_FILE" \
  --wait \
  --timeout 5m

echo ""
echo "✅ PostgreSQL desplegado exitosamente!"
echo ""
echo "📝 Información de conexión:"
echo "   Host: $RELEASE_NAME-primary.$NAMESPACE.svc.cluster.local"
echo "   Port: 5432"
echo "   Database: miapp"
echo "   Username: miapp_user"
echo "   Password: MiPasswordApp123"
echo ""
echo "🔧 Para conectarte localmente:"
echo "   kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-primary 5432:5432"
echo "   psql -h localhost -U miapp_user -d miapp"
echo ""
echo "📊 Ver estado:"
echo "   kubectl get pods -n $NAMESPACE"
echo "   helm status $RELEASE_NAME -n $NAMESPACE"
echo ""
