#!/bin/bash
# =============================================================================
# @script         bootstrap-network-vpn
# @version        1.0.0
# @phase          5
# @category       deploy
# @priority       50
# @short          VPN and secure networking configuration
# @description    Configures VPN infrastructure using WireGuard with key
#                 generation, iptables rules, Docker networking, peer
#                 management, and security monitoring documentation.
#
# @creates        config/network/vpn/wireguard-config.conf
# @creates        config/network/vpn/generate-keys.sh
# @creates        config/network/vpn/iptables-rules.conf
# @creates        config/network/vpn/docker-network.yml
# @creates        .env.vpn
#
# @detects        has_vpn_config
# @questions      network-vpn
# @defaults       vpn.enabled=false, vpn.provider=wireguard, vpn.port=51820
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
#
# @config_section  vpn
# @env_vars        ACTIVE_PEERS,BLUE,CREATED_FILES,DNS_SERVER_1,DNS_SERVER_2,DNS_SERVERS,DOCKER_NETWORK_DRIVER,DOCKER_NETWORK_FILE,DOCKER_NETWORK_NAME,DOCKER_NETWORK_SUBNET,ENABLED,ENV_FILE,EUID,FILES_TO_CREATE,FIREWALL_ENABLED,GREEN,IPTABLES_FILE,KEYGEN_SCRIPT,KEYS_DIR,MONITORING_DOC,NC,PEER_COUNT,PEER_IP,PEER_NAME,PEER_PRESHARED_KEY,PEER_PRIVATE_KEY,PEER_PUBLIC_KEY,PEERS_DIR,SERVER_PRIVATE_KEY,SERVER_PUBLIC_KEY,SKIPPED_FILES,VPN_CIDR,VPN_CIDR_BASE,VPN_CONFIG,VPN_CONFIG_FILE,VPN_ENDPOINT,VPN_INTERFACE,VPN_KEEPALIVE,VPN_KEY_BITS,VPN_PORT,VPN_PROTOCOL,VPN_PROVIDER,YELLOW
# @interactive     no
# @platforms       all
# @conflicts       none
# @rollback        rm -rf config/network/vpn/wireguard-config.conf config/network/vpn/generate-keys.sh config/network/vpn/iptables-rules.conf config/network/vpn/docker-network.yml .env.vpn
# @verify          test -f config/network/vpn/wireguard-config.conf
# @docs            https://www.wireguard.com/quickstart/
# =============================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Source docker utilities if available
if [[ -f "${BOOTSTRAP_DIR}/lib/docker-utils.sh" ]]; then
    source "${BOOTSTRAP_DIR}/lib/docker-utils.sh"
fi

# Initialize script
init_script "bootstrap-network-vpn"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-network-vpn"

# Track created files for display
declare -a CREATED_FILES=()
declare -a SKIPPED_FILES=()

# ===================================================================
# Read Configuration
# ===================================================================

# Check if this bootstrap should run
ENABLED=$(config_get "vpn.enabled" "false")
if [[ "$ENABLED" != "true" ]]; then
    log_info "VPN/Network bootstrap disabled in config"
    exit 0
fi

# Read VPN-specific settings
VPN_PROVIDER=$(config_get "vpn.provider" "wireguard")
VPN_PROTOCOL=$(config_get "vpn.protocol" "wireguard")
VPN_ENDPOINT=$(config_get "vpn.endpoint" "")
VPN_CIDR=$(config_get "vpn.cidr" "10.0.0.0/24")
VPN_PORT=$(config_get "vpn.port" "51820")
VPN_KEY_BITS=$(config_get "vpn.key_bits" "256")
VPN_INTERFACE=$(config_get "vpn.interface" "wg0")
DNS_SERVERS=$(config_get "vpn.dns_servers" "8.8.8.8,8.8.4.4")
VPN_KEEPALIVE=$(config_get "vpn.keepalive" "25")

# Get project settings
PROJECT_NAME=$(config_get "project.name" "app")
PROJECT_TIER=$(config_get "project.tier" "dev")

# Docker network settings
DOCKER_NETWORK_NAME=$(config_get "vpn.docker_network_name" "${PROJECT_NAME}-vpn-net")
DOCKER_NETWORK_DRIVER=$(config_get "vpn.docker_network_driver" "overlay")
DOCKER_NETWORK_SUBNET=$(config_get "vpn.docker_network_subnet" "10.1.0.0/24")

# Security settings
FIREWALL_ENABLED=$(config_get "vpn.firewall_enabled" "true")
PEER_COUNT=$(config_get "vpn.peer_count" "3")

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

FILES_TO_CREATE=(
    "config/network/vpn/"
    "config/network/vpn/${VPN_PROTOCOL}-config.conf"
    "config/network/vpn/generate-keys.sh"
    "config/network/vpn/iptables-rules.conf"
    "config/network/vpn/docker-network.yml"
    "config/network/vpn/peer-*.conf (${PEER_COUNT} peers)"
    ".env.vpn"
)

pre_execution_confirm "$SCRIPT_NAME" "VPN & Secure Network Configuration" \
    "${FILES_TO_CREATE[@]}"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check if project directory exists
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"

# Check if we can write to project
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Check if running as root (needed for network config in production)
if [[ "$PROJECT_TIER" == "prod" ]] || [[ "$PROJECT_TIER" == "production" ]]; then
    if [[ $EUID -ne 0 ]] && [[ "$FIREWALL_ENABLED" == "true" ]]; then
        log_warning "Running as non-root. Some network configurations may require sudo privileges."
    fi
fi

# Check for required tools (optional, warn if missing)
if ! command -v wg &>/dev/null && [[ "$VPN_PROTOCOL" == "wireguard" ]]; then
    log_warning "WireGuard tools not installed. Key generation will require manual setup."
fi

log_success "Environment validated"

# ===================================================================
# Create Network Directory Structure
# ===================================================================

log_info "Creating VPN directory structure..."

if ! dir_exists "$PROJECT_ROOT/config/network/vpn"; then
    ensure_dir "$PROJECT_ROOT/config/network/vpn"
    log_dir_created "$SCRIPT_NAME" "config/network/vpn/"
fi

if ! dir_exists "$PROJECT_ROOT/config/network/vpn/peers"; then
    ensure_dir "$PROJECT_ROOT/config/network/vpn/peers"
    log_dir_created "$SCRIPT_NAME" "config/network/vpn/peers/"
fi

if ! dir_exists "$PROJECT_ROOT/config/network/vpn/keys"; then
    ensure_dir "$PROJECT_ROOT/config/network/vpn/keys"
    chmod 700 "$PROJECT_ROOT/config/network/vpn/keys"
    log_dir_created "$SCRIPT_NAME" "config/network/vpn/keys/"
fi

log_success "Directory structure created"

# ===================================================================
# Create WireGuard Configuration
# ===================================================================

log_info "Creating VPN configuration..."

VPN_CONFIG_FILE="$PROJECT_ROOT/config/network/vpn/${VPN_PROTOCOL}-config.conf"

if file_exists "$VPN_CONFIG_FILE"; then
    backup_file "$VPN_CONFIG_FILE"
    SKIPPED_FILES+=("config/network/vpn/${VPN_PROTOCOL}-config.conf (backed up)")
    log_warning "${VPN_PROTOCOL}-config.conf already exists, backed up"
else
    if [[ "$VPN_PROTOCOL" == "wireguard" ]]; then
        cat > "$VPN_CONFIG_FILE" << 'EOFWG'
# ===================================================================
# WireGuard VPN Configuration - Server
# Auto-generated by bootstrap-network-vpn.sh
# ===================================================================

[Interface]
# Server private key (generate with: wg genkey)
PrivateKey = SERVER_PRIVATE_KEY_PLACEHOLDER

# Server address within VPN network
Address = {{VPN_CIDR_BASE}}.1/24

# VPN listen port
ListenPort = {{VPN_PORT}}

# DNS servers for VPN clients
DNS = {{DNS_SERVERS}}

# PostUp: Commands to run when VPN starts
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostUp = ip6tables -A FORWARD -i %i -j ACCEPT; ip6tables -A FORWARD -o %i -j ACCEPT; ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# PostDown: Commands to run when VPN stops
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
PostDown = ip6tables -D FORWARD -i %i -j ACCEPT; ip6tables -D FORWARD -o %i -j ACCEPT; ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# ===================================================================
# Peers (clients connecting to this VPN server)
# Each peer should have its own [Peer] section
# Generate peer configs with: bash config/network/vpn/generate-keys.sh
# ===================================================================

# Peer configurations will be appended here by generate-keys.sh
# Example:
# [Peer]
# PublicKey = PEER_PUBLIC_KEY
# AllowedIPs = 10.0.0.2/32
# PersistentKeepalive = 25

EOFWG
    else
        # OpenVPN configuration
        cat > "$VPN_CONFIG_FILE" << 'EOFOVPN'
# ===================================================================
# OpenVPN Server Configuration
# Auto-generated by bootstrap-network-vpn.sh
# ===================================================================

port {{VPN_PORT}}
proto udp
dev tun

# SSL/TLS certificates
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh2048.pem

# Network configuration
server {{VPN_CIDR_BASE}}.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt

# Push routes to clients
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS {{DNS_SERVERS_1}}"
push "dhcp-option DNS {{DNS_SERVERS_2}}"

# Client-to-client communication
client-to-client

# Keepalive ping every 10s, timeout after 120s
keepalive 10 120

# Cryptographic cipher
cipher AES-256-CBC
auth SHA256

# Compression
compress lz4-v2
push "compress lz4-v2"

# User/group nobody for security
user nobody
group nogroup

# Persist keys and TUN device through restarts
persist-key
persist-tun

# Log verbosity (0-9, 3 is recommended)
verb 3

# Log to file
status /var/log/openvpn/openvpn-status.log
log-append /var/log/openvpn/openvpn.log

EOFOVPN
    fi

    # Get base IP for CIDR (e.g., 10.0.0 from 10.0.0.0/24)
    VPN_CIDR_BASE=$(echo "$VPN_CIDR" | cut -d'/' -f1 | rev | cut -d'.' -f2- | rev)

    # Replace placeholders
    sed -i "s/{{VPN_CIDR_BASE}}/$VPN_CIDR_BASE/g" "$VPN_CONFIG_FILE"
    sed -i "s/{{VPN_PORT}}/$VPN_PORT/g" "$VPN_CONFIG_FILE"
    sed -i "s/{{DNS_SERVERS}}/$DNS_SERVERS/g" "$VPN_CONFIG_FILE"

    # For OpenVPN, split DNS servers
    DNS_SERVER_1=$(echo "$DNS_SERVERS" | cut -d',' -f1)
    DNS_SERVER_2=$(echo "$DNS_SERVERS" | cut -d',' -f2)
    sed -i "s/{{DNS_SERVERS_1}}/$DNS_SERVER_1/g" "$VPN_CONFIG_FILE"
    sed -i "s/{{DNS_SERVERS_2}}/$DNS_SERVER_2/g" "$VPN_CONFIG_FILE"

    verify_file "$VPN_CONFIG_FILE"
    log_file_created "$SCRIPT_NAME" "config/network/vpn/${VPN_PROTOCOL}-config.conf"
    CREATED_FILES+=("config/network/vpn/${VPN_PROTOCOL}-config.conf")
fi

# ===================================================================
# Create Key Generation Script
# ===================================================================

log_info "Creating key generation script..."

KEYGEN_SCRIPT="$PROJECT_ROOT/config/network/vpn/generate-keys.sh"

if file_exists "$KEYGEN_SCRIPT"; then
    backup_file "$KEYGEN_SCRIPT"
    SKIPPED_FILES+=("config/network/vpn/generate-keys.sh (backed up)")
    log_warning "generate-keys.sh already exists, backed up"
else
    cat > "$KEYGEN_SCRIPT" << 'EOFKEYGEN'
#!/bin/bash

# ===================================================================
# VPN Key Generation Script
# Auto-generated by bootstrap-network-vpn.sh
# ===================================================================

set -euo pipefail

VPN_PROTOCOL="{{VPN_PROTOCOL}}"
KEYS_DIR="./config/network/vpn/keys"
PEERS_DIR="./config/network/vpn/peers"
VPN_CONFIG="./config/network/vpn/${VPN_PROTOCOL}-config.conf"

mkdir -p "$KEYS_DIR" "$PEERS_DIR"
chmod 700 "$KEYS_DIR"

echo "=================================================="
echo "VPN Key Generation - $VPN_PROTOCOL"
echo "=================================================="
echo ""

# ===================================================================
# WireGuard Key Generation
# ===================================================================

if [[ "$VPN_PROTOCOL" == "wireguard" ]]; then
    if ! command -v wg &>/dev/null; then
        echo "Error: WireGuard tools not installed"
        echo "Install with: sudo apt install wireguard-tools"
        exit 1
    fi

    # Generate server keys
    echo "Generating server keys..."
    SERVER_PRIVATE_KEY=$(wg genkey)
    SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)

    echo "$SERVER_PRIVATE_KEY" > "$KEYS_DIR/server-private.key"
    echo "$SERVER_PUBLIC_KEY" > "$KEYS_DIR/server-public.key"
    chmod 600 "$KEYS_DIR/server-private.key"
    chmod 644 "$KEYS_DIR/server-public.key"

    echo "✓ Server keys generated"
    echo "  Private: $KEYS_DIR/server-private.key"
    echo "  Public:  $KEYS_DIR/server-public.key"
    echo ""

    # Update server config with private key
    sed -i "s/SERVER_PRIVATE_KEY_PLACEHOLDER/$SERVER_PRIVATE_KEY/g" "$VPN_CONFIG"

    # Generate peer keys
    PEER_COUNT={{PEER_COUNT}}
    VPN_CIDR_BASE="{{VPN_CIDR_BASE}}"

    for i in $(seq 1 $PEER_COUNT); do
        PEER_NAME="peer-$i"
        PEER_IP="${VPN_CIDR_BASE}.$((i + 1))"

        echo "Generating keys for $PEER_NAME..."

        PEER_PRIVATE_KEY=$(wg genkey)
        PEER_PUBLIC_KEY=$(echo "$PEER_PRIVATE_KEY" | wg pubkey)
        PEER_PRESHARED_KEY=$(wg genpsk)

        echo "$PEER_PRIVATE_KEY" > "$KEYS_DIR/${PEER_NAME}-private.key"
        echo "$PEER_PUBLIC_KEY" > "$KEYS_DIR/${PEER_NAME}-public.key"
        echo "$PEER_PRESHARED_KEY" > "$KEYS_DIR/${PEER_NAME}-preshared.key"
        chmod 600 "$KEYS_DIR/${PEER_NAME}-"*.key

        # Create peer client config
        cat > "$PEERS_DIR/${PEER_NAME}.conf" << EOFPEER
[Interface]
PrivateKey = $PEER_PRIVATE_KEY
Address = $PEER_IP/32
DNS = {{DNS_SERVERS}}

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
PresharedKey = $PEER_PRESHARED_KEY
Endpoint = {{VPN_ENDPOINT}}:{{VPN_PORT}}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = {{VPN_KEEPALIVE}}
EOFPEER

        # Append peer to server config
        cat >> "$VPN_CONFIG" << EOFSERVER

# Peer: $PEER_NAME
[Peer]
PublicKey = $PEER_PUBLIC_KEY
PresharedKey = $PEER_PRESHARED_KEY
AllowedIPs = $PEER_IP/32
PersistentKeepalive = {{VPN_KEEPALIVE}}
EOFSERVER

        echo "✓ Generated $PEER_NAME config"
    done

    echo ""
    echo "=================================================="
    echo "WireGuard Setup Complete"
    echo "=================================================="
    echo ""
    echo "Server config: $VPN_CONFIG"
    echo "Client configs: $PEERS_DIR/peer-*.conf"
    echo ""
    echo "Next steps:"
    echo "1. Copy peer configs to client devices"
    echo "2. Start server: wg-quick up {{VPN_INTERFACE}}"
    echo "3. Check status: wg show"
    echo ""

# ===================================================================
# OpenVPN Key Generation
# ===================================================================

elif [[ "$VPN_PROTOCOL" == "openvpn" ]]; then
    if ! command -v openssl &>/dev/null; then
        echo "Error: OpenSSL not installed"
        exit 1
    fi

    echo "OpenVPN key generation requires Easy-RSA or manual PKI setup."
    echo "Please follow OpenVPN documentation to:"
    echo "  1. Install Easy-RSA: apt install easy-rsa"
    echo "  2. Initialize PKI: make-cadir ~/openvpn-ca"
    echo "  3. Generate CA, server cert, DH params"
    echo "  4. Generate client certificates"
    echo ""
    echo "Reference: https://openvpn.net/community-resources/how-to/"

else
    echo "Error: Unknown VPN protocol: $VPN_PROTOCOL"
    exit 1
fi
EOFKEYGEN

    # Get base IP for CIDR
    VPN_CIDR_BASE=$(echo "$VPN_CIDR" | cut -d'/' -f1 | rev | cut -d'.' -f2- | rev)

    # Replace placeholders
    sed -i "s/{{VPN_PROTOCOL}}/$VPN_PROTOCOL/g" "$KEYGEN_SCRIPT"
    sed -i "s/{{PEER_COUNT}}/$PEER_COUNT/g" "$KEYGEN_SCRIPT"
    sed -i "s/{{VPN_CIDR_BASE}}/$VPN_CIDR_BASE/g" "$KEYGEN_SCRIPT"
    sed -i "s/{{DNS_SERVERS}}/$DNS_SERVERS/g" "$KEYGEN_SCRIPT"
    sed -i "s/{{VPN_ENDPOINT}}/$VPN_ENDPOINT/g" "$KEYGEN_SCRIPT"
    sed -i "s/{{VPN_PORT}}/$VPN_PORT/g" "$KEYGEN_SCRIPT"
    sed -i "s/{{VPN_KEEPALIVE}}/$VPN_KEEPALIVE/g" "$KEYGEN_SCRIPT"
    sed -i "s/{{VPN_INTERFACE}}/$VPN_INTERFACE/g" "$KEYGEN_SCRIPT"

    chmod +x "$KEYGEN_SCRIPT"

    verify_file "$KEYGEN_SCRIPT"
    log_file_created "$SCRIPT_NAME" "config/network/vpn/generate-keys.sh"
    CREATED_FILES+=("config/network/vpn/generate-keys.sh")
fi

# ===================================================================
# Create IPTables Rules Configuration
# ===================================================================

if [[ "$FIREWALL_ENABLED" == "true" ]]; then
    log_info "Creating iptables rules configuration..."

    IPTABLES_FILE="$PROJECT_ROOT/config/network/vpn/iptables-rules.conf"

    if file_exists "$IPTABLES_FILE"; then
        backup_file "$IPTABLES_FILE"
        SKIPPED_FILES+=("config/network/vpn/iptables-rules.conf (backed up)")
        log_warning "iptables-rules.conf already exists, backed up"
    else
        cat > "$IPTABLES_FILE" << 'EOFIPTABLES'
#!/bin/bash

# ===================================================================
# IPTables Firewall Rules for VPN
# Auto-generated by bootstrap-network-vpn.sh
# ===================================================================

# IMPORTANT: Review and customize these rules before applying
# Apply with: sudo bash config/network/vpn/iptables-rules.conf

set -euo pipefail

VPN_INTERFACE="{{VPN_INTERFACE}}"
VPN_PORT="{{VPN_PORT}}"
VPN_CIDR="{{VPN_CIDR}}"

echo "Applying iptables rules for VPN..."

# ===================================================================
# INPUT Rules - Allow VPN connections
# ===================================================================

# Allow VPN port (WireGuard/OpenVPN)
iptables -A INPUT -p udp --dport $VPN_PORT -j ACCEPT

# Allow VPN interface traffic
iptables -A INPUT -i $VPN_INTERFACE -j ACCEPT

# ===================================================================
# FORWARD Rules - Allow VPN routing
# ===================================================================

# Allow forwarding from VPN interface
iptables -A FORWARD -i $VPN_INTERFACE -j ACCEPT
iptables -A FORWARD -o $VPN_INTERFACE -j ACCEPT

# Allow established/related connections
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

# ===================================================================
# NAT Rules - Masquerade VPN traffic
# ===================================================================

# Enable NAT for VPN clients to access internet
iptables -t nat -A POSTROUTING -s $VPN_CIDR -o eth0 -j MASQUERADE

# ===================================================================
# Security Rules - Rate limiting
# ===================================================================

# Rate limit new VPN connections (prevent DoS)
iptables -A INPUT -p udp --dport $VPN_PORT -m state --state NEW -m recent --set
iptables -A INPUT -p udp --dport $VPN_PORT -m state --state NEW -m recent --update --seconds 60 --hitcount 10 -j DROP

# ===================================================================
# IPv6 Rules (if enabled)
# ===================================================================

# Allow VPN port
ip6tables -A INPUT -p udp --dport $VPN_PORT -j ACCEPT

# Allow VPN interface
ip6tables -A INPUT -i $VPN_INTERFACE -j ACCEPT

# Allow forwarding
ip6tables -A FORWARD -i $VPN_INTERFACE -j ACCEPT
ip6tables -A FORWARD -o $VPN_INTERFACE -j ACCEPT

echo "✓ IPTables rules applied"
echo ""
echo "To persist rules after reboot:"
echo "  Ubuntu/Debian: apt install iptables-persistent"
echo "  Then: netfilter-persistent save"
echo ""
echo "To view current rules:"
echo "  iptables -L -v -n"
echo "  iptables -t nat -L -v -n"
EOFIPTABLES

        # Replace placeholders
        sed -i "s/{{VPN_INTERFACE}}/$VPN_INTERFACE/g" "$IPTABLES_FILE"
        sed -i "s/{{VPN_PORT}}/$VPN_PORT/g" "$IPTABLES_FILE"
        sed -i "s/{{VPN_CIDR}}/$VPN_CIDR/g" "$IPTABLES_FILE"

        chmod +x "$IPTABLES_FILE"

        verify_file "$IPTABLES_FILE"
        log_file_created "$SCRIPT_NAME" "config/network/vpn/iptables-rules.conf"
        CREATED_FILES+=("config/network/vpn/iptables-rules.conf")
    fi
fi

# ===================================================================
# Create Docker Network Configuration
# ===================================================================

log_info "Creating Docker network configuration..."

DOCKER_NETWORK_FILE="$PROJECT_ROOT/config/network/vpn/docker-network.yml"

if file_exists "$DOCKER_NETWORK_FILE"; then
    backup_file "$DOCKER_NETWORK_FILE"
    SKIPPED_FILES+=("config/network/vpn/docker-network.yml (backed up)")
    log_warning "docker-network.yml already exists, backed up"
else
    cat > "$DOCKER_NETWORK_FILE" << 'EOFDOCKER'
version: '3.8'

# ===================================================================
# Docker Network Configuration for VPN/Secure Networking
# Auto-generated by bootstrap-network-vpn.sh
# ===================================================================

networks:
  # Overlay network for multi-host communication
  {{DOCKER_NETWORK_NAME}}:
    driver: {{DOCKER_NETWORK_DRIVER}}
    driver_opts:
      encrypted: "true"
    ipam:
      config:
        - subnet: {{DOCKER_NETWORK_SUBNET}}
    labels:
      com.example.description: "Encrypted VPN network for {{PROJECT_NAME}}"
      com.example.environment: "{{PROJECT_TIER}}"

# ===================================================================
# VPN Service Example (WireGuard)
# Uncomment to deploy VPN server in Docker
# ===================================================================

# services:
#   wireguard:
#     image: linuxserver/wireguard:latest
#     container_name: {{PROJECT_NAME}}-wireguard
#     cap_add:
#       - NET_ADMIN
#       - SYS_MODULE
#     environment:
#       - PUID=1000
#       - PGID=1000
#       - TZ=America/Chicago
#       - SERVERURL={{VPN_ENDPOINT}}
#       - SERVERPORT={{VPN_PORT}}
#       - PEERS={{PEER_COUNT}}
#       - PEERDNS={{DNS_SERVERS}}
#       - INTERNAL_SUBNET={{VPN_CIDR}}
#     volumes:
#       - ./config/network/vpn:/config
#       - /lib/modules:/lib/modules
#     ports:
#       - "{{VPN_PORT}}:51820/udp"
#     sysctls:
#       - net.ipv4.conf.all.src_valid_mark=1
#     networks:
#       - {{DOCKER_NETWORK_NAME}}
#     restart: unless-stopped

# ===================================================================
# Notes on Service Mesh Integration
# ===================================================================
# For production deployments, consider integrating:
#
# 1. Istio Service Mesh
#    - mTLS between services
#    - Traffic management and observability
#    - Install: https://istio.io/latest/docs/setup/
#
# 2. Linkerd
#    - Lightweight service mesh
#    - Automatic mTLS
#    - Install: https://linkerd.io/getting-started/
#
# 3. Consul Connect
#    - Service discovery + secure networking
#    - Multi-datacenter support
#    - Install: https://www.consul.io/docs/connect
#
# Add service mesh sidecar proxies to your services for:
# - Automatic encryption
# - Load balancing
# - Circuit breaking
# - Distributed tracing

EOFDOCKER

    # Replace placeholders
    sed -i "s/{{DOCKER_NETWORK_NAME}}/$DOCKER_NETWORK_NAME/g" "$DOCKER_NETWORK_FILE"
    sed -i "s/{{DOCKER_NETWORK_DRIVER}}/$DOCKER_NETWORK_DRIVER/g" "$DOCKER_NETWORK_FILE"
    sed -i "s/{{DOCKER_NETWORK_SUBNET}}/$DOCKER_NETWORK_SUBNET/g" "$DOCKER_NETWORK_FILE"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$DOCKER_NETWORK_FILE"
    sed -i "s/{{PROJECT_TIER}}/$PROJECT_TIER/g" "$DOCKER_NETWORK_FILE"
    sed -i "s/{{VPN_ENDPOINT}}/$VPN_ENDPOINT/g" "$DOCKER_NETWORK_FILE"
    sed -i "s/{{VPN_PORT}}/$VPN_PORT/g" "$DOCKER_NETWORK_FILE"
    sed -i "s/{{PEER_COUNT}}/$PEER_COUNT/g" "$DOCKER_NETWORK_FILE"
    sed -i "s/{{DNS_SERVERS}}/$DNS_SERVERS/g" "$DOCKER_NETWORK_FILE"
    sed -i "s/{{VPN_CIDR}}/$VPN_CIDR/g" "$DOCKER_NETWORK_FILE"

    verify_file "$DOCKER_NETWORK_FILE"
    log_file_created "$SCRIPT_NAME" "config/network/vpn/docker-network.yml"
    CREATED_FILES+=("config/network/vpn/docker-network.yml")
fi

# ===================================================================
# Create Environment File
# ===================================================================

log_info "Creating VPN environment configuration..."

ENV_FILE="$PROJECT_ROOT/.env.vpn"

if file_exists "$ENV_FILE"; then
    backup_file "$ENV_FILE"
    SKIPPED_FILES+=(".env.vpn (backed up)")
    log_warning ".env.vpn already exists, backed up"
else
    cat > "$ENV_FILE" << 'EOFENV'
# ===================================================================
# VPN Environment Configuration
# Auto-generated by bootstrap-network-vpn.sh
# ===================================================================

# VPN Protocol
VPN_PROTOCOL={{VPN_PROTOCOL}}
VPN_PROVIDER={{VPN_PROVIDER}}

# Network Configuration
VPN_INTERFACE={{VPN_INTERFACE}}
VPN_PORT={{VPN_PORT}}
VPN_CIDR={{VPN_CIDR}}
VPN_ENDPOINT={{VPN_ENDPOINT}}

# DNS Configuration
DNS_SERVERS={{DNS_SERVERS}}

# Connection Settings
VPN_KEEPALIVE={{VPN_KEEPALIVE}}
VPN_KEY_BITS={{VPN_KEY_BITS}}

# Docker Network
DOCKER_NETWORK_NAME={{DOCKER_NETWORK_NAME}}
DOCKER_NETWORK_DRIVER={{DOCKER_NETWORK_DRIVER}}
DOCKER_NETWORK_SUBNET={{DOCKER_NETWORK_SUBNET}}

# Security
FIREWALL_ENABLED={{FIREWALL_ENABLED}}
VPN_ENCRYPTION=AES-256-GCM

# Monitoring
VPN_LOG_LEVEL=info
VPN_METRICS_ENABLED=true
VPN_METRICS_PORT=9586

# High Availability (for production)
VPN_HA_ENABLED=false
VPN_BACKUP_SERVER=
VPN_FAILOVER_TIMEOUT=30

EOFENV

    # Replace placeholders
    sed -i "s/{{VPN_PROTOCOL}}/$VPN_PROTOCOL/g" "$ENV_FILE"
    sed -i "s/{{VPN_PROVIDER}}/$VPN_PROVIDER/g" "$ENV_FILE"
    sed -i "s/{{VPN_INTERFACE}}/$VPN_INTERFACE/g" "$ENV_FILE"
    sed -i "s/{{VPN_PORT}}/$VPN_PORT/g" "$ENV_FILE"
    sed -i "s/{{VPN_CIDR}}/$VPN_CIDR/g" "$ENV_FILE"
    sed -i "s/{{VPN_ENDPOINT}}/$VPN_ENDPOINT/g" "$ENV_FILE"
    sed -i "s/{{DNS_SERVERS}}/$DNS_SERVERS/g" "$ENV_FILE"
    sed -i "s/{{VPN_KEEPALIVE}}/$VPN_KEEPALIVE/g" "$ENV_FILE"
    sed -i "s/{{VPN_KEY_BITS}}/$VPN_KEY_BITS/g" "$ENV_FILE"
    sed -i "s/{{DOCKER_NETWORK_NAME}}/$DOCKER_NETWORK_NAME/g" "$ENV_FILE"
    sed -i "s/{{DOCKER_NETWORK_DRIVER}}/$DOCKER_NETWORK_DRIVER/g" "$ENV_FILE"
    sed -i "s/{{DOCKER_NETWORK_SUBNET}}/$DOCKER_NETWORK_SUBNET/g" "$ENV_FILE"
    sed -i "s/{{FIREWALL_ENABLED}}/$FIREWALL_ENABLED/g" "$ENV_FILE"

    verify_file "$ENV_FILE"
    log_file_created "$SCRIPT_NAME" ".env.vpn"
    CREATED_FILES+=(".env.vpn")
fi

# ===================================================================
# Create Monitoring & Logging Documentation
# ===================================================================

log_info "Creating monitoring documentation..."

MONITORING_DOC="$PROJECT_ROOT/config/network/vpn/MONITORING.md"

if file_exists "$MONITORING_DOC"; then
    backup_file "$MONITORING_DOC"
    SKIPPED_FILES+=("config/network/vpn/MONITORING.md (backed up)")
else
    cat > "$MONITORING_DOC" << 'EOFMON'
# VPN Monitoring & Logging

## WireGuard Monitoring

### Check VPN Status
```bash
# Show all peers and connection status
wg show

# Show specific interface
wg show {{VPN_INTERFACE}}

# Show latest handshakes (connections)
wg show {{VPN_INTERFACE}} latest-handshakes
```

### Connection Metrics
```bash
# Transfer statistics
wg show {{VPN_INTERFACE}} transfer

# Peer details
wg show {{VPN_INTERFACE}} peers
```

### Logging
WireGuard logs to kernel messages:
```bash
# View WireGuard logs
journalctl -u wg-quick@{{VPN_INTERFACE}} -f

# Kernel logs
dmesg | grep wireguard
```

## Prometheus Metrics (Optional)

Install WireGuard exporter:
```bash
# Using wireguard_exporter
docker run -d \
  --name wireguard-exporter \
  --net=host \
  --cap-add=NET_ADMIN \
  mindflavor/prometheus-wireguard-exporter
```

Metrics available at: `http://localhost:9586/metrics`

## Grafana Dashboard

Import dashboard ID: 11568 (WireGuard Dashboard)

Key metrics:
- Peer connection status
- Data transfer (bytes in/out)
- Latest handshake time
- Number of active peers

## Alerting

### Connection Failures
Monitor for peers with no recent handshake:
```promql
time() - wireguard_latest_handshake_seconds > 300
```

### High Traffic
Alert on unusual bandwidth:
```promql
rate(wireguard_sent_bytes_total[5m]) > 100000000
```

## Log Aggregation

Ship logs to centralized system:
```bash
# Using fluentd/fluent-bit
# Configure to read journalctl logs
# Send to Elasticsearch, Loki, or CloudWatch
```

## Security Monitoring

### Failed Connection Attempts
```bash
# Check for dropped packets
iptables -L -v -n | grep {{VPN_PORT}}

# Monitor auth failures
journalctl -u wg-quick@{{VPN_INTERFACE}} | grep -i "fail\|error\|deny"
```

### Traffic Analysis
```bash
# Use tcpdump on VPN interface
tcpdump -i {{VPN_INTERFACE}} -n -c 100

# Analyze with Wireshark
tcpdump -i {{VPN_INTERFACE}} -w /tmp/vpn-capture.pcap
```

## Health Checks

### Automated Health Check Script
```bash
#!/bin/bash
# Check if VPN is running and has active peers

ACTIVE_PEERS=$(wg show {{VPN_INTERFACE}} peers | wc -l)

if [ $ACTIVE_PEERS -eq 0 ]; then
    echo "WARNING: No active VPN peers"
    exit 1
fi

echo "OK: $ACTIVE_PEERS active peers"
exit 0
```

## Performance Monitoring

### Bandwidth Usage
```bash
# Install vnstat
vnstat -i {{VPN_INTERFACE}}

# Real-time monitoring
iftop -i {{VPN_INTERFACE}}
```

### Latency Testing
```bash
# Ping through VPN
ping -I {{VPN_INTERFACE}} 8.8.8.8

# MTR trace
mtr -i {{VPN_INTERFACE}} 8.8.8.8
```

EOFMON

    sed -i "s/{{VPN_INTERFACE}}/$VPN_INTERFACE/g" "$MONITORING_DOC"
    sed -i "s/{{VPN_PORT}}/$VPN_PORT/g" "$MONITORING_DOC"

    verify_file "$MONITORING_DOC"
    log_file_created "$SCRIPT_NAME" "config/network/vpn/MONITORING.md"
    CREATED_FILES+=("config/network/vpn/MONITORING.md")
fi

# ===================================================================
# Display Created Files
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#CREATED_FILES[@]} files created"

echo ""
log_section "VPN & Network Bootstrap Complete"

echo -e "${GREEN}✓ Created Files:${NC}"
for file in "${CREATED_FILES[@]}"; do
    echo "  • $file"
done

if [[ ${#SKIPPED_FILES[@]} -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}⚠ Skipped Files (already existed):${NC}"
    for file in "${SKIPPED_FILES[@]}"; do
        echo "  • $file"
    done
fi

# ===================================================================
# Summary
# ===================================================================

echo ""
echo -e "${BLUE}VPN Configuration:${NC}"
echo "  Protocol: $VPN_PROTOCOL"
echo "  Network: $VPN_CIDR"
echo "  Port: $VPN_PORT"
echo "  Interface: $VPN_INTERFACE"
echo "  Peers: $PEER_COUNT"
echo ""

echo -e "${BLUE}Docker Network:${NC}"
echo "  Name: $DOCKER_NETWORK_NAME"
echo "  Driver: $DOCKER_NETWORK_DRIVER"
echo "  Subnet: $DOCKER_NETWORK_SUBNET"
echo ""

echo -e "${BLUE}Quick Start:${NC}"
echo "  1. Generate VPN keys:"
echo "     bash config/network/vpn/generate-keys.sh"
echo ""
echo "  2. Review and customize configuration:"
echo "     nano config/network/vpn/${VPN_PROTOCOL}-config.conf"
echo ""

if [[ "$VPN_PROTOCOL" == "wireguard" ]]; then
    echo "  3. Start WireGuard VPN:"
    echo "     sudo wg-quick up $VPN_INTERFACE"
    echo ""
    echo "  4. Check status:"
    echo "     sudo wg show"
    echo ""
    echo "  5. Enable at boot:"
    echo "     sudo systemctl enable wg-quick@${VPN_INTERFACE}"
else
    echo "  3. Set up OpenVPN PKI:"
    echo "     Follow guide in config/network/vpn/${VPN_PROTOCOL}-config.conf"
    echo ""
    echo "  4. Start OpenVPN server:"
    echo "     sudo openvpn --config config/network/vpn/${VPN_PROTOCOL}-config.conf"
fi

echo ""
echo "  Docker Network:"
echo "    docker-compose -f config/network/vpn/docker-network.yml up -d"
echo ""

if [[ "$FIREWALL_ENABLED" == "true" ]]; then
    echo "  Firewall Rules (review before applying):"
    echo "    sudo bash config/network/vpn/iptables-rules.conf"
    echo ""
fi

echo -e "${BLUE}Files Created:${NC}"
echo "  Network: ${#CREATED_FILES[@]} files"
echo "  Location: $PROJECT_ROOT/config/network/vpn/"
echo ""

if [[ "$PROJECT_TIER" == "prod" ]] || [[ "$PROJECT_TIER" == "production" ]]; then
    echo -e "${YELLOW}Production Security Checklist:${NC}"
    echo "  • Set VPN_ENDPOINT in .env.vpn to your public IP/domain"
    echo "  • Generate strong keys (bash config/network/vpn/generate-keys.sh)"
    echo "  • Review and apply iptables rules"
    echo "  • Enable kernel IP forwarding: sysctl -w net.ipv4.ip_forward=1"
    echo "  • Configure monitoring (see config/network/vpn/MONITORING.md)"
    echo "  • Set up log rotation for VPN logs"
    echo "  • Enable fail2ban for rate limiting"
    echo "  • Document disaster recovery procedures"
else
    echo -e "${YELLOW}Development Notes:${NC}"
    echo "  • VPN_ENDPOINT not set - update in .env.vpn for peer connections"
    echo "  • Default credentials used - change for production"
    echo "  • Firewall rules provided but not auto-applied"
fi

echo ""
echo -e "${BLUE}Service Mesh Integration:${NC}"
echo "  For production, consider adding:"
echo "  • Istio: Full-featured service mesh with mTLS"
echo "  • Linkerd: Lightweight service mesh"
echo "  • Consul Connect: Service discovery + secure networking"
echo "  See config/network/vpn/docker-network.yml for details"
echo ""

show_log_location
