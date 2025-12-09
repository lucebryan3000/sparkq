#!/bin/bash

# ===================================================================
# lib/dependency-checker.sh
#
# Mandatory dependency validation with auto-install prompting
# Used by all bootstrap scripts before execution
# ===================================================================

# Global tracking of missing dependencies
declare -a _MISSING_TOOLS=()
declare -a _MISSING_SCRIPTS=()
declare -a _VERSION_FAILURES=()
declare -a _REQUIRED_TOOLS=()
declare -a _REQUIRED_SCRIPTS=()
declare -a _OPTIONAL_TOOLS=()

# Configuration
DEPENDENCY_CHECK_TIMEOUT=${DEPENDENCY_CHECK_TIMEOUT:-10}  # seconds
AUTO_INSTALL_TIMEOUT=${AUTO_INSTALL_TIMEOUT:-300}  # 5 minutes

# ===================================================================
# Safe Command Execution
# ===================================================================

# Execute command with timeout
# Usage: run_with_timeout 10 "command args"
run_with_timeout() {
    local timeout="$1"
    shift
    local cmd="$@"

    # Validate timeout is a number
    if ! [[ "$timeout" =~ ^[0-9]+$ ]]; then
        echo "ERROR: [DependencyChecker] Invalid timeout: $timeout" >&2
        return 1
    fi

    # Run command with timeout
    timeout "$timeout" bash -c "$cmd" 2>&1
}

# Validate URL is safe (basic validation)
# Usage: validate_url "https://example.com/file.sh"
validate_url() {
    local url="$1"

    # Check for valid https:// or http:// prefix
    if [[ ! "$url" =~ ^https?:// ]]; then
        echo "ERROR: [DependencyChecker] Invalid URL protocol: $url" >&2
        return 1
    fi

    # Check for suspicious patterns (escape properly for regex)
    if [[ "$url" =~ [\;\|\&\$\`] ]]; then
        echo "ERROR: [DependencyChecker] Suspicious characters in URL: $url" >&2
        return 1
    fi

    return 0
}

# ===================================================================
# Core Dependency Functions
# ===================================================================

# Check if a command exists and optionally validate version
# Usage: check_dependency "node" "18.0.0" "min"
check_dependency() {
    local tool="$1"
    local required_version="${2:-}"
    local comparison="${3:-min}"  # min, max, exact

    if ! command -v "$tool" &> /dev/null; then
        _MISSING_TOOLS+=("$tool")
        return 1
    fi

    # Version check if specified (with timeout to prevent hanging)
    if [[ -n "$required_version" ]]; then
        local current_version=""

        # Run version check with timeout
        case "$tool" in
            node)
                current_version=$(timeout $DEPENDENCY_CHECK_TIMEOUT node --version 2>/dev/null | sed 's/v//' || echo "")
                ;;
            python3)
                current_version=$(timeout $DEPENDENCY_CHECK_TIMEOUT python3 --version 2>/dev/null | awk '{print $2}' || echo "")
                ;;
            docker)
                current_version=$(timeout $DEPENDENCY_CHECK_TIMEOUT docker --version 2>/dev/null | awk '{print $3}' | sed 's/,//' || echo "")
                ;;
            git)
                current_version=$(timeout $DEPENDENCY_CHECK_TIMEOUT git --version 2>/dev/null | awk '{print $3}' || echo "")
                ;;
            kubectl)
                current_version=$(timeout $DEPENDENCY_CHECK_TIMEOUT kubectl version --client -o json 2>/dev/null | grep -o '"gitVersion":"v[^"]*' | cut -d'v' -f2 || echo "")
                ;;
            helm)
                current_version=$(timeout $DEPENDENCY_CHECK_TIMEOUT helm version --short 2>/dev/null | grep -o 'v[0-9.]*' | sed 's/v//' || echo "")
                ;;
            *)
                current_version=""
                ;;
        esac

        # Check if version detection timed out
        if [[ $? -eq 124 ]]; then
            echo "WARNING: [DependencyChecker] Version check timed out for $tool" >&2
            current_version=""
        fi

        if [[ -n "$current_version" ]]; then
            if ! version_satisfies "$current_version" "$required_version" "$comparison"; then
                _VERSION_FAILURES+=("$tool: need $comparison $required_version, have $current_version")
                return 1
            fi
        fi
    fi

    return 0
}

# Check if a bootstrap script has run (by checking its tracking)
# Usage: check_script_dependency "bootstrap-git"
check_script_dependency() {
    local script_name="$1"
    local marker_file="${BOOTSTRAP_DIR}/logs/.${script_name}.completed"

    if [[ ! -f "$marker_file" ]]; then
        _MISSING_SCRIPTS+=("$script_name")
        return 1
    fi

    return 0
}

# Compare semantic versions
# Returns 0 if version satisfies requirement, 1 otherwise
version_satisfies() {
    local current="$1"
    local required="$2"
    local comparison="$3"

    # Simple version comparison using sort -V
    case "$comparison" in
        min)
            # Current must be >= required
            [[ "$(printf '%s\n' "$required" "$current" | sort -V | head -1)" == "$required" ]]
            ;;
        max)
            # Current must be <= required
            [[ "$(printf '%s\n' "$required" "$current" | sort -V | tail -1)" == "$required" ]]
            ;;
        exact)
            # Current must equal required
            [[ "$current" == "$required" ]]
            ;;
        *)
            # Unknown comparison, fail safe
            return 1
            ;;
    esac
}

# ===================================================================
# Dependency Declaration & Validation
# ===================================================================

# Declare all dependencies upfront (called at start of script)
# Usage: declare_dependencies \
#          --tools "node:18.0.0:min docker git" \
#          --scripts "bootstrap-git bootstrap-environment" \
#          --optional "redis postgresql"
declare_dependencies() {
    local tools=""
    local scripts=""
    local optional=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tools) tools="$2"; shift 2 ;;
            --scripts) scripts="$2"; shift 2 ;;
            --optional) optional="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    # Reset tracking arrays
    _MISSING_TOOLS=()
    _MISSING_SCRIPTS=()
    _VERSION_FAILURES=()
    _REQUIRED_TOOLS=()
    _REQUIRED_SCRIPTS=()
    _OPTIONAL_TOOLS=()

    # Check tool dependencies in parallel
    if [[ -n "$tools" ]]; then
        # Create temporary directory for parallel results
        local tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t 'dep-check')
        local pids=()
        local tool_idx=0

        for tool_spec in $tools; do
            IFS=':' read -r tool version comparison <<< "$tool_spec"
            _REQUIRED_TOOLS+=("$tool")

            # Launch parallel check in background
            (
                local result_file="${tmpdir}/tool_${tool_idx}.result"

                # Check if command exists
                if ! command -v "$tool" &> /dev/null; then
                    echo "MISSING:$tool" > "$result_file"
                    exit 1
                fi

                # Version check if specified
                if [[ -n "$version" ]]; then
                    local current_version
                    case "$tool" in
                        node) current_version=$(node --version 2>/dev/null | sed 's/v//') ;;
                        python3) current_version=$(python3 --version 2>/dev/null | awk '{print $2}') ;;
                        docker) current_version=$(docker --version 2>/dev/null | awk '{print $3}' | sed 's/,//') ;;
                        git) current_version=$(git --version 2>/dev/null | awk '{print $3}') ;;
                        kubectl) current_version=$(kubectl version --client -o json 2>/dev/null | grep -o '"gitVersion":"v[^"]*' | cut -d'v' -f2) ;;
                        helm) current_version=$(helm version --short 2>/dev/null | grep -o 'v[0-9.]*' | sed 's/v//') ;;
                        *) current_version="" ;;
                    esac

                    if [[ -n "$current_version" ]]; then
                        # Simple version comparison
                        local comp="${comparison:-min}"
                        case "$comp" in
                            min)
                                if [[ "$(printf '%s\n' "$version" "$current_version" | sort -V | head -1)" != "$version" ]]; then
                                    echo "VERSION:$tool:need $comp $version, have $current_version" > "$result_file"
                                    exit 1
                                fi
                                ;;
                        esac
                    fi
                fi

                echo "OK:$tool" > "$result_file"
            ) &
            pids+=($!)
            ((tool_idx++))
        done

        # Wait for all parallel checks to complete
        for pid in "${pids[@]}"; do
            wait "$pid" 2>/dev/null || true
        done

        # Collect results from temp files
        for result_file in "$tmpdir"/tool_*.result; do
            [[ -f "$result_file" ]] || continue
            local result=$(cat "$result_file")
            local status="${result%%:*}"
            local rest="${result#*:}"

            case "$status" in
                MISSING)
                    _MISSING_TOOLS+=("$rest")
                    ;;
                VERSION)
                    local tool="${rest%%:*}"
                    local msg="${rest#*:}"
                    _VERSION_FAILURES+=("$tool: $msg")
                    ;;
                OK)
                    # Tool is OK
                    ;;
            esac
        done

        # Cleanup
        rm -rf "$tmpdir" 2>/dev/null || true
    fi

    # Check script dependencies (sequential - they may have order dependencies)
    if [[ -n "$scripts" ]]; then
        for script in $scripts; do
            _REQUIRED_SCRIPTS+=("$script")
            check_script_dependency "$script"
        done
    fi

    # Track optional tools (warnings only)
    if [[ -n "$optional" ]]; then
        for tool in $optional; do
            _OPTIONAL_TOOLS+=("$tool")
        done
    fi

    # Validate dependencies
    validate_dependencies || return 1
}

# ===================================================================
# Validation & Error Reporting
# ===================================================================

# Validate all dependencies and report failures
validate_dependencies() {
    local has_errors=0

    # Report missing tools
    if [[ ${#_MISSING_TOOLS[@]} -gt 0 ]]; then
        has_errors=1
        echo ""
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "DEPENDENCY ERROR: Missing Required Tools"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        for tool in "${_MISSING_TOOLS[@]}"; do
            log_error "  ✗ $tool (not installed)"
            suggest_install "$tool"
        done
        echo ""
    fi

    # Report version failures
    if [[ ${#_VERSION_FAILURES[@]} -gt 0 ]]; then
        has_errors=1
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "DEPENDENCY ERROR: Version Requirements Not Met"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        for failure in "${_VERSION_FAILURES[@]}"; do
            log_error "  ✗ $failure"
        done
        echo ""
    fi

    # Report missing script dependencies
    if [[ ${#_MISSING_SCRIPTS[@]} -gt 0 ]]; then
        has_errors=1
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "DEPENDENCY ERROR: Required Bootstrap Scripts Not Run"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        log_error "The following bootstrap scripts must run first:"
        echo ""
        for script in "${_MISSING_SCRIPTS[@]}"; do
            log_error "  ✗ ${script}.sh"
        done
        echo ""
        log_info "Run missing scripts in order:"
        echo ""
        for script in "${_MISSING_SCRIPTS[@]}"; do
            echo "  bash __bootbuild/scripts/${script}.sh"
        done
        echo ""
    fi

    # If errors, offer to auto-install or abort
    if [[ $has_errors -eq 1 ]]; then
        if [[ ${#_MISSING_TOOLS[@]} -gt 0 ]]; then
            prompt_auto_install || return 1
        else
            log_fatal "Dependency validation failed. Please resolve issues above."
        fi
    fi

    # Check optional tools (warnings only)
    check_optional_tools

    return 0
}

# Check optional tools and warn if missing
check_optional_tools() {
    local missing_optional=()

    for tool in "${_OPTIONAL_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_optional+=("$tool")
        fi
    done

    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        echo ""
        log_warning "Optional tools not installed (script will work without them):"
        for tool in "${missing_optional[@]}"; do
            echo "  ⚠ $tool"
        done
        echo ""
    fi
}

# ===================================================================
# Auto-Install Prompting
# ===================================================================

# Prompt user to auto-install missing tools
prompt_auto_install() {
    echo ""
    log_warning "Some dependencies are missing."
    echo ""

    # Show installable tools
    local installable=()
    for tool in "${_MISSING_TOOLS[@]}"; do
        if can_auto_install "$tool"; then
            installable+=("$tool")
        fi
    done

    if [[ ${#installable[@]} -eq 0 ]]; then
        log_error "No tools can be auto-installed. Please install manually using instructions above."
        return 1
    fi

    # Prompt for installation
    echo "The following tools can be installed automatically:"
    for tool in "${installable[@]}"; do
        echo "  • $tool"
    done
    echo ""

    local response
    read -p "Install missing dependencies now? [Y/n]: " response
    response=${response:-Y}

    if [[ "$response" =~ ^[Yy] ]]; then
        for tool in "${installable[@]}"; do
            auto_install_tool "$tool"
        done

        # Re-validate after installation
        _MISSING_TOOLS=()
        for tool in "${installable[@]}"; do
            check_dependency "$tool"
        done

        if [[ ${#_MISSING_TOOLS[@]} -gt 0 ]]; then
            log_error "Installation failed for: ${_MISSING_TOOLS[*]}"
            return 1
        fi

        log_success "All dependencies installed successfully!"
        return 0
    else
        log_error "Cannot proceed without required dependencies."
        return 1
    fi
}

# Check if tool can be auto-installed
can_auto_install() {
    local tool="$1"

    case "$tool" in
        node|npm|pnpm|yarn) return 0 ;;  # Via nvm/fnm
        docker) return 0 ;;               # Via apt/brew
        python3|pip3) return 0 ;;         # Via apt/brew
        git) return 0 ;;                  # Via apt/brew
        jq|curl) return 0 ;;              # Via apt/brew
        *) return 1 ;;                    # Unknown
    esac
}

# Auto-install a tool (sandboxed - only whitelisted tools allowed)
auto_install_tool() {
    local tool="$1"

    # Validate tool is in whitelist
    if ! can_auto_install "$tool"; then
        echo "ERROR: [DependencyChecker] Tool not in auto-install whitelist: $tool" >&2
        return 1
    fi

    log_info "Installing $tool (timeout: ${AUTO_INSTALL_TIMEOUT}s)..."

    case "$tool" in
        node|npm)
            # Try nvm first, fall back to package manager
            if command -v nvm &> /dev/null; then
                timeout $AUTO_INSTALL_TIMEOUT nvm install --lts || {
                    log_error "nvm install timed out or failed"
                    return 1
                }
            elif [[ -f "$HOME/.nvm/nvm.sh" ]]; then
                source "$HOME/.nvm/nvm.sh"
                timeout $AUTO_INSTALL_TIMEOUT nvm install --lts || {
                    log_error "nvm install timed out or failed"
                    return 1
                }
            else
                install_via_package_manager "nodejs npm"
            fi
            ;;
        pnpm)
            if command -v npm &> /dev/null; then
                timeout $AUTO_INSTALL_TIMEOUT npm install -g pnpm || {
                    log_error "npm install pnpm timed out or failed"
                    return 1
                }
            else
                log_error "npm required to install pnpm"
                return 1
            fi
            ;;
        yarn)
            if command -v npm &> /dev/null; then
                timeout $AUTO_INSTALL_TIMEOUT npm install -g yarn || {
                    log_error "npm install yarn timed out or failed"
                    return 1
                }
            else
                install_via_package_manager "yarn"
            fi
            ;;
        docker)
            install_via_package_manager "docker.io docker-compose"
            # Add user to docker group if not already
            if ! groups | grep -q docker; then
                sudo usermod -aG docker "$USER"
                log_warning "Added $USER to docker group. You may need to log out and back in."
            fi
            ;;
        python3|pip3)
            install_via_package_manager "python3 python3-pip"
            ;;
        git)
            install_via_package_manager "git"
            ;;
        jq)
            install_via_package_manager "jq"
            ;;
        curl)
            install_via_package_manager "curl"
            ;;
        *)
            log_warning "Don't know how to auto-install $tool"
            return 1
            ;;
    esac
}

# Install via system package manager (with input sanitization and timeout)
install_via_package_manager() {
    local packages="$1"

    # Validate packages string doesn't contain dangerous characters (escape properly for regex)
    if [[ "$packages" =~ [\;\|\&\$\`\<\>] ]]; then
        echo "ERROR: [DependencyChecker] Invalid characters in package names: $packages" >&2
        return 1
    fi

    # Validate packages are alphanumeric with common package name characters
    # Note: Dash must be at end of character class or escaped
    local package_pattern='^[a-zA-Z0-9._][a-zA-Z0-9._ ]*[a-zA-Z0-9._]$|^[a-zA-Z0-9._]$'
    if [[ ! "$packages" =~ $package_pattern ]]; then
        echo "ERROR: [DependencyChecker] Invalid package name format: $packages" >&2
        return 1
    fi

    log_info "Installing packages via package manager: $packages"

    if command -v apt-get &> /dev/null; then
        timeout $AUTO_INSTALL_TIMEOUT sudo apt-get update && \
        timeout $AUTO_INSTALL_TIMEOUT sudo apt-get install -y $packages
    elif command -v brew &> /dev/null; then
        timeout $AUTO_INSTALL_TIMEOUT brew install $packages
    elif command -v dnf &> /dev/null; then
        timeout $AUTO_INSTALL_TIMEOUT sudo dnf install -y $packages
    elif command -v yum &> /dev/null; then
        timeout $AUTO_INSTALL_TIMEOUT sudo yum install -y $packages
    else
        log_error "No supported package manager found (apt, brew, dnf, yum)"
        return 1
    fi

    local exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
        log_error "Package installation timed out after ${AUTO_INSTALL_TIMEOUT}s"
        return 1
    fi

    return $exit_code
}

# ===================================================================
# Installation Suggestions
# ===================================================================

# Suggest how to install a missing tool
suggest_install() {
    local tool="$1"

    case "$tool" in
        node|npm)
            echo "    Install: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
            echo "             nvm install --lts"
            echo "    Or:      https://nodejs.org/"
            ;;
        docker)
            echo "    Install: https://docs.docker.com/get-docker/"
            echo "    Linux:   sudo apt-get install docker.io docker-compose"
            ;;
        python3|pip3)
            echo "    Install: sudo apt-get install python3 python3-pip  # Ubuntu/Debian"
            echo "             brew install python3                      # macOS"
            ;;
        git)
            echo "    Install: sudo apt-get install git  # Ubuntu/Debian"
            echo "             brew install git          # macOS"
            ;;
        kubectl)
            echo "    Install: https://kubernetes.io/docs/tasks/tools/"
            ;;
        helm)
            echo "    Install: https://helm.sh/docs/intro/install/"
            ;;
        jq)
            echo "    Install: sudo apt-get install jq  # Ubuntu/Debian"
            echo "             brew install jq           # macOS"
            ;;
        pnpm)
            echo "    Install: npm install -g pnpm"
            ;;
        yarn)
            echo "    Install: npm install -g yarn"
            ;;
        postgresql|psql)
            echo "    Install: sudo apt-get install postgresql-client"
            ;;
        mysql)
            echo "    Install: sudo apt-get install mysql-client"
            ;;
        redis-cli)
            echo "    Install: sudo apt-get install redis-tools"
            ;;
        *)
            echo "    Search: https://command-not-found.com/$tool"
            ;;
    esac
}

# ===================================================================
# Manifest-Based Dependency Declaration
# ===================================================================

# Get tool info from manifest
# Usage: _get_tool_info "node" "min_version"
_get_tool_info() {
    local tool="$1"
    local field="$2"

    if [[ -n "${MANIFEST_FILE:-}" && -f "$MANIFEST_FILE" ]]; then
        jq -r ".tools.\"$tool\".\"$field\" // empty" "$MANIFEST_FILE" 2>/dev/null
    fi
}

# Check dependency using manifest tool definitions
# Usage: check_manifest_dependency "node"
check_manifest_dependency() {
    local tool="$1"

    # Get tool info from manifest
    local command=$(_get_tool_info "$tool" "command")
    local min_version=$(_get_tool_info "$tool" "min_version")
    local detect_cmd=$(_get_tool_info "$tool" "detect_version")

    # Use tool name as command if not specified
    [[ -z "$command" ]] && command="$tool"

    # Check if command exists
    if ! command -v "$command" &> /dev/null; then
        _MISSING_TOOLS+=("$tool")
        return 1
    fi

    # Version check if min_version and detect command specified
    if [[ -n "$min_version" && -n "$detect_cmd" ]]; then
        local current_version=$(eval "$detect_cmd" 2>/dev/null || echo "0.0.0")

        if [[ -n "$current_version" && "$current_version" != "0.0.0" ]]; then
            if ! version_satisfies "$current_version" "$min_version" "min"; then
                _VERSION_FAILURES+=("$tool: need >= $min_version, have $current_version")
                return 1
            fi
        fi
    fi

    return 0
}

# Declare dependencies for a script by reading from manifest
# Usage: declare_manifest_dependencies "packages"
declare_manifest_dependencies() {
    local script_key="$1"

    # Reset tracking arrays
    _MISSING_TOOLS=()
    _MISSING_SCRIPTS=()
    _VERSION_FAILURES=()
    _REQUIRED_TOOLS=()
    _REQUIRED_SCRIPTS=()
    _OPTIONAL_TOOLS=()

    if [[ -z "${MANIFEST_FILE:-}" || ! -f "$MANIFEST_FILE" ]]; then
        log_warning "Manifest file not found, skipping dependency check"
        return 0
    fi

    # Get required tools from manifest
    local required_tools=$(jq -r ".scripts.\"$script_key\".requires.tools // [] | .[]" "$MANIFEST_FILE" 2>/dev/null)
    for tool in $required_tools; do
        _REQUIRED_TOOLS+=("$tool")
        check_manifest_dependency "$tool"
    done

    # Get optional tools from manifest
    local optional_tools=$(jq -r ".scripts.\"$script_key\".requires.optional // [] | .[]" "$MANIFEST_FILE" 2>/dev/null)
    for tool in $optional_tools; do
        _OPTIONAL_TOOLS+=("$tool")
    done

    # Get script dependencies from manifest
    local depends=$(jq -r ".scripts.\"$script_key\".depends // [] | .[]" "$MANIFEST_FILE" 2>/dev/null)
    for script in $depends; do
        _REQUIRED_SCRIPTS+=("$script")
        check_script_dependency "bootstrap-$script"
    done

    # Validate dependencies
    validate_dependencies || return 1
}

# Updated suggest_install to use manifest hints
suggest_install_from_manifest() {
    local tool="$1"

    local hint=$(_get_tool_info "$tool" "install_hint")
    if [[ -n "$hint" ]]; then
        echo "    Install: $hint"
    else
        suggest_install "$tool"
    fi
}

# ===================================================================
# Utility Functions
# ===================================================================

# Get list of satisfied dependencies for display
get_satisfied_dependencies() {
    echo "${_REQUIRED_TOOLS[@]}"
}

# Get list of satisfied script dependencies for display
get_satisfied_script_dependencies() {
    echo "${_REQUIRED_SCRIPTS[@]}"
}

# Export functions for use in bootstrap scripts
export -f check_dependency
export -f check_script_dependency
export -f declare_dependencies
export -f declare_manifest_dependencies
export -f check_manifest_dependency
export -f validate_dependencies
export -f version_satisfies
export -f get_satisfied_dependencies
export -f get_satisfied_script_dependencies
export -f suggest_install_from_manifest
