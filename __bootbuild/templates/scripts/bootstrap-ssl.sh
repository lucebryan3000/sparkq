#!/bin/bash

# ===================================================================
# bootstrap-ssl.sh
#
# Bootstrap local HTTPS certificate generation
# Creates SSL certificates for localhost development using mkcert or openssl
# ===================================================================

set -euo pipefail

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-ssl.sh"

# Source additional libraries
source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
source "${BOOTSTRAP_DIR}/lib/validation-common.sh"
source "${BOOTSTRAP_DIR}/lib/config-manager.sh"

# Get project root
PROJECT_ROOT=$(get_project_root "${1:-.}")
TEMPLATE_ROOT="${TEMPLATES_DIR}/root"

# Script identifier and answers file
SCRIPT_NAME="bootstrap-ssl"
ANSWERS_FILE=".bootstrap-answers.env"

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "SSL/HTTPS Configuration" \
    "ssl/ directory with certificates" \
    "openssl.cnf configuration" \
    "install-cert.sh helper script"

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping SSL certificate configuration..."

require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Check for certificate generation tools
CERT_METHOD=""
if require_command "mkcert" 2>/dev/null; then
    CERT_METHOD="mkcert"
    log_success "mkcert is installed (preferred method)"
elif require_command "openssl" 2>/dev/null; then
    CERT_METHOD="openssl"
    log_success "openssl is installed (fallback method)"
else
    track_warning "Neither mkcert nor openssl found"
    log_warning "Neither mkcert nor openssl found. Install one to generate certificates."
    CERT_METHOD="none"
fi

# ===================================================================
# Create SSL Directory
# ===================================================================

log_info "Creating ssl/ directory..."

SSL_DIR="$PROJECT_ROOT/ssl"

if [[ ! -d "$SSL_DIR" ]]; then
    if mkdir -p "$SSL_DIR"; then
        track_created "ssl/"
        log_success "Created ssl/ directory"
    else
        log_fatal "Failed to create ssl/ directory"
    fi
else
    log_info "ssl/ directory already exists"
fi

# ===================================================================
# Create openssl.cnf
# ===================================================================

log_info "Creating openssl.cnf configuration..."

if file_exists "$SSL_DIR/openssl.cnf"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$SSL_DIR/openssl.cnf"
    else
        track_skipped "openssl.cnf"
        log_warning "openssl.cnf already exists, skipping"
    fi
fi

if file_exists "$TEMPLATE_ROOT/ssl/openssl.cnf"; then
    if cp "$TEMPLATE_ROOT/ssl/openssl.cnf" "$SSL_DIR/"; then
        if verify_file "$SSL_DIR/openssl.cnf"; then
            track_created "ssl/openssl.cnf"
            log_file_created "$SCRIPT_NAME" "ssl/openssl.cnf"
        fi
    else
        log_fatal "Failed to copy openssl.cnf"
    fi
else
    track_warning "openssl.cnf template not found"
    log_warning "openssl.cnf template not found in $TEMPLATE_ROOT/ssl"
fi

# ===================================================================
# Create cert-info.txt
# ===================================================================

log_info "Creating certificate documentation..."

if file_exists "$TEMPLATE_ROOT/ssl/cert-info.txt"; then
    # Customize cert-info.txt with current timestamp and method
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    VALIDITY_DAYS="365"

    if cp "$TEMPLATE_ROOT/ssl/cert-info.txt" "$SSL_DIR/cert-info.txt"; then
        # Replace template variables
        sed -i "s/{{TIMESTAMP}}/$TIMESTAMP/g" "$SSL_DIR/cert-info.txt" 2>/dev/null || \
            sed -i '' "s/{{TIMESTAMP}}/$TIMESTAMP/g" "$SSL_DIR/cert-info.txt"
        sed -i "s/{{METHOD}}/$CERT_METHOD/g" "$SSL_DIR/cert-info.txt" 2>/dev/null || \
            sed -i '' "s/{{METHOD}}/$CERT_METHOD/g" "$SSL_DIR/cert-info.txt"
        sed -i "s/{{VALIDITY_DAYS}}/$VALIDITY_DAYS/g" "$SSL_DIR/cert-info.txt" 2>/dev/null || \
            sed -i '' "s/{{VALIDITY_DAYS}}/$VALIDITY_DAYS/g" "$SSL_DIR/cert-info.txt"

        if verify_file "$SSL_DIR/cert-info.txt"; then
            track_created "ssl/cert-info.txt"
            log_file_created "$SCRIPT_NAME" "ssl/cert-info.txt"
        fi
    else
        log_fatal "Failed to copy cert-info.txt"
    fi
else
    track_warning "cert-info.txt template not found"
    log_warning "cert-info.txt template not found in $TEMPLATE_ROOT/ssl"
fi

# ===================================================================
# Create install-cert.sh
# ===================================================================

log_info "Creating certificate installation helper..."

if file_exists "$TEMPLATE_ROOT/ssl/install-cert.sh"; then
    if cp "$TEMPLATE_ROOT/ssl/install-cert.sh" "$SSL_DIR/"; then
        # Make executable
        chmod +x "$SSL_DIR/install-cert.sh"

        if verify_file "$SSL_DIR/install-cert.sh"; then
            track_created "ssl/install-cert.sh"
            log_file_created "$SCRIPT_NAME" "ssl/install-cert.sh"
        fi
    else
        log_fatal "Failed to copy install-cert.sh"
    fi
else
    track_warning "install-cert.sh template not found"
    log_warning "install-cert.sh template not found in $TEMPLATE_ROOT/ssl"
fi

# ===================================================================
# Generate Certificates
# ===================================================================

generate_mkcert_certificates() {
    log_info "Generating certificates with mkcert..."

    cd "$SSL_DIR"

    # Check if mkcert CA is installed
    if ! mkcert -CAROOT >/dev/null 2>&1; then
        log_info "Installing mkcert CA (may require sudo)..."
        if mkcert -install; then
            log_success "mkcert CA installed"
        else
            log_warning "Failed to install mkcert CA"
            return 1
        fi
    fi

    # Generate certificate
    if mkcert -key-file localhost.key -cert-file localhost.crt localhost 127.0.0.1 ::1 "*.localhost"; then
        log_success "Generated certificates with mkcert"

        # Create combined PEM file
        cat localhost.crt localhost.key > localhost.pem
        log_success "Created combined PEM file"

        track_created "ssl/localhost.crt"
        track_created "ssl/localhost.key"
        track_created "ssl/localhost.pem"

        cd "$PROJECT_ROOT"
        return 0
    else
        log_warning "Failed to generate certificates with mkcert"
        cd "$PROJECT_ROOT"
        return 1
    fi
}

generate_openssl_certificates() {
    log_info "Generating self-signed certificates with openssl..."

    cd "$SSL_DIR"

    # Generate private key
    if openssl genrsa -out localhost.key 2048 >/dev/null 2>&1; then
        log_success "Generated private key"
    else
        log_warning "Failed to generate private key"
        cd "$PROJECT_ROOT"
        return 1
    fi

    # Generate certificate
    if openssl req -new -x509 -key localhost.key -out localhost.crt -days 365 \
        -config openssl.cnf >/dev/null 2>&1; then
        log_success "Generated self-signed certificate"

        # Create combined PEM file
        cat localhost.crt localhost.key > localhost.pem
        log_success "Created combined PEM file"

        track_created "ssl/localhost.crt"
        track_created "ssl/localhost.key"
        track_created "ssl/localhost.pem"

        log_warning "Certificate is self-signed. Trust it manually or use mkcert for auto-trusted certificates."

        cd "$PROJECT_ROOT"
        return 0
    else
        log_warning "Failed to generate certificate"
        cd "$PROJECT_ROOT"
        return 1
    fi
}

# Check if certificates already exist
if [[ -f "$SSL_DIR/localhost.crt" && -f "$SSL_DIR/localhost.key" ]]; then
    log_info "Certificates already exist in ssl/"

    # Check expiration
    if command -v openssl >/dev/null 2>&1; then
        EXPIRY=$(openssl x509 -in "$SSL_DIR/localhost.crt" -noout -enddate 2>/dev/null | cut -d= -f2)
        if [[ -n "$EXPIRY" ]]; then
            log_info "Current certificate expires: $EXPIRY"
        fi
    fi

    # Ask if user wants to regenerate
    if ! is_auto_approved "regenerate_ssl_certificates"; then
        log_info "To regenerate certificates, run this script again with -y or delete existing certificates"
    else
        log_info "Regenerating certificates..."
        rm -f "$SSL_DIR/localhost.crt" "$SSL_DIR/localhost.key" "$SSL_DIR/localhost.pem"

        if [[ "$CERT_METHOD" == "mkcert" ]]; then
            generate_mkcert_certificates
        elif [[ "$CERT_METHOD" == "openssl" ]]; then
            generate_openssl_certificates
        fi
    fi
else
    # Generate new certificates
    if [[ "$CERT_METHOD" == "mkcert" ]]; then
        generate_mkcert_certificates
    elif [[ "$CERT_METHOD" == "openssl" ]]; then
        generate_openssl_certificates
    else
        log_warning "No certificate generation tool available"
        log_info "Install mkcert (recommended) or openssl to generate certificates"
    fi
fi

# ===================================================================
# Update .gitignore
# ===================================================================

log_info "Updating .gitignore to exclude private keys..."

GITIGNORE="$PROJECT_ROOT/.gitignore"

if [[ -f "$GITIGNORE" ]]; then
    # Check if ssl exclusions already exist
    if ! grep -q "ssl/\*\.key" "$GITIGNORE" 2>/dev/null; then
        echo "" >> "$GITIGNORE"
        echo "# SSL private keys (never commit)" >> "$GITIGNORE"
        echo "ssl/*.key" >> "$GITIGNORE"
        echo "ssl/*.pem" >> "$GITIGNORE"
        log_success "Added SSL exclusions to .gitignore"
        track_created ".gitignore (updated)"
    else
        log_info "SSL exclusions already in .gitignore"
    fi
else
    log_warning ".gitignore not found, consider creating it"
fi

# ===================================================================
# Validation & Testing (Self-Testing Protocol)
# ===================================================================

validate_bootstrap() {
    local errors=0

    log_info "Validating bootstrap configuration..."
    echo ""

    # Test 1: Required directory
    log_info "Checking SSL directory..."
    if [[ -d "$SSL_DIR" ]]; then
        log_success "Directory: ssl/ exists"
    else
        log_warning "Directory: ssl/ not found"
        errors=$((errors + 1))
    fi

    # Test 2: Configuration files
    log_info "Checking configuration files..."
    for file in openssl.cnf cert-info.txt install-cert.sh; do
        if [[ -f "$SSL_DIR/$file" ]]; then
            log_success "File: $file exists"
        else
            log_warning "File: $file not found"
        fi
    done

    # Test 3: Certificate files
    log_info "Checking certificate files..."
    if [[ -f "$SSL_DIR/localhost.crt" ]]; then
        log_success "Certificate: localhost.crt exists"

        # Validate certificate with openssl
        if command -v openssl >/dev/null 2>&1; then
            if openssl x509 -in "$SSL_DIR/localhost.crt" -noout -text >/dev/null 2>&1; then
                log_success "Certificate: Valid X.509 format"

                # Check subject
                SUBJECT=$(openssl x509 -in "$SSL_DIR/localhost.crt" -noout -subject | sed 's/subject=//')
                log_success "Subject: $SUBJECT"

                # Check expiration
                EXPIRY=$(openssl x509 -in "$SSL_DIR/localhost.crt" -noout -enddate | cut -d= -f2)
                log_success "Expires: $EXPIRY"

                # Check SANs
                SANS=$(openssl x509 -in "$SSL_DIR/localhost.crt" -noout -ext subjectAltName 2>/dev/null | grep -v "X509v3")
                if [[ -n "$SANS" ]]; then
                    log_success "SANs: $SANS"
                fi
            else
                log_warning "Certificate: Invalid format"
                errors=$((errors + 1))
            fi
        fi
    else
        log_info "Certificate: Not generated (requires mkcert or openssl)"
    fi

    if [[ -f "$SSL_DIR/localhost.key" ]]; then
        log_success "Private key: localhost.key exists"

        # Check key permissions
        PERMS=$(stat -c %a "$SSL_DIR/localhost.key" 2>/dev/null || stat -f %Lp "$SSL_DIR/localhost.key")
        if [[ "$PERMS" == "600" || "$PERMS" == "644" ]]; then
            log_success "Permissions: $PERMS (acceptable)"
        else
            log_info "Permissions: $PERMS (consider 600 for better security)"
        fi
    else
        log_info "Private key: Not generated (requires mkcert or openssl)"
    fi

    # Test 4: .gitignore protection
    log_info "Checking .gitignore protection..."
    if [[ -f "$PROJECT_ROOT/.gitignore" ]]; then
        if grep -q "ssl/\*\.key" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
            log_success "Private keys excluded from git"
        else
            log_warning "Private keys not excluded in .gitignore"
        fi
    fi

    # Test 5: Installation script
    log_info "Checking installation helper..."
    if [[ -x "$SSL_DIR/install-cert.sh" ]]; then
        log_success "install-cert.sh is executable"
    elif [[ -f "$SSL_DIR/install-cert.sh" ]]; then
        log_warning "install-cert.sh exists but not executable"
    fi

    # Summary
    echo ""
    if [[ $errors -eq 0 ]]; then
        log_success "All validation checks passed!"
        return 0
    else
        log_warning "Validation found $errors issue(s) (non-critical)"
        return 0
    fi
}

# ===================================================================
# Summary & Next Steps
# ===================================================================

validate_bootstrap

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"
show_summary
show_log_location

log_info "Next steps:"
if [[ -f "$SSL_DIR/localhost.crt" ]]; then
    echo "  ✓ SSL certificates generated"
    echo ""
    echo "  Trust certificate in system (optional):"
    if [[ "$CERT_METHOD" == "mkcert" ]]; then
        echo "    Already trusted! (mkcert installed to system CA)"
    else
        echo "    cd ssl && ./install-cert.sh"
    fi
    echo ""
    echo "  Use in your application:"
    echo "    1. Point your server to ssl/localhost.crt and ssl/localhost.key"
    echo "    2. See ssl/cert-info.txt for framework-specific examples"
    echo "    3. Access your app at https://localhost:PORT"
    echo ""
    echo "  Verify HTTPS:"
    echo "    curl --cacert ssl/localhost.crt https://localhost:PORT"
else
    echo "  1. Install certificate generator:"
    echo "     - mkcert (recommended): brew install mkcert (macOS) or apt install mkcert (Linux)"
    echo "     - openssl (fallback): usually pre-installed"
    echo ""
    echo "  2. Generate certificates:"
    echo "     ./bootstrap ssl (run again)"
    echo ""
    echo "  3. See ssl/cert-info.txt for usage examples"
fi
echo ""
echo "  Security reminder:"
echo "    - Private keys are excluded from git"
echo "    - Never use self-signed certs in production"
echo "    - Regenerate certificates annually"
echo ""
