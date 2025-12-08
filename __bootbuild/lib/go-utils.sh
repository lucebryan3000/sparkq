#!/usr/bin/env bash
# go-utils.sh - Go build and deployment helpers
# Part of bootbuild framework

set -euo pipefail

# Initialize go.mod with module path
go_mod_init() {
    local module_path="${1:-}"

    if [[ -z "$module_path" ]]; then
        echo "Error: Module path required" >&2
        echo "Usage: go_mod_init <module_path>" >&2
        return 1
    fi

    if [[ -f "go.mod" ]]; then
        echo "Warning: go.mod already exists" >&2
        return 0
    fi

    echo "Initializing Go module: $module_path"
    go mod init "$module_path"
}

# Tidy dependencies and verify
go_mod_tidy() {
    local verify="${1:-false}"

    echo "Tidying Go dependencies..."
    go mod tidy

    if [[ "$verify" == "true" ]]; then
        echo "Verifying dependencies..."
        go mod verify
    fi

    echo "Downloading dependencies..."
    go mod download
}

# Build binary with versioning
go_build() {
    local output="${1:-}"
    local version="${2:-dev}"
    local commit="${3:-$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')}"
    local date="${4:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"

    if [[ -z "$output" ]]; then
        output="./bin/$(basename "$(pwd)")"
    fi

    local ldflags="-s -w"
    ldflags="$ldflags -X main.version=$version"
    ldflags="$ldflags -X main.commit=$commit"
    ldflags="$ldflags -X main.buildDate=$date"

    echo "Building Go binary: $output"
    echo "  Version: $version"
    echo "  Commit:  $commit"
    echo "  Date:    $date"

    mkdir -p "$(dirname "$output")"
    go build -ldflags "$ldflags" -o "$output" .

    echo "Binary created: $output"
    ls -lh "$output"
}

# Run tests with coverage
go_test() {
    local coverage="${1:-false}"
    local verbose="${2:-false}"

    local flags="-race"

    if [[ "$verbose" == "true" ]]; then
        flags="$flags -v"
    fi

    if [[ "$coverage" == "true" ]]; then
        echo "Running tests with coverage..."
        flags="$flags -coverprofile=coverage.out -covermode=atomic"
        go test $flags ./...

        echo ""
        echo "Coverage summary:"
        go tool cover -func=coverage.out | tail -1

        echo ""
        echo "To view HTML coverage report, run:"
        echo "  go tool cover -html=coverage.out"
    else
        echo "Running tests..."
        go test $flags ./...
    fi
}

# Cross-compile for multiple platforms
go_cross_compile() {
    local version="${1:-dev}"
    local platforms="${2:-linux/amd64,linux/arm64,darwin/amd64,darwin/arm64,windows/amd64}"
    local output_dir="${3:-./dist}"

    local app_name
    app_name="$(basename "$(pwd)")"

    local commit
    commit="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"

    local date
    date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    local ldflags="-s -w"
    ldflags="$ldflags -X main.version=$version"
    ldflags="$ldflags -X main.commit=$commit"
    ldflags="$ldflags -X main.buildDate=$date"

    mkdir -p "$output_dir"

    echo "Cross-compiling $app_name v$version for multiple platforms..."
    echo ""

    IFS=',' read -ra PLATFORM_LIST <<< "$platforms"
    for platform in "${PLATFORM_LIST[@]}"; do
        IFS='/' read -r os arch <<< "$platform"

        local output_name="$output_dir/${app_name}_${os}_${arch}"
        if [[ "$os" == "windows" ]]; then
            output_name="${output_name}.exe"
        fi

        echo "Building for $os/$arch..."
        GOOS="$os" GOARCH="$arch" go build -ldflags "$ldflags" -o "$output_name" .

        if [[ -f "$output_name" ]]; then
            echo "  Created: $output_name ($(ls -lh "$output_name" | awk '{print $5}'))"
        fi
    done

    echo ""
    echo "Cross-compilation complete. Binaries in: $output_dir"
    ls -lh "$output_dir"
}

# Install binary to GOPATH/bin or custom location
go_install() {
    local install_path="${1:-}"
    local version="${2:-dev}"

    local commit
    commit="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"

    local date
    date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    local ldflags="-s -w"
    ldflags="$ldflags -X main.version=$version"
    ldflags="$ldflags -X main.commit=$commit"
    ldflags="$ldflags -X main.buildDate=$date"

    if [[ -n "$install_path" ]]; then
        echo "Installing to: $install_path"
        go build -ldflags "$ldflags" -o "$install_path" .
    else
        echo "Installing to GOPATH/bin..."
        go install -ldflags "$ldflags" .
    fi

    echo "Installation complete"
}

# Clean build artifacts
go_clean() {
    local deep="${1:-false}"

    echo "Cleaning build artifacts..."

    if [[ -d "bin" ]]; then
        echo "  Removing bin/"
        rm -rf bin
    fi

    if [[ -d "dist" ]]; then
        echo "  Removing dist/"
        rm -rf dist
    fi

    if [[ -f "coverage.out" ]]; then
        echo "  Removing coverage.out"
        rm -f coverage.out
    fi

    go clean

    if [[ "$deep" == "true" ]]; then
        echo "  Deep clean: removing module cache..."
        go clean -modcache
    fi

    echo "Clean complete"
}

# Run go vet for code analysis
go_vet() {
    local verbose="${1:-false}"

    echo "Running go vet..."

    if [[ "$verbose" == "true" ]]; then
        go vet -v ./...
    else
        go vet ./...
    fi

    echo "Vet complete - no issues found"
}

# Format code
go_fmt() {
    local check="${1:-false}"

    if [[ "$check" == "true" ]]; then
        echo "Checking code formatting..."
        local unformatted
        unformatted=$(gofmt -l . 2>&1)

        if [[ -n "$unformatted" ]]; then
            echo "Error: The following files are not formatted:" >&2
            echo "$unformatted" >&2
            return 1
        fi

        echo "All files are properly formatted"
    else
        echo "Formatting Go code..."
        gofmt -w .
        echo "Formatting complete"
    fi
}

# Check for vulnerabilities using govulncheck
go_audit() {
    local install_if_missing="${1:-true}"

    if ! command -v govulncheck &> /dev/null; then
        if [[ "$install_if_missing" == "true" ]]; then
            echo "Installing govulncheck..."
            go install golang.org/x/vuln/cmd/govulncheck@latest
        else
            echo "Error: govulncheck not found" >&2
            echo "Install with: go install golang.org/x/vuln/cmd/govulncheck@latest" >&2
            return 1
        fi
    fi

    echo "Checking for vulnerabilities..."
    govulncheck ./...

    echo ""
    echo "Vulnerability scan complete"
}

# Get Go version info
go_version_info() {
    echo "Go version:"
    go version

    echo ""
    echo "Go environment:"
    go env GOVERSION GOOS GOARCH GOPATH GOROOT
}

# Download all dependencies
go_download() {
    echo "Downloading all dependencies..."
    go mod download
    echo "Download complete"
}

# Verify dependencies
go_verify() {
    echo "Verifying dependencies..."
    go mod verify
    echo "Verification complete"
}

# List all dependencies
go_list_deps() {
    local format="${1:-}"

    if [[ -n "$format" ]]; then
        go list -m -f "$format" all
    else
        echo "Direct dependencies:"
        go list -m all | grep -v "$(go list -m)"
    fi
}

# Check for outdated dependencies
go_check_updates() {
    if ! command -v go-mod-outdated &> /dev/null; then
        echo "Installing go-mod-outdated..."
        go install github.com/psampaz/go-mod-outdated@latest
    fi

    echo "Checking for outdated dependencies..."
    go list -u -m -json all | go-mod-outdated -direct
}

# Run static analysis
go_lint() {
    if ! command -v golangci-lint &> /dev/null; then
        echo "Error: golangci-lint not found" >&2
        echo "Install from: https://golangci-lint.run/usage/install/" >&2
        return 1
    fi

    echo "Running golangci-lint..."
    golangci-lint run ./...
    echo "Linting complete"
}

# Export functions
export -f go_mod_init
export -f go_mod_tidy
export -f go_build
export -f go_test
export -f go_cross_compile
export -f go_install
export -f go_clean
export -f go_vet
export -f go_fmt
export -f go_audit
export -f go_version_info
export -f go_download
export -f go_verify
export -f go_list_deps
export -f go_check_updates
export -f go_lint
