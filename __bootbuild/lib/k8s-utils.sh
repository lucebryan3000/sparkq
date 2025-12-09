#!/usr/bin/env bash
# k8s-utils.sh - Kubernetes kubectl wrapper functions
# Part of bootbuild library collection

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/logging.sh"
source "${SCRIPT_DIR}/error-handling.sh"

# Global k8s configuration
K8S_TIMEOUT=${K8S_TIMEOUT:-300}
K8S_CONTEXT=""
K8S_NAMESPACE=${K8S_NAMESPACE:-default}

# Check kubectl availability
k8s_check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        error "kubectl not found. Please install kubectl first"
        return 1
    fi
    return 0
}

# Switch kubectl context
k8s_switch_context() {
    local context="${1:-}"

    if [[ -z "$context" ]]; then
        error "Context name required"
        return 1
    fi

    k8s_check_kubectl || return 1

    info "Switching to context: $context"

    if kubectl config use-context "$context" &> /dev/null; then
        K8S_CONTEXT="$context"
        success "Switched to context: $context"
        return 0
    else
        error "Failed to switch to context: $context"
        return 1
    fi
}

# Get current context
k8s_get_current_context() {
    k8s_check_kubectl || return 1
    kubectl config current-context
}

# List available contexts
k8s_list_contexts() {
    k8s_check_kubectl || return 1
    kubectl config get-contexts -o name
}

# List pods
k8s_get_pods() {
    local namespace="${1:-$K8S_NAMESPACE}"
    local selector="${2:-}"

    k8s_check_kubectl || return 1

    local cmd="kubectl get pods -n $namespace"

    if [[ -n "$selector" ]]; then
        cmd="$cmd -l $selector"
    fi

    eval "$cmd"
}

# Get pod by name pattern
k8s_find_pod() {
    local name_pattern="${1:-}"
    local namespace="${2:-$K8S_NAMESPACE}"

    if [[ -z "$name_pattern" ]]; then
        error "Pod name pattern required"
        return 1
    fi

    k8s_check_kubectl || return 1

    kubectl get pods -n "$namespace" --no-headers | grep "$name_pattern" | head -1 | awk '{print $1}'
}

# Check pod status
k8s_pod_status() {
    local pod_name="${1:-}"
    local namespace="${2:-$K8S_NAMESPACE}"

    if [[ -z "$pod_name" ]]; then
        error "Pod name required"
        return 1
    fi

    k8s_check_kubectl || return 1

    kubectl get pod "$pod_name" -n "$namespace" -o jsonpath='{.status.phase}'
}

# Wait for pod to be ready
k8s_wait_pod_ready() {
    local pod_name="${1:-}"
    local namespace="${2:-$K8S_NAMESPACE}"
    local timeout="${3:-$K8S_TIMEOUT}"

    if [[ -z "$pod_name" ]]; then
        error "Pod name required"
        return 1
    fi

    k8s_check_kubectl || return 1

    info "Waiting for pod $pod_name to be ready (timeout: ${timeout}s)"

    if kubectl wait --for=condition=ready pod "$pod_name" -n "$namespace" --timeout="${timeout}s" &> /dev/null; then
        success "Pod $pod_name is ready"
        return 0
    else
        error "Pod $pod_name failed to become ready within ${timeout}s"
        return 1
    fi
}

# List deployments
k8s_get_deployments() {
    local namespace="${1:-$K8S_NAMESPACE}"
    local selector="${2:-}"

    k8s_check_kubectl || return 1

    local cmd="kubectl get deployments -n $namespace"

    if [[ -n "$selector" ]]; then
        cmd="$cmd -l $selector"
    fi

    eval "$cmd"
}

# Get deployment status
k8s_deployment_status() {
    local deployment="${1:-}"
    local namespace="${2:-$K8S_NAMESPACE}"

    if [[ -z "$deployment" ]]; then
        error "Deployment name required"
        return 1
    fi

    k8s_check_kubectl || return 1

    kubectl get deployment "$deployment" -n "$namespace" -o jsonpath='{.status.conditions[?(@.type=="Available")].status}'
}

# Check rollout status
k8s_rollout_status() {
    local resource_type="${1:-deployment}"
    local resource_name="${2:-}"
    local namespace="${3:-$K8S_NAMESPACE}"
    local timeout="${4:-$K8S_TIMEOUT}"

    if [[ -z "$resource_name" ]]; then
        error "Resource name required"
        return 1
    fi

    k8s_check_kubectl || return 1

    info "Checking rollout status for $resource_type/$resource_name"

    if timeout "$timeout" kubectl rollout status "$resource_type/$resource_name" -n "$namespace"; then
        success "Rollout completed successfully"
        return 0
    else
        error "Rollout failed or timed out"
        return 1
    fi
}

# Restart deployment
k8s_restart_deployment() {
    local deployment="${1:-}"
    local namespace="${2:-$K8S_NAMESPACE}"

    if [[ -z "$deployment" ]]; then
        error "Deployment name required"
        return 1
    fi

    k8s_check_kubectl || return 1

    info "Restarting deployment: $deployment"

    if kubectl rollout restart deployment "$deployment" -n "$namespace"; then
        success "Deployment restart initiated"
        k8s_rollout_status "deployment" "$deployment" "$namespace"
        return $?
    else
        error "Failed to restart deployment"
        return 1
    fi
}

# Get pod logs
k8s_logs() {
    local pod_name="${1:-}"
    local namespace="${2:-$K8S_NAMESPACE}"
    local container="${3:-}"
    local follow="${4:-false}"
    local tail="${5:-100}"

    if [[ -z "$pod_name" ]]; then
        error "Pod name required"
        return 1
    fi

    k8s_check_kubectl || return 1

    local cmd="kubectl logs $pod_name -n $namespace --tail=$tail"

    if [[ -n "$container" ]]; then
        cmd="$cmd -c $container"
    fi

    if [[ "$follow" == "true" ]]; then
        cmd="$cmd -f"
    fi

    eval "$cmd"
}

# Get logs from all pods matching label
k8s_logs_by_label() {
    local selector="${1:-}"
    local namespace="${2:-$K8S_NAMESPACE}"
    local tail="${3:-100}"

    if [[ -z "$selector" ]]; then
        error "Label selector required"
        return 1
    fi

    k8s_check_kubectl || return 1

    kubectl logs -l "$selector" -n "$namespace" --tail="$tail" --all-containers=true
}

# Execute command in pod
k8s_exec() {
    local pod_name="${1:-}"
    local namespace="${2:-$K8S_NAMESPACE}"
    local container="${3:-}"
    shift 3
    local command=("$@")

    if [[ -z "$pod_name" ]]; then
        error "Pod name required"
        return 1
    fi

    if [[ ${#command[@]} -eq 0 ]]; then
        error "Command required"
        return 1
    fi

    k8s_check_kubectl || return 1

    local cmd="kubectl exec $pod_name -n $namespace"

    if [[ -n "$container" ]]; then
        cmd="$cmd -c $container"
    fi

    cmd="$cmd -- ${command[*]}"

    eval "$cmd"
}

# Interactive shell in pod
k8s_shell() {
    local pod_name="${1:-}"
    local namespace="${2:-$K8S_NAMESPACE}"
    local container="${3:-}"
    local shell="${4:-/bin/bash}"

    if [[ -z "$pod_name" ]]; then
        error "Pod name required"
        return 1
    fi

    k8s_check_kubectl || return 1

    info "Opening shell in pod: $pod_name"

    local cmd="kubectl exec -it $pod_name -n $namespace"

    if [[ -n "$container" ]]; then
        cmd="$cmd -c $container"
    fi

    cmd="$cmd -- $shell"

    eval "$cmd"
}

# Apply manifest
k8s_apply() {
    local manifest="${1:-}"
    local namespace="${2:-$K8S_NAMESPACE}"

    if [[ -z "$manifest" ]]; then
        error "Manifest file or directory required"
        return 1
    fi

    if [[ ! -e "$manifest" ]]; then
        error "Manifest not found: $manifest"
        return 1
    fi

    k8s_check_kubectl || return 1

    info "Applying manifest: $manifest"

    if kubectl apply -f "$manifest" -n "$namespace"; then
        success "Manifest applied successfully"
        return 0
    else
        error "Failed to apply manifest"
        return 1
    fi
}

# Delete resources
k8s_delete() {
    local resource_type="${1:-}"
    local resource_name="${2:-}"
    local namespace="${3:-$K8S_NAMESPACE}"
    local force="${4:-false}"

    if [[ -z "$resource_type" ]] || [[ -z "$resource_name" ]]; then
        error "Resource type and name required"
        return 1
    fi

    k8s_check_kubectl || return 1

    warn "Deleting $resource_type/$resource_name from namespace $namespace"

    local cmd="kubectl delete $resource_type $resource_name -n $namespace"

    if [[ "$force" == "true" ]]; then
        cmd="$cmd --force --grace-period=0"
    fi

    if eval "$cmd"; then
        success "Resource deleted successfully"
        return 0
    else
        error "Failed to delete resource"
        return 1
    fi
}

# Scale deployment
k8s_scale() {
    local deployment="${1:-}"
    local replicas="${2:-1}"
    local namespace="${3:-$K8S_NAMESPACE}"

    if [[ -z "$deployment" ]]; then
        error "Deployment name required"
        return 1
    fi

    if ! [[ "$replicas" =~ ^[0-9]+$ ]]; then
        error "Replicas must be a number"
        return 1
    fi

    k8s_check_kubectl || return 1

    info "Scaling deployment $deployment to $replicas replicas"

    if kubectl scale deployment "$deployment" --replicas="$replicas" -n "$namespace"; then
        success "Deployment scaled successfully"
        return 0
    else
        error "Failed to scale deployment"
        return 1
    fi
}

# Create ConfigMap from file
k8s_create_configmap() {
    local name="${1:-}"
    local namespace="${2:-$K8S_NAMESPACE}"
    local source="${3:-}"
    local from_type="${4:-file}"

    if [[ -z "$name" ]] || [[ -z "$source" ]]; then
        error "ConfigMap name and source required"
        return 1
    fi

    k8s_check_kubectl || return 1

    info "Creating ConfigMap: $name"

    local cmd="kubectl create configmap $name -n $namespace"

    case "$from_type" in
        file)
            if [[ ! -f "$source" ]]; then
                error "Source file not found: $source"
                return 1
            fi
            cmd="$cmd --from-file=$source"
            ;;
        literal)
            cmd="$cmd --from-literal=$source"
            ;;
        env-file)
            if [[ ! -f "$source" ]]; then
                error "Env file not found: $source"
                return 1
            fi
            cmd="$cmd --from-env-file=$source"
            ;;
        *)
            error "Invalid from_type: $from_type (use: file, literal, env-file)"
            return 1
            ;;
    esac

    if eval "$cmd"; then
        success "ConfigMap created successfully"
        return 0
    else
        error "Failed to create ConfigMap"
        return 1
    fi
}

# Create Secret
k8s_create_secret() {
    local name="${1:-}"
    local namespace="${2:-$K8S_NAMESPACE}"
    local type="${3:-generic}"
    local source="${4:-}"
    local from_type="${5:-literal}"

    if [[ -z "$name" ]] || [[ -z "$source" ]]; then
        error "Secret name and source required"
        return 1
    fi

    k8s_check_kubectl || return 1

    info "Creating Secret: $name"

    local cmd="kubectl create secret $type $name -n $namespace"

    case "$from_type" in
        file)
            if [[ ! -f "$source" ]]; then
                error "Source file not found: $source"
                return 1
            fi
            cmd="$cmd --from-file=$source"
            ;;
        literal)
            cmd="$cmd --from-literal=$source"
            ;;
        env-file)
            if [[ ! -f "$source" ]]; then
                error "Env file not found: $source"
                return 1
            fi
            cmd="$cmd --from-env-file=$source"
            ;;
        *)
            error "Invalid from_type: $from_type (use: file, literal, env-file)"
            return 1
            ;;
    esac

    if eval "$cmd"; then
        success "Secret created successfully"
        return 0
    else
        error "Failed to create Secret"
        return 1
    fi
}

# Port forward
k8s_port_forward() {
    local resource="${1:-}"
    local local_port="${2:-}"
    local remote_port="${3:-$local_port}"
    local namespace="${4:-$K8S_NAMESPACE}"

    if [[ -z "$resource" ]] || [[ -z "$local_port" ]]; then
        error "Resource and port required"
        return 1
    fi

    k8s_check_kubectl || return 1

    info "Port forwarding $resource: $local_port -> $remote_port"

    kubectl port-forward "$resource" "$local_port:$remote_port" -n "$namespace"
}

# Get resource YAML
k8s_get_yaml() {
    local resource_type="${1:-}"
    local resource_name="${2:-}"
    local namespace="${3:-$K8S_NAMESPACE}"

    if [[ -z "$resource_type" ]] || [[ -z "$resource_name" ]]; then
        error "Resource type and name required"
        return 1
    fi

    k8s_check_kubectl || return 1

    kubectl get "$resource_type" "$resource_name" -n "$namespace" -o yaml
}

# Describe resource
k8s_describe() {
    local resource_type="${1:-}"
    local resource_name="${2:-}"
    local namespace="${3:-$K8S_NAMESPACE}"

    if [[ -z "$resource_type" ]] || [[ -z "$resource_name" ]]; then
        error "Resource type and name required"
        return 1
    fi

    k8s_check_kubectl || return 1

    kubectl describe "$resource_type" "$resource_name" -n "$namespace"
}

# Get events
k8s_get_events() {
    local namespace="${1:-$K8S_NAMESPACE}"
    local sort_by="${2:-lastTimestamp}"

    k8s_check_kubectl || return 1

    kubectl get events -n "$namespace" --sort-by=".${sort_by}"
}

# Export functions
export -f k8s_check_kubectl
export -f k8s_switch_context
export -f k8s_get_current_context
export -f k8s_list_contexts
export -f k8s_get_pods
export -f k8s_find_pod
export -f k8s_pod_status
export -f k8s_wait_pod_ready
export -f k8s_get_deployments
export -f k8s_deployment_status
export -f k8s_rollout_status
export -f k8s_restart_deployment
export -f k8s_logs
export -f k8s_logs_by_label
export -f k8s_exec
export -f k8s_shell
export -f k8s_apply
export -f k8s_delete
export -f k8s_scale
export -f k8s_create_configmap
export -f k8s_create_secret
export -f k8s_port_forward
export -f k8s_get_yaml
export -f k8s_describe
export -f k8s_get_events
