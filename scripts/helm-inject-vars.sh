#!/bin/bash

# Helm Variables Injector Script
# Inyecta variables desde helm-variables.env a los values de Helm
# Soporta múltiples ambientes (dev, prod, staging)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
GITHUB_DIR="${PROJECT_ROOT}/.github"
HELM_DIR="${PROJECT_ROOT}/helm-recype"
ENV_FILE="${GITHUB_DIR}/helm-variables.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [ "$DEBUG" = "true" ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

check_files() {
    if [ ! -f "$ENV_FILE" ]; then
        log_error "Environment file not found: $ENV_FILE"
        exit 1
    fi
    
    if [ ! -d "$HELM_DIR" ]; then
        log_error "Helm directory not found: $HELM_DIR"
        exit 1
    fi
    
    log_info "Files found: ENV file and Helm directory"
}

load_env() {
    log_info "Loading environment variables from: $ENV_FILE"
    
    # Source the env file but only export selected variables
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
    
    log_info "Environment variables loaded successfully"
}

validate_secrets() {
    log_info "Validating critical secrets..."
    
    local missing=0
    
    if [ -z "$DB_PASSWD" ]; then
        log_error "DB_PASSWD is not set"
        missing=$((missing + 1))
    else
        log_info "✓ DB_PASSWD is set to: $(echo $DB_PASSWD | head -c 5)..."
    fi
    
    if [ -z "$API_PASSWD" ]; then
        log_error "API_PASSWD is not set"
        missing=$((missing + 1))
    else
        log_info "✓ API_PASSWD is set to: $(echo $API_PASSWD | head -c 5)..."
    fi
    
    if [ "$missing" -gt 0 ]; then
        log_error "$missing critical secret(s) missing"
        exit 1
    fi
    
    log_info "All critical secrets validated"
}

create_secrets_file() {
    local env="${1:-default}"
    local output_file="${HELM_DIR}/.generated-values-${env}.yaml"
    
    log_info "Creating secrets file for environment: $env"
    log_info "Output file: $output_file"
    
    cat > "$output_file" << EOF
# Auto-generated Helm values with secrets
# Generated on: $(date -u +'%Y-%m-%dT%H:%M:%SZ')
# Environment: $env
# WARNING: This file contains sensitive data. Never commit to version control!

# Database Configuration
database:
  user: "${DB_USER}"
  password: "${DB_PASSWD}"
  name: "${DB_NAME}"
  port: ${DB_PORT}
  host: "postgresql.${env}.svc.cluster.local"

# API Configuration
api:
  password: "${API_PASSWD}"
  port: ${API_PORT}

# Kubernetes Secrets
secrets:
  create: true
  name: "ms-payments-secrets"
  
  data:
    db-user: "${DB_USER}"
    db-password: "${DB_PASSWD}"
    db-name: "${DB_NAME}"
    db-port: "${DB_PORT}"
    api-password: "${API_PASSWD}"

# Environment variables
env:
  - name: DB_PASSWD
    valueFrom:
      secretKeyRef:
        name: ms-payments-secrets
        key: db-password
  - name: API_PASSWD
    valueFrom:
      secretKeyRef:
        name: ms-payments-secrets
        key: api-password
  - name: DB_USER
    valueFrom:
      secretKeyRef:
        name: ms-payments-secrets
        key: db-user
  - name: DATABASE_URL
    value: "postgresql://${DB_USER}:${DB_PASSWD}@postgresql.${env}.svc.cluster.local:${DB_PORT}/${DB_NAME}"

# ConfigMap for non-sensitive data
configMap:
  create: true
  name: "ms-payments-config"
  
  data:
    APP_ENV: "${APP_ENV}"
    APP_NAME: "${APP_NAME}"
    DB_NAME: "${DB_NAME}"
    DB_PORT: "${DB_PORT}"
    DB_USER: "${DB_USER}"
    API_PORT: "${API_PORT}"

# Image configuration
image:
  repository: "${IMAGE_REPOSITORY}"
  tag: "${IMAGE_TAG}"
  pullPolicy: "${IMAGE_PULL_POLICY}"

# Replica count
replicaCount: ${APP_REPLICA_COUNT}

# Resources
resources:
  requests:
    cpu: "${RESOURCES_REQUESTS_CPU}"
    memory: "${RESOURCES_REQUESTS_MEMORY}"
  limits:
    cpu: "${RESOURCES_LIMITS_CPU}"
    memory: "${RESOURCES_LIMITS_MEMORY}"

# Service
service:
  type: "${SERVICE_TYPE}"
  port: ${SERVICE_PORT}

# HPA
hpa:
  enabled: ${HPA_ENABLED}
  minReplicas: ${HPA_MIN_REPLICAS}
  maxReplicas: ${HPA_MAX_REPLICAS}
  targetCPUUtilizationPercentage: ${HPA_TARGET_CPU_UTILIZATION}

# Namespace
namespace: "${NAMESPACE}"
EOF

    log_info "Secrets file created: $output_file"
    
    # Set restricted permissions
    chmod 600 "$output_file"
    log_info "File permissions set to 600 (read/write by owner only)"
}

create_kubernetes_secret() {
    local namespace="${1:-default}"
    
    log_info "Creating Kubernetes secret in namespace: $namespace"
    
    # Create namespace if it doesn't exist
    kubectl create namespace "$namespace" 2>/dev/null || true
    
    # Create the secret
    kubectl create secret generic ms-payments-secrets \
        --from-literal=db-user="$DB_USER" \
        --from-literal=db-password="$DB_PASSWD" \
        --from-literal=db-name="$DB_NAME" \
        --from-literal=db-port="$DB_PORT" \
        --from-literal=api-password="$API_PASSWD" \
        --namespace="$namespace" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log_info "Kubernetes secret created/updated in namespace: $namespace"
}

validate_helm_template() {
    local values_file="${1:-${HELM_DIR}/values.yaml}"
    
    log_info "Validating Helm template with values file: $values_file"
    
    if ! helm template ms-payments "$HELM_DIR" -f "$values_file" > /dev/null 2>&1; then
        log_error "Helm template validation failed"
        return 1
    fi
    
    log_info "Helm template validation successful"
    return 0
}

show_help() {
    cat << EOF
${BLUE}Helm Variables Injector Script${NC}

Usage: ./scripts/helm-inject-vars.sh [command] [options]

Commands:
    validate            - Validate critical secrets
    generate [env]      - Generate values file with secrets (default: default)
    create-secret [ns]  - Create Kubernetes secret (default: default)
    template [file]     - Validate Helm template with values file
    dry-run [env]       - Preview what will be generated (without creating)
    full [env] [ns]     - Complete setup: generate and create secret
    help                - Show this help message

Environment:
    ENV_FILE            - Path to environment variables file (default: .github/helm-variables.env)
    DEBUG               - Set to 'true' to enable debug output

Examples:
    # Validate secrets are set
    ./scripts/helm-inject-vars.sh validate
    
    # Generate values file for production
    ./scripts/helm-inject-vars.sh generate prod
    
    # Create Kubernetes secret in production namespace
    ./scripts/helm-inject-vars.sh create-secret production
    
    # Complete setup for production
    ./scripts/helm-inject-vars.sh full prod production
    
    # Enable debug output
    DEBUG=true ./scripts/helm-inject-vars.sh validate
    
    # Preview what will be generated
    ./scripts/helm-inject-vars.sh dry-run prod

Files Generated:
    .helm-recype/.generated-values-{env}.yaml   - Generated values file with secrets

${YELLOW}IMPORTANT:${NC}
    - Never commit generated values files with real secrets
    - Always use .gitignore for .generated-values-*.yaml files
    - Consider using sealed-secrets or external-secrets in production

EOF
}

# Main script logic
main() {
    local command="${1:-help}"
    
    case "$command" in
        validate)
            check_files
            load_env
            validate_secrets
            ;;
        generate)
            local env="${2:-default}"
            check_files
            load_env
            validate_secrets
            create_secrets_file "$env"
            ;;
        create-secret)
            local namespace="${2:-default}"
            check_files
            load_env
            validate_secrets
            create_kubernetes_secret "$namespace"
            ;;
        template)
            local values_file="${2:-${HELM_DIR}/values.yaml}"
            validate_helm_template "$values_file"
            ;;
        dry-run)
            local env="${2:-default}"
            check_files
            load_env
            validate_secrets
            log_info "DRY RUN: Would generate values file for environment: $env"
            log_info "Output would be: ${HELM_DIR}/.generated-values-${env}.yaml"
            ;;
        full)
            local env="${2:-default}"
            local namespace="${3:-default}"
            check_files
            load_env
            validate_secrets
            create_secrets_file "$env"
            if command -v kubectl &> /dev/null; then
                create_kubernetes_secret "$namespace"
            else
                log_warn "kubectl not found, skipping Kubernetes secret creation"
            fi
            ;;
        help)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
