#!/bin/bash

# ===================================================================
# install-cert.sh
#
# Helper script to install local SSL certificates in system trust store
# Supports macOS, Linux (Debian/Ubuntu), and provides Windows instructions
# ===================================================================

set -euo pipefail

CERT_FILE="${1:-ssl/localhost.crt}"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    OS="windows"
else
    OS="unknown"
fi

# Check if certificate exists
if [[ ! -f "$CERT_FILE" ]]; then
    echo "Error: Certificate file not found: $CERT_FILE"
    exit 1
fi

echo "Installing certificate: $CERT_FILE"
echo "Detected OS: $OS"
echo ""

case $OS in
    macos)
        echo "Installing on macOS..."
        echo "This requires sudo privileges."
        echo ""

        sudo security add-trusted-cert -d -r trustRoot \
            -k /Library/Keychains/System.keychain "$CERT_FILE"

        echo "Certificate installed successfully!"
        echo "Restart your browsers for changes to take effect."
        ;;

    linux)
        echo "Installing on Linux..."
        echo "This requires sudo privileges."
        echo ""

        # Copy to ca-certificates
        sudo cp "$CERT_FILE" /usr/local/share/ca-certificates/localhost-dev.crt
        sudo update-ca-certificates

        echo "Certificate installed successfully!"
        echo "Restart your browsers for changes to take effect."
        ;;

    windows)
        echo "Windows detected. Please run the following in PowerShell (as Administrator):"
        echo ""
        echo "  Import-Certificate -FilePath $CERT_FILE -CertStoreLocation Cert:\\LocalMachine\\Root"
        echo ""
        exit 0
        ;;

    *)
        echo "Unsupported OS: $OSTYPE"
        echo "Please manually add the certificate to your system trust store."
        exit 1
        ;;
esac

echo ""
echo "Note: Firefox uses its own certificate store."
echo "To trust in Firefox:"
echo "  1. Preferences > Privacy & Security > Certificates > View Certificates"
echo "  2. Authorities tab > Import > Select $CERT_FILE"
echo "  3. Check 'Trust this CA to identify websites'"
