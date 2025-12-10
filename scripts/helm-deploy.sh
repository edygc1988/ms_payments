#!/bin/bash

# Helm deployment helper script for ms-payments
# Usage: ./scripts/helm-deploy.sh [action] [options]

set -e

CHART_PATH="./helm-recype"
RELEASE_NAME="ms-payments"
NAMESPACE="${NAMESPACE:-default}"
VALUES_FILE="${CHART_PATH}/values.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

check_helm() {
    if ! command -v helm &> /dev/null; then
        log_error "Helm is not installed"
        exit 1
    fi
    log_info "Helm version: $(helm version --short)"
}

check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    log_info "kubectl version: $(kubectl version --client --short)"
}

validate() {
    log_info "Validating Helm chart..."
    helm lint "${CHART_PATH}" --strict
    helm template "${RELEASE_NAME}" "${CHART_PATH}" --values "${VALUES_FILE}" > /dev/null
    log_info "Chart validation successful!"
}

dry_run() {
    log_info "Running Helm dry-run..."
    helm upgrade --install "${RELEASE_NAME}" "${CHART_PATH}" \
        --namespace "${NAMESPACE}" \
        --values "${VALUES_FILE}" \
        --dry-run \
        --debug
}

deploy() {
    local wait_flag="${1:-true}"
    
    log_info "Deploying with Helm..."
    
    if [ "${wait_flag}" = "true" ]; then
        helm upgrade --install "${RELEASE_NAME}" "${CHART_PATH}" \
            --namespace "${NAMESPACE}" \
            --values "${VALUES_FILE}" \
            --create-namespace \
            --wait \
            --timeout 5m
    else
        helm upgrade --install "${RELEASE_NAME}" "${CHART_PATH}" \
            --namespace "${NAMESPACE}" \
            --values "${VALUES_FILE}" \
            --create-namespace
    fi
    
    log_info "Deployment completed!"
}

rollback() {
    local revision="${1:-0}"
    
    log_info "Rolling back release..."
    
    if [ "${revision}" = "0" ]; then
        helm rollback "${RELEASE_NAME}" --namespace "${NAMESPACE}"
    else
        helm rollback "${RELEASE_NAME}" "${revision}" --namespace "${NAMESPACE}"
    fi
    
    log_info "Rollback completed!"
}

status() {
    log_info "Release status:"
    helm status "${RELEASE_NAME}" --namespace "${NAMESPACE}"
    
    log_info "\nDeployment status:"
    kubectl rollout status deployment/"${RELEASE_NAME}" -n "${NAMESPACE}" || true
    
    log_info "\nPods:"
    kubectl get pods -n "${NAMESPACE}" -l app="${RELEASE_NAME}" || true
}

history() {
    log_info "Release history:"
    helm history "${RELEASE_NAME}" --namespace "${NAMESPACE}"
}

uninstall() {
    log_warn "Uninstalling release ${RELEASE_NAME}..."
    helm uninstall "${RELEASE_NAME}" --namespace "${NAMESPACE}"
    log_info "Release uninstalled!"
}

update_image() {
    local new_tag="${1:-latest}"
    
    log_info "Updating image tag to: ${new_tag}"
    
    # Update the values file
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|tag: \".*\"|tag: \"${new_tag}\"|" "${VALUES_FILE}"
    else
        sed -i "s|tag: \".*\"|tag: \"${new_tag}\"|" "${VALUES_FILE}"
    fi
    
    log_info "Image tag updated in values.yaml"
}

show_help() {
    cat << EOF
Helm deployment helper script for ms-payments

Usage: ./scripts/helm-deploy.sh [action] [options]

Actions:
    validate        - Validate the Helm chart
    dry-run         - Perform a dry-run deployment
    deploy          - Deploy the Helm chart (with wait)
    deploy-no-wait  - Deploy the Helm chart (without wait)
    status          - Show release status
    history         - Show release history
    rollback        - Rollback to previous release (or specify revision)
    uninstall       - Uninstall the release
    update-image    - Update the container image tag

Environment Variables:
    NAMESPACE       - Kubernetes namespace (default: default)
    CHART_PATH      - Path to Helm chart (default: ./helm-recype)

Examples:
    ./scripts/helm-deploy.sh validate
    ./scripts/helm-deploy.sh dry-run
    ./scripts/helm-deploy.sh deploy
    ./scripts/helm-deploy.sh status
    ./scripts/helm-deploy.sh rollback
    ./scripts/helm-deploy.sh rollback 2
    ./scripts/helm-deploy.sh update-image v1.0.0
    NAMESPACE=production ./scripts/helm-deploy.sh deploy

EOF
}

# Main script logic
main() {
    local action="${1:-help}"
    
    case "${action}" in
        validate)
            check_helm
            validate
            ;;
        dry-run)
            check_helm
            validate
            dry_run
            ;;
        deploy)
            check_helm
            check_kubectl
            validate
            deploy true
            status
            ;;
        deploy-no-wait)
            check_helm
            check_kubectl
            validate
            deploy false
            ;;
        status)
            check_helm
            check_kubectl
            status
            ;;
        history)
            check_helm
            history
            ;;
        rollback)
            check_helm
            check_kubectl
            rollback "${2:-0}"
            status
            ;;
        uninstall)
            check_helm
            uninstall
            ;;
        update-image)
            update_image "${2}"
            ;;
        help)
            show_help
            ;;
        *)
            log_error "Unknown action: ${action}"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
