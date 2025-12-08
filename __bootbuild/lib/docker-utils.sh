#!/bin/bash

# ===================================================================
# docker-utils.sh
#
# Docker Utility Functions for Bootstrap System
# Provides Docker detection, resource introspection, and health checks
# Source this in bootstrap scripts that need Docker awareness
# ===================================================================

[[ -n "${_BOOTSTRAP_DOCKER_UTILS_LOADED:-}" ]] && return 0
_BOOTSTRAP_DOCKER_UTILS_LOADED=1

# ===================================================================
# Docker Environment Detection
# ===================================================================

is_in_docker() {
    [[ -f "/.dockerenv" ]] || grep -q docker /proc/self/cgroup 2>/dev/null
}

get_docker_tier() {
    echo "${BOOTSTRAP_TIER:-2}"
}

is_docker_ttty_available() {
    [[ -t 0 ]] || [[ -t 1 ]]
}

get_docker_hostname() {
    if is_in_docker; then
        cat /etc/hostname 2>/dev/null || echo "container"
    else
        hostname
    fi
}

# ===================================================================
# Docker Resource Detection
# ===================================================================

available_cpus() {
    if [[ -f /sys/fs/cgroup/cpuset.cpus_allowed_list ]]; then
        # Count available CPUs from cgroup
        local cpus
        cpus=$(cat /sys/fs/cgroup/cpuset.cpus_allowed_list 2>/dev/null | tr ',' '\n' | wc -l)
        echo "$cpus"
    elif [[ -f /sys/fs/cgroup/cpu.max ]]; then
        # CPU quota from cpu.max
        local quota
        quota=$(cat /sys/fs/cgroup/cpu.max 2>/dev/null | cut -d' ' -f1)
        if [[ "$quota" != "max" ]]; then
            echo $((quota / 100000))
        else
            nproc
        fi
    else
        nproc
    fi
}

available_memory_mb() {
    if [[ -f /sys/fs/cgroup/memory.limit_in_bytes ]]; then
        local bytes
        bytes=$(cat /sys/fs/cgroup/memory.limit_in_bytes 2>/dev/null)
        echo $((bytes / 1024 / 1024))
    elif [[ -f /sys/fs/cgroup/memory.max ]]; then
        local bytes
        bytes=$(cat /sys/fs/cgroup/memory.max 2>/dev/null)
        if [[ "$bytes" != "max" ]]; then
            echo $((bytes / 1024 / 1024))
        else
            free -m 2>/dev/null | awk '/^Mem:/{print $2}' || echo "0"
        fi
    else
        free -m 2>/dev/null | awk '/^Mem:/{print $2}' || echo "0"
    fi
}

# ===================================================================
# Docker-Specific Logging (structured for container logs)
# ===================================================================

log_docker_info() {
    local message="$1"
    if [[ "${BOOTSTRAP_LOG_FORMAT:-text}" == "json" ]]; then
        printf '{"level":"info","timestamp":"%s","message":"%s","tier":"%s"}\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$message" "${BOOTSTRAP_TIER:-2}" >&2
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $message" >&2
    fi
}

log_docker_error() {
    local message="$1"
    if [[ "${BOOTSTRAP_LOG_FORMAT:-text}" == "json" ]]; then
        printf '{"level":"error","timestamp":"%s","message":"%s","tier":"%s"}\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$message" "${BOOTSTRAP_TIER:-2}" >&2
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $message" >&2
    fi
}

log_docker_warning() {
    local message="$1"
    if [[ "${BOOTSTRAP_LOG_FORMAT:-text}" == "json" ]]; then
        printf '{"level":"warning","timestamp":"%s","message":"%s","tier":"%s"}\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$message" "${BOOTSTRAP_TIER:-2}" >&2
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $message" >&2
    fi
}

# ===================================================================
# Bootstrap Phase Control
# ===================================================================

should_run_phase() {
    local phase_num="$1"
    local tier="${BOOTSTRAP_TIER:-2}"

    case "$tier" in
        1)
            # Tier 1 Sandbox: Run all phases
            return 0
            ;;
        2)
            # Tier 2 Development: Phases 1-3 only
            [[ "$phase_num" -le 3 ]] && return 0
            return 1
            ;;
        3)
            # Tier 3 Production: Phase 1 only
            [[ "$phase_num" -eq 1 ]] && return 0
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

phase_name() {
    local phase_num="$1"
    case "$phase_num" in
        1) echo "AI Development Toolkit" ;;
        2) echo "Infrastructure" ;;
        3) echo "Code Quality" ;;
        4) echo "CI/CD & Deployment" ;;
        *) echo "Unknown" ;;
    esac
}

# ===================================================================
# Secrets Management (Docker Secrets)
# ===================================================================

get_docker_secret() {
    local secret_name="$1"
    local default_value="${2:-}"

    if [[ -f "/run/secrets/$secret_name" ]]; then
        cat "/run/secrets/$secret_name"
    elif [[ -n "$default_value" ]]; then
        echo "$default_value"
    else
        return 1
    fi
}

# ===================================================================
# Network Detection
# ===================================================================

get_docker_network_mode() {
    # Check if using host network (for Tier 1)
    if ip link show docker0 &>/dev/null; then
        echo "bridge"
    else
        echo "host"
    fi
}

resolve_service_host() {
    local service_name="$1"
    local default_host="${2:-localhost}"

    if is_in_docker; then
        # In Docker, service names resolve to their containers
        # Docker DNS resolves 'postgres' to the postgres container IP
        echo "$service_name"
    else
        echo "$default_host"
    fi
}

# ===================================================================
# Health Check Utilities
# ===================================================================

wait_for_service() {
    local host="$1"
    local port="$2"
    local service_name="${3:-service}"
    local max_attempts="${4:-30}"
    local attempt=0

    log_docker_info "Waiting for $service_name ($host:$port)..."

    while [[ $attempt -lt $max_attempts ]]; do
        if timeout 2 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
            log_docker_info "✓ $service_name is ready"
            return 0
        fi

        attempt=$((attempt + 1))
        echo "." >&2
        sleep 1
    done

    log_docker_error "✗ Timeout waiting for $service_name"
    return 1
}

# ===================================================================
# Environment Configuration
# ===================================================================

setup_docker_environment() {
    # Called by entrypoint to configure environment for Docker

    if is_in_docker; then
        export BOOTSTRAP_IN_DOCKER="true"
        export BOOTSTRAP_TTY_AVAILABLE="$(is_docker_ttty_available && echo true || echo false)"
        export BOOTSTRAP_NO_COLOR="${BOOTSTRAP_NO_COLOR:-true}"
        export BOOTSTRAP_LOG_FORMAT="${BOOTSTRAP_LOG_FORMAT:-json}"

        # Auto-detect tier from environment or default to 2
        export BOOTSTRAP_TIER="${BOOTSTRAP_TIER:-2}"

        # Set up Docker-specific defaults
        export BOOTSTRAP_INTERACTIVE_MODE="false"
        export BOOTSTRAP_AUTO_YES="true"
        export BOOTSTRAP_SKIP_PREFLIGHT="true"
    fi
}

# ===================================================================
# Container Information Display
# ===================================================================

show_docker_info() {
    if is_in_docker; then
        log_docker_info "Running inside Docker"
        log_docker_info "Tier: $(get_docker_tier)"
        log_docker_info "Hostname: $(get_docker_hostname)"
        log_docker_info "Available CPUs: $(available_cpus)"
        log_docker_info "Available Memory: $(available_memory_mb)MB"
    fi
}
