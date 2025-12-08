#!/bin/bash

# ===================================================================
# rust-utils.sh
#
# Rust cargo and build helpers
# Source this file to use cargo-related utilities:
#   source "$(dirname "$0")/../lib/rust-utils.sh"
#
# Provides:
#   - cargo_build() - Build project
#   - cargo_build_release() - Release build
#   - cargo_test() - Run tests
#   - cargo_clippy() - Run clippy linter
#   - cargo_fmt() - Format code
#   - cargo_doc() - Generate documentation
#   - cargo_cross_compile() - Cross-compile
#   - cargo_clean() - Clean build artifacts
#   - cargo_audit() - Security audit
#   - cargo_update() - Update dependencies
# ===================================================================

# Prevent double-sourcing
[[ -n "${_BOOTSTRAP_RUST_UTILS_LOADED:-}" ]] && return 0
_BOOTSTRAP_RUST_UTILS_LOADED=1

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# ===================================================================
# Configuration
# ===================================================================

# Default Rust/Cargo paths
CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"

# ===================================================================
# Validation
# ===================================================================

# Check if cargo is installed
require_cargo() {
    if ! command -v cargo &> /dev/null; then
        log_error "cargo not found. Install Rust from https://rustup.rs"
        return 1
    fi
    log_debug "cargo found: $(cargo --version)"
    return 0
}

# Check if rustup is installed
require_rustup() {
    if ! command -v rustup &> /dev/null; then
        log_error "rustup not found. Install from https://rustup.rs"
        return 1
    fi
    log_debug "rustup found: $(rustup --version)"
    return 0
}

# Check if we're in a Cargo project
is_cargo_project() {
    if [[ ! -f "Cargo.toml" ]]; then
        log_error "No Cargo.toml found in current directory"
        return 1
    fi
    return 0
}

# ===================================================================
# Build Functions
# ===================================================================

# Build Rust project in debug mode
# Usage: cargo_build [OPTIONS]
# Options:
#   --verbose    - Show verbose output
#   --features   - Comma-separated list of features
#   --all-features - Build with all features
cargo_build() {
    require_cargo || return 1
    is_cargo_project || return 1

    log_info "Building Rust project (debug mode)..."

    local verbose=""
    local features=""
    local all_features=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose)
                verbose="--verbose"
                shift
                ;;
            --features)
                features="--features $2"
                shift 2
                ;;
            --all-features)
                all_features="--all-features"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    if cargo build $verbose $features $all_features; then
        log_success "Build completed successfully"
        return 0
    else
        log_error "Build failed"
        return 1
    fi
}

# Build Rust project in release mode
# Usage: cargo_build_release [OPTIONS]
# Options: Same as cargo_build
cargo_build_release() {
    require_cargo || return 1
    is_cargo_project || return 1

    log_info "Building Rust project (release mode)..."

    local verbose=""
    local features=""
    local all_features=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose)
                verbose="--verbose"
                shift
                ;;
            --features)
                features="--features $2"
                shift 2
                ;;
            --all-features)
                all_features="--all-features"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    if cargo build --release $verbose $features $all_features; then
        log_success "Release build completed successfully"

        # Show binary location
        if [[ -d "target/release" ]]; then
            local binaries=$(find target/release -maxdepth 1 -type f -executable ! -name "*.so" ! -name "*.d" 2>/dev/null)
            if [[ -n "$binaries" ]]; then
                log_info "Binaries created:"
                echo "$binaries" | while read -r binary; do
                    echo "  → $(basename "$binary") ($(du -h "$binary" | cut -f1))"
                done
            fi
        fi
        return 0
    else
        log_error "Release build failed"
        return 1
    fi
}

# ===================================================================
# Testing Functions
# ===================================================================

# Run Rust tests
# Usage: cargo_test [OPTIONS] [TEST_NAME]
# Options:
#   --verbose       - Show verbose output
#   --release       - Test release build
#   --doc           - Test documentation examples
#   --no-fail-fast  - Don't stop on first failure
cargo_test() {
    require_cargo || return 1
    is_cargo_project || return 1

    log_info "Running Rust tests..."

    local verbose=""
    local release=""
    local doc=""
    local no_fail_fast=""
    local test_name=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose)
                verbose="--verbose"
                shift
                ;;
            --release)
                release="--release"
                shift
                ;;
            --doc)
                doc="--doc"
                shift
                ;;
            --no-fail-fast)
                no_fail_fast="--no-fail-fast"
                shift
                ;;
            *)
                test_name="$1"
                shift
                ;;
        esac
    done

    if cargo test $verbose $release $doc $no_fail_fast $test_name; then
        log_success "All tests passed"
        return 0
    else
        log_error "Tests failed"
        return 1
    fi
}

# ===================================================================
# Code Quality Functions
# ===================================================================

# Run clippy linter
# Usage: cargo_clippy [OPTIONS]
# Options:
#   --fix       - Automatically fix warnings
#   --pedantic  - Enable pedantic lints
#   --deny      - Treat warnings as errors
cargo_clippy() {
    require_cargo || return 1
    is_cargo_project || return 1

    # Check if clippy is installed
    if ! rustup component list | grep -q "clippy.*installed"; then
        log_warning "clippy not installed, installing..."
        rustup component add clippy || return 1
    fi

    log_info "Running clippy linter..."

    local fix=""
    local pedantic=""
    local deny=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --fix)
                fix="--fix"
                shift
                ;;
            --pedantic)
                pedantic="-W clippy::pedantic"
                shift
                ;;
            --deny)
                deny="-D warnings"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    if cargo clippy $fix -- $pedantic $deny; then
        log_success "Clippy checks passed"
        return 0
    else
        log_error "Clippy found issues"
        return 1
    fi
}

# Format Rust code
# Usage: cargo_fmt [OPTIONS]
# Options:
#   --check  - Check formatting without modifying files
cargo_fmt() {
    require_cargo || return 1
    is_cargo_project || return 1

    # Check if rustfmt is installed
    if ! rustup component list | grep -q "rustfmt.*installed"; then
        log_warning "rustfmt not installed, installing..."
        rustup component add rustfmt || return 1
    fi

    log_info "Formatting Rust code..."

    local check=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --check)
                check="--check"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    if cargo fmt --all $check; then
        if [[ -n "$check" ]]; then
            log_success "Code is properly formatted"
        else
            log_success "Code formatted successfully"
        fi
        return 0
    else
        log_error "Formatting check failed"
        return 1
    fi
}

# ===================================================================
# Documentation Functions
# ===================================================================

# Generate documentation
# Usage: cargo_doc [OPTIONS]
# Options:
#   --open          - Open docs in browser after generating
#   --no-deps       - Don't document dependencies
#   --document-private-items - Document private items
cargo_doc() {
    require_cargo || return 1
    is_cargo_project || return 1

    log_info "Generating documentation..."

    local open=""
    local no_deps=""
    local private=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --open)
                open="--open"
                shift
                ;;
            --no-deps)
                no_deps="--no-deps"
                shift
                ;;
            --document-private-items)
                private="--document-private-items"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    if cargo doc $no_deps $private $open; then
        log_success "Documentation generated successfully"
        if [[ -z "$open" ]]; then
            log_info "View docs at: target/doc/index.html"
        fi
        return 0
    else
        log_error "Documentation generation failed"
        return 1
    fi
}

# ===================================================================
# Cross-Compilation Functions
# ===================================================================

# Cross-compile for target platform
# Usage: cargo_cross_compile TARGET [OPTIONS]
# Example: cargo_cross_compile x86_64-unknown-linux-musl --release
cargo_cross_compile() {
    require_cargo || return 1
    is_cargo_project || return 1

    if [[ -z "$1" ]]; then
        log_error "Usage: cargo_cross_compile TARGET [OPTIONS]"
        log_info "Common targets:"
        log_info "  x86_64-unknown-linux-gnu"
        log_info "  x86_64-unknown-linux-musl"
        log_info "  x86_64-pc-windows-gnu"
        log_info "  x86_64-apple-darwin"
        log_info "  aarch64-unknown-linux-gnu"
        return 1
    fi

    local target="$1"
    shift

    log_info "Cross-compiling for target: $target"

    # Check if target is installed
    if ! rustup target list | grep -q "$target (installed)"; then
        log_warning "Target $target not installed, installing..."
        rustup target add "$target" || return 1
    fi

    if cargo build --target "$target" "$@"; then
        log_success "Cross-compilation successful"
        log_info "Binary location: target/$target/debug/ or target/$target/release/"
        return 0
    else
        log_error "Cross-compilation failed"
        return 1
    fi
}

# ===================================================================
# Maintenance Functions
# ===================================================================

# Clean build artifacts
# Usage: cargo_clean [OPTIONS]
# Options:
#   --release   - Clean only release artifacts
#   --doc       - Clean documentation
cargo_clean() {
    require_cargo || return 1
    is_cargo_project || return 1

    log_info "Cleaning build artifacts..."

    local release=""
    local doc=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --release)
                release="--release"
                shift
                ;;
            --doc)
                doc="--doc"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    # Show size before cleaning
    if [[ -d "target" ]]; then
        local size=$(du -sh target 2>/dev/null | cut -f1)
        log_debug "Current target/ size: $size"
    fi

    if cargo clean $release $doc; then
        log_success "Build artifacts cleaned"
        return 0
    else
        log_error "Clean failed"
        return 1
    fi
}

# Security audit dependencies
# Usage: cargo_audit [OPTIONS]
# Options:
#   --json  - Output in JSON format
cargo_audit() {
    require_cargo || return 1
    is_cargo_project || return 1

    # Check if cargo-audit is installed
    if ! cargo install --list | grep -q "cargo-audit"; then
        log_warning "cargo-audit not installed, installing..."
        cargo install cargo-audit || return 1
    fi

    log_info "Running security audit..."

    local json=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                json="--json"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    if cargo audit $json; then
        log_success "No security vulnerabilities found"
        return 0
    else
        log_warning "Security vulnerabilities detected - review output above"
        return 1
    fi
}

# Update dependencies
# Usage: cargo_update [OPTIONS]
# Options:
#   --dry-run   - Show what would be updated
#   --aggressive - Update to latest versions (not just compatible)
cargo_update() {
    require_cargo || return 1
    is_cargo_project || return 1

    log_info "Updating dependencies..."

    local dry_run=""
    local aggressive=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run="--dry-run"
                shift
                ;;
            --aggressive)
                aggressive="--aggressive"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    # Backup Cargo.lock if it exists
    if [[ -f "Cargo.lock" ]]; then
        backup_file "Cargo.lock"
    fi

    if [[ -n "$aggressive" ]]; then
        # For aggressive updates, use cargo-edit if available
        if cargo install --list | grep -q "cargo-edit"; then
            if cargo upgrade $dry_run; then
                log_success "Dependencies updated to latest versions"
                return 0
            fi
        else
            log_warning "cargo-edit not installed. Install with: cargo install cargo-edit"
            log_info "Falling back to standard update..."
        fi
    fi

    if cargo update $dry_run; then
        if [[ -n "$dry_run" ]]; then
            log_success "Dry run complete - no changes made"
        else
            log_success "Dependencies updated successfully"
        fi
        return 0
    else
        log_error "Update failed"
        return 1
    fi
}

# ===================================================================
# Utility Functions
# ===================================================================

# Show Rust toolchain info
rust_info() {
    require_cargo || return 1

    log_section "Rust Toolchain Information"

    echo "Rust version:"
    rustc --version
    echo ""

    echo "Cargo version:"
    cargo --version
    echo ""

    if command -v rustup &> /dev/null; then
        echo "Installed toolchains:"
        rustup toolchain list
        echo ""

        echo "Installed targets:"
        rustup target list --installed
        echo ""

        echo "Installed components:"
        rustup component list --installed
    fi
}

# Run full quality check (fmt, clippy, test)
cargo_check_all() {
    require_cargo || return 1
    is_cargo_project || return 1

    log_section "Running Full Quality Check"

    local failed=0

    log_info "Step 1/3: Format check..."
    if ! cargo_fmt --check; then
        failed=1
        log_error "Format check failed"
    fi

    log_info "Step 2/3: Clippy check..."
    if ! cargo_clippy; then
        failed=1
        log_error "Clippy check failed"
    fi

    log_info "Step 3/3: Running tests..."
    if ! cargo_test; then
        failed=1
        log_error "Tests failed"
    fi

    if [[ $failed -eq 0 ]]; then
        log_success "All quality checks passed"
        return 0
    else
        log_error "Some quality checks failed"
        return 1
    fi
}

# Export functions
export -f require_cargo
export -f require_rustup
export -f is_cargo_project
export -f cargo_build
export -f cargo_build_release
export -f cargo_test
export -f cargo_clippy
export -f cargo_fmt
export -f cargo_doc
export -f cargo_cross_compile
export -f cargo_clean
export -f cargo_audit
export -f cargo_update
export -f rust_info
export -f cargo_check_all
