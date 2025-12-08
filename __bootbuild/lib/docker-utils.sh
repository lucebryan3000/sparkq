#!/usr/bin/env bash
# docker-utils.sh - Docker build, push, and management utilities
# Part of bootbuild library

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/log-utils.sh"

# Prevent double-sourcing
[[ -n "${_BOOTSTRAP_DOCKER_UTILS_LOADED:-}" ]] && return 0
_BOOTSTRAP_DOCKER_UTILS_LOADED=1

# Docker build with caching
# Usage: docker_build <dockerfile> <image_name> <tag> [build_args...]
docker_build() {
    local dockerfile="${1:-Dockerfile}"
    local image_name="${2:?Image name required}"
    local tag="${3:-latest}"
    shift 3 || true

    log_info "Building Docker image: ${image_name}:${tag}"

    if [[ ! -f "$dockerfile" ]]; then
        log_error "Dockerfile not found: $dockerfile"
        return 1
    fi

    local build_args=()
    for arg in "$@"; do
        build_args+=(--build-arg "$arg")
    done

    # Build with BuildKit for better caching
    if docker build \
        --file "$dockerfile" \
        --tag "${image_name}:${tag}" \
        --cache-from "${image_name}:latest" \
        --cache-from "${image_name}:${tag}" \
        "${build_args[@]}" \
        . ; then
        log_success "Built ${image_name}:${tag}"
        return 0
    else
        log_error "Build failed for ${image_name}:${tag}"
        return 1
    fi
}

# Build with multi-stage optimization
# Usage: docker_build_multistage <dockerfile> <image_name> <tag> <target_stage>
docker_build_multistage() {
    local dockerfile="${1:-Dockerfile}"
    local image_name="${2:?Image name required}"
    local tag="${3:-latest}"
    local target="${4:-}"

    log_info "Building multi-stage image: ${image_name}:${tag}"

    local target_arg=()
    if [[ -n "$target" ]]; then
        target_arg=(--target "$target")
        log_info "Target stage: $target"
    fi

    if DOCKER_BUILDKIT=1 docker build \
        --file "$dockerfile" \
        --tag "${image_name}:${tag}" \
        "${target_arg[@]}" \
        --cache-from "${image_name}:latest" \
        . ; then
        log_success "Multi-stage build complete: ${image_name}:${tag}"
        return 0
    else
        log_error "Multi-stage build failed"
        return 1
    fi
}

# Push image to registry
# Usage: docker_push <image_name> <tag> [registry]
docker_push() {
    local image_name="${1:?Image name required}"
    local tag="${2:-latest}"
    local registry="${3:-}"

    local full_image="${image_name}:${tag}"
    if [[ -n "$registry" ]]; then
        full_image="${registry}/${image_name}:${tag}"
        docker tag "${image_name}:${tag}" "$full_image"
    fi

    log_info "Pushing image: $full_image"

    if docker push "$full_image"; then
        log_success "Pushed $full_image"
        return 0
    else
        log_error "Push failed for $full_image"
        return 1
    fi
}

# Pull image from registry
# Usage: docker_pull <image_name> <tag> [registry]
docker_pull() {
    local image_name="${1:?Image name required}"
    local tag="${2:-latest}"
    local registry="${3:-}"

    local full_image="${image_name}:${tag}"
    if [[ -n "$registry" ]]; then
        full_image="${registry}/${image_name}:${tag}"
    fi

    log_info "Pulling image: $full_image"

    if docker pull "$full_image"; then
        log_success "Pulled $full_image"

        # Tag without registry prefix if needed
        if [[ -n "$registry" ]]; then
            docker tag "$full_image" "${image_name}:${tag}"
        fi
        return 0
    else
        log_error "Pull failed for $full_image"
        return 1
    fi
}

# Registry login
# Usage: docker_registry_login <registry> [username] [password]
docker_registry_login() {
    local registry="${1:?Registry required}"
    local username="${2:-}"
    local password="${3:-}"

    log_info "Logging into registry: $registry"

    if [[ -n "$username" && -n "$password" ]]; then
        echo "$password" | docker login "$registry" --username "$username" --password-stdin
    else
        # Interactive login or use existing credentials
        docker login "$registry"
    fi

    if [[ $? -eq 0 ]]; then
        log_success "Logged into $registry"
        return 0
    else
        log_error "Login failed for $registry"
        return 1
    fi
}

# Start docker-compose services
# Usage: docker_compose_up [compose_file] [service...]
docker_compose_up() {
    local compose_file="${1:-docker-compose.yml}"
    shift || true

    if [[ ! -f "$compose_file" ]]; then
        log_error "Compose file not found: $compose_file"
        return 1
    fi

    log_info "Starting services from $compose_file"

    local services=("$@")
    if docker compose -f "$compose_file" up -d "${services[@]}"; then
        log_success "Services started"
        docker compose -f "$compose_file" ps
        return 0
    else
        log_error "Failed to start services"
        return 1
    fi
}

# Stop docker-compose services
# Usage: docker_compose_down [compose_file] [--volumes]
docker_compose_down() {
    local compose_file="${1:-docker-compose.yml}"
    local remove_volumes="${2:-}"

    if [[ ! -f "$compose_file" ]]; then
        log_error "Compose file not found: $compose_file"
        return 1
    fi

    log_info "Stopping services from $compose_file"

    local down_args=()
    if [[ "$remove_volumes" == "--volumes" ]]; then
        down_args+=(--volumes)
        log_info "Removing volumes"
    fi

    if docker compose -f "$compose_file" down "${down_args[@]}"; then
        log_success "Services stopped"
        return 0
    else
        log_error "Failed to stop services"
        return 1
    fi
}

# Restart docker-compose services
# Usage: docker_compose_restart [compose_file] [service...]
docker_compose_restart() {
    local compose_file="${1:-docker-compose.yml}"
    shift || true

    log_info "Restarting services"

    local services=("$@")
    if docker compose -f "$compose_file" restart "${services[@]}"; then
        log_success "Services restarted"
        return 0
    else
        log_error "Failed to restart services"
        return 1
    fi
}

# View compose logs
# Usage: docker_compose_logs [compose_file] [service] [--follow]
docker_compose_logs() {
    local compose_file="${1:-docker-compose.yml}"
    local service="${2:-}"
    local follow="${3:-}"

    local log_args=()
    if [[ "$follow" == "--follow" ]]; then
        log_args+=(-f)
    fi

    if [[ -n "$service" ]]; then
        docker compose -f "$compose_file" logs "${log_args[@]}" "$service"
    else
        docker compose -f "$compose_file" logs "${log_args[@]}"
    fi
}

# List running containers
# Usage: docker_ps_running [format]
docker_ps_running() {
    local format="${1:-table}"

    case "$format" in
        table)
            docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}\t{{.Ports}}"
            ;;
        json)
            docker ps --format "{{json .}}"
            ;;
        simple)
            docker ps --format "{{.Names}}"
            ;;
        *)
            docker ps
            ;;
    esac
}

# Check if container is running
# Usage: docker_is_running <container_name>
docker_is_running() {
    local container="${1:?Container name required}"

    if docker ps --filter "name=^${container}$" --format "{{.Names}}" | grep -q "^${container}$"; then
        return 0
    else
        return 1
    fi
}

# Wait for container to be healthy
# Usage: docker_wait_healthy <container_name> [timeout_seconds]
docker_wait_healthy() {
    local container="${1:?Container name required}"
    local timeout="${2:-60}"
    local elapsed=0

    log_info "Waiting for $container to be healthy (timeout: ${timeout}s)"

    while [[ $elapsed -lt $timeout ]]; do
        local health_status
        health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "none")

        if [[ "$health_status" == "healthy" ]]; then
            log_success "$container is healthy"
            return 0
        elif [[ "$health_status" == "none" ]]; then
            if docker_is_running "$container"; then
                log_success "$container is running (no health check)"
                return 0
            fi
        fi

        sleep 2
        elapsed=$((elapsed + 2))
    done

    log_error "$container did not become healthy within ${timeout}s"
    return 1
}

# Cleanup unused Docker resources
# Usage: docker_cleanup [--all]
docker_cleanup() {
    local all_flag="${1:-}"

    log_info "Cleaning up Docker resources"

    # Remove stopped containers
    log_info "Removing stopped containers..."
    docker container prune -f

    # Remove dangling images
    log_info "Removing dangling images..."
    docker image prune -f

    # Remove unused networks
    log_info "Removing unused networks..."
    docker network prune -f

    # Remove unused volumes
    log_info "Removing unused volumes..."
    docker volume prune -f

    if [[ "$all_flag" == "--all" ]]; then
        log_info "Removing all unused images (not just dangling)..."
        docker image prune -a -f
    fi

    log_success "Cleanup complete"
    docker system df
}

# Inspect image layers
# Usage: docker_inspect_layers <image_name> [tag]
docker_inspect_layers() {
    local image_name="${1:?Image name required}"
    local tag="${2:-latest}"
    local full_image="${image_name}:${tag}"

    log_info "Inspecting layers for $full_image"

    if ! docker image inspect "$full_image" &>/dev/null; then
        log_error "Image not found: $full_image"
        return 1
    fi

    echo "=== Image History ==="
    docker history "$full_image" --human

    echo ""
    echo "=== Layer Details ==="
    docker image inspect "$full_image" --format='{{range .RootFS.Layers}}{{println .}}{{end}}'

    echo ""
    echo "=== Image Size ==="
    docker image inspect "$full_image" --format='Size: {{.Size}} bytes ({{.VirtualSize}} virtual)'
}

# Get image size
# Usage: docker_image_size <image_name> [tag]
docker_image_size() {
    local image_name="${1:?Image name required}"
    local tag="${2:-latest}"
    local full_image="${image_name}:${tag}"

    docker image inspect "$full_image" --format='{{.Size}}' 2>/dev/null || echo "0"
}

# Create Docker network
# Usage: docker_network_create <network_name> [driver]
docker_network_create() {
    local network_name="${1:?Network name required}"
    local driver="${2:-bridge}"

    if docker network inspect "$network_name" &>/dev/null; then
        log_info "Network already exists: $network_name"
        return 0
    fi

    log_info "Creating network: $network_name (driver: $driver)"

    if docker network create --driver "$driver" "$network_name"; then
        log_success "Network created: $network_name"
        return 0
    else
        log_error "Failed to create network: $network_name"
        return 1
    fi
}

# Remove Docker network
# Usage: docker_network_remove <network_name>
docker_network_remove() {
    local network_name="${1:?Network name required}"

    if ! docker network inspect "$network_name" &>/dev/null; then
        log_info "Network does not exist: $network_name"
        return 0
    fi

    log_info "Removing network: $network_name"

    if docker network rm "$network_name"; then
        log_success "Network removed: $network_name"
        return 0
    else
        log_error "Failed to remove network: $network_name"
        return 1
    fi
}

# Create Docker volume
# Usage: docker_volume_create <volume_name> [driver]
docker_volume_create() {
    local volume_name="${1:?Volume name required}"
    local driver="${2:-local}"

    if docker volume inspect "$volume_name" &>/dev/null; then
        log_info "Volume already exists: $volume_name"
        return 0
    fi

    log_info "Creating volume: $volume_name (driver: $driver)"

    if docker volume create --driver "$driver" "$volume_name"; then
        log_success "Volume created: $volume_name"
        return 0
    else
        log_error "Failed to create volume: $volume_name"
        return 1
    fi
}

# Remove Docker volume
# Usage: docker_volume_remove <volume_name>
docker_volume_remove() {
    local volume_name="${1:?Volume name required}"

    if ! docker volume inspect "$volume_name" &>/dev/null; then
        log_info "Volume does not exist: $volume_name"
        return 0
    fi

    log_info "Removing volume: $volume_name"

    if docker volume rm "$volume_name"; then
        log_success "Volume removed: $volume_name"
        return 0
    else
        log_error "Failed to remove volume: $volume_name"
        return 1
    fi
}

# Backup volume to tar archive
# Usage: docker_volume_backup <volume_name> <backup_path>
docker_volume_backup() {
    local volume_name="${1:?Volume name required}"
    local backup_path="${2:?Backup path required}"

    log_info "Backing up volume $volume_name to $backup_path"

    if ! docker volume inspect "$volume_name" &>/dev/null; then
        log_error "Volume does not exist: $volume_name"
        return 1
    fi

    docker run --rm \
        -v "${volume_name}:/source:ro" \
        -v "$(dirname "$backup_path"):/backup" \
        alpine \
        tar -czf "/backup/$(basename "$backup_path")" -C /source .

    if [[ -f "$backup_path" ]]; then
        log_success "Volume backed up to $backup_path"
        return 0
    else
        log_error "Backup failed"
        return 1
    fi
}

# Restore volume from tar archive
# Usage: docker_volume_restore <volume_name> <backup_path>
docker_volume_restore() {
    local volume_name="${1:?Volume name required}"
    local backup_path="${2:?Backup path required}"

    if [[ ! -f "$backup_path" ]]; then
        log_error "Backup file not found: $backup_path"
        return 1
    fi

    log_info "Restoring volume $volume_name from $backup_path"

    # Create volume if it doesn't exist
    docker_volume_create "$volume_name"

    docker run --rm \
        -v "${volume_name}:/target" \
        -v "$(dirname "$backup_path"):/backup:ro" \
        alpine \
        tar -xzf "/backup/$(basename "$backup_path")" -C /target

    log_success "Volume restored from $backup_path"
}

# Execute command in running container
# Usage: docker_exec <container_name> <command...>
docker_exec() {
    local container="${1:?Container name required}"
    shift

    if ! docker_is_running "$container"; then
        log_error "Container is not running: $container"
        return 1
    fi

    docker exec -it "$container" "$@"
}

# Copy files to/from container
# Usage: docker_cp <src> <dest>
# Example: docker_cp mycontainer:/app/logs ./logs
docker_cp() {
    local src="${1:?Source required}"
    local dest="${2:?Destination required}"

    log_info "Copying $src to $dest"

    if docker cp "$src" "$dest"; then
        log_success "Copy complete"
        return 0
    else
        log_error "Copy failed"
        return 1
    fi
}

# Get container stats
# Usage: docker_stats [container_name]
docker_stats() {
    local container="${1:-}"

    if [[ -n "$container" ]]; then
        docker stats "$container" --no-stream
    else
        docker stats --no-stream
    fi
}

# Export library functions
export -f docker_build
export -f docker_build_multistage
export -f docker_push
export -f docker_pull
export -f docker_registry_login
export -f docker_compose_up
export -f docker_compose_down
export -f docker_compose_restart
export -f docker_compose_logs
export -f docker_ps_running
export -f docker_is_running
export -f docker_wait_healthy
export -f docker_cleanup
export -f docker_inspect_layers
export -f docker_image_size
export -f docker_network_create
export -f docker_network_remove
export -f docker_volume_create
export -f docker_volume_remove
export -f docker_volume_backup
export -f docker_volume_restore
export -f docker_exec
export -f docker_cp
export -f docker_stats
