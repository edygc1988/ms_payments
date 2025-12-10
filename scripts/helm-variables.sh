#!/bin/bash

# Helm Variables Processor
# This script loads helm variables and creates secrets

set -e

# Source the variables file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VARIABLES_FILE="${PROJECT_ROOT}/.github/helm-variables.env"

if [ ! -f "$VARIABLES_FILE" ]; then
    echo "❌ Variables file not found: $VARIABLES_FILE"
    exit 1
fi

# Load variables
source "$VARIABLES_FILE"

echo "✅ Variables loaded successfully"
echo ""
echo "Configuration Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Database:"
echo "  User: $DB_USER"
echo "  Database: $DB_NAME"
echo "  Port: $DB_PORT"
echo ""
echo "Application:"
echo "  Name: $APP_NAME"
echo "  Environment: $APP_ENV"
echo "  Replicas: $APP_REPLICA_COUNT"
echo ""
echo "Image:"
echo "  Repository: $IMAGE_REPOSITORY"
echo "  Tag: $IMAGE_TAG"
echo ""
echo "HPA:"
echo "  Enabled: $HPA_ENABLED"
echo "  Min Replicas: $HPA_MIN_REPLICAS"
echo "  Max Replicas: $HPA_MAX_REPLICAS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Function to create secret
create_k8s_secret() {
    local namespace=$1
    local secret_name=$2
    local db_passwd=$3
    local api_passwd=$4

    echo "Creating Kubernetes secret: $secret_name"
    
    kubectl create secret generic "$secret_name" \
        --from-literal=db-password="$db_passwd" \
        --from-literal=api-password="$api_passwd" \
        -n "$namespace" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    echo "✅ Secret created successfully"
}

# Function to validate environment
validate_env() {
    echo "Validating environment variables..."
    
    local required_vars=(
        "DB_PASSWD"
        "API_PASSWD"
        "IMAGE_REPOSITORY"
        "IMAGE_TAG"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "❌ Missing required variable: $var"
            exit 1
        fi
    done
    
    echo "✅ All required variables are set"
}

# Function to generate values override
generate_values_override() {
    local output_file="$1"
    local namespace="${2:-default}"
    
    cat > "$output_file" << EOF
# Generated Helm Values Override
# Generated at: $(date)

replicaCount: $APP_REPLICA_COUNT

image:
  repository: $IMAGE_REPOSITORY
  tag: $IMAGE_TAG
  pullPolicy: $IMAGE_PULL_POLICY

service:
  type: $SERVICE_TYPE
  port: $SERVICE_PORT

container:
  port: $API_PORT

postgres:
  user: $DB_USER
  password: $DB_PASSWD
  database: $DB_NAME
  port: $DB_PORT

api:
  password: $API_PASSWD
  port: $API_PORT

resources:
  requests:
    cpu: $RESOURCES_REQUESTS_CPU
    memory: $RESOURCES_REQUESTS_MEMORY
  limits:
    cpu: $RESOURCES_LIMITS_CPU
    memory: $RESOURCES_LIMITS_MEMORY

hpa:
  enabled: $HPA_ENABLED
  minReplicas: $HPA_MIN_REPLICAS
  maxReplicas: $HPA_MAX_REPLICAS
  targetCPUUtilizationPercentage: $HPA_TARGET_CPU_UTILIZATION

persistence:
  enabled: $PERSISTENCE_ENABLED
  size: $PERSISTENCE_SIZE

namespace: $namespace
EOF

    echo "✅ Generated values override: $output_file"
}

# Main execution
case "${1:-validate}" in
    validate)
        validate_env
        ;;
    show-values)
        echo "Current Helm Variables:"
        cat "$VARIABLES_FILE" | grep -v "^#" | grep -v "^$"
        ;;
    create-secret)
        namespace="${2:-default}"
        validate_env
        create_k8s_secret "$namespace" "$SECRET_NAME" "$DB_PASSWD" "$API_PASSWD"
        ;;
    generate-override)
        output_file="${2:-values-override.yaml}"
        namespace="${3:-default}"
        validate_env
        generate_values_override "$output_file" "$namespace"
        ;;
    *)
        echo "Usage: $0 {validate|show-values|create-secret|generate-override} [namespace] [output-file]"
        echo ""
        echo "Commands:"
        echo "  validate              - Validate all environment variables"
        echo "  show-values           - Display all helm variables"
        echo "  create-secret         - Create Kubernetes secret (requires kubectl)"
        echo "  generate-override     - Generate values override file"
        exit 1
        ;;
esac
