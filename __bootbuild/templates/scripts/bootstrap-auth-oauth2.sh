#!/bin/bash
# =============================================================================
# @script         bootstrap-auth-oauth2
# @version        1.0.0
# @phase          4
# @category       security
# @priority       60
#
# @short          OAuth2 authentication provider setup
# @description    OAuth2 authentication provider setup with file tracking.
#                 Configures OAuth2/OIDC providers (Keycloak, Auth0, Okta)
#                 including realm export, environment files, and Docker configs.
#
# @creates        config/oauth2/
# @creates        config/oauth2/oauth2-config.json
# @creates        config/oauth2/realm-export.json
# @creates        .env.oauth2
# @creates        docker-compose.oauth2.yml
#
# @depends        project
#
# @requires       tool:docker
# @requires       tool:openssl
#
# @detects        has_oauth2
# @questions      none
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
#
# @config_section  oauth2
# @env_vars        ADMIN_TOKEN,AUTH0_DOMAIN,BLUE,CREATED_FILES,DOCKER_COMPOSE_FILE,ENABLED,ENV_FILE,FILES_TO_CREATE,GREEN,NC,OAUTH2_ADMIN_PASSWORD,OAUTH2_ADMIN_USER,OAUTH2_CLIENT_ID,OAUTH2_CLIENT_SECRET,OAUTH2_CONFIG_FILE,OAUTH2_ISSUER_URL,OAUTH2_PORT,OAUTH2_PROVIDER,OAUTH2_REALM,OAUTH2_REDIRECT_URIS,OAUTH2_SCOPES,OAUTH2_VERSION,OAUTH2_WEB_ORIGINS,OKTA_DOMAIN,README_FILE,REALM_EXPORT_FILE,REDIRECT_URIS_JSON,SCOPES_JSON,SESSION_SECRET,SKIPPED_FILES,WEB_ORIGINS_JSON,YELLOW
# @interactive     no
# @platforms       all
# @conflicts       none
# @rollback        rm -rf config/oauth2/ config/oauth2/oauth2-config.json config/oauth2/realm-export.json .env.oauth2 docker-compose.oauth2.yml
# @verify          test -f config/oauth2/
# @docs            https://oauth.net/2/
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

# Initialize script
init_script "bootstrap-auth-oauth2"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-auth-oauth2"

# Track created files for display
declare -a CREATED_FILES=()
declare -a SKIPPED_FILES=()

# ===================================================================
# Read Configuration
# ===================================================================

# Check if this bootstrap should run
ENABLED=$(config_get "oauth2.enabled" "true")
if [[ "$ENABLED" != "true" ]]; then
    log_info "OAuth2 bootstrap disabled in config"
    exit 0
fi

# Read OAuth2-specific settings
OAUTH2_PROVIDER=$(config_get "oauth2.provider" "keycloak")
OAUTH2_VERSION=$(config_get "oauth2.version" "latest")
OAUTH2_REALM=$(config_get "oauth2.realm" "master")
OAUTH2_CLIENT_ID=$(config_get "oauth2.client_id" "app-client")
OAUTH2_CLIENT_SECRET=$(config_get "oauth2.client_secret" "$(openssl rand -hex 32 2>/dev/null || echo 'change-me-in-production')")
OAUTH2_PORT=$(config_get "oauth2.port" "8080")
OAUTH2_ADMIN_USER=$(config_get "oauth2.admin_user" "admin")
OAUTH2_ADMIN_PASSWORD=$(config_get "oauth2.admin_password" "admin")
OAUTH2_REDIRECT_URIS=$(config_get "oauth2.redirect_uris" "http://localhost:3000/callback,http://localhost:3000/api/auth/callback")
OAUTH2_WEB_ORIGINS=$(config_get "oauth2.web_origins" "http://localhost:3000")
OAUTH2_SCOPES=$(config_get "oauth2.scopes" "openid,profile,email")

# Get project name for Docker
PROJECT_NAME=$(config_get "project.name" "app")

# Construct issuer URL based on provider
case "$OAUTH2_PROVIDER" in
    keycloak)
        OAUTH2_ISSUER_URL="http://localhost:${OAUTH2_PORT}/realms/${OAUTH2_REALM}"
        ;;
    auth0)
        OAUTH2_ISSUER_URL="https://\${AUTH0_DOMAIN}"
        ;;
    okta)
        OAUTH2_ISSUER_URL="https://\${OKTA_DOMAIN}/oauth2/default"
        ;;
    *)
        OAUTH2_ISSUER_URL="http://localhost:${OAUTH2_PORT}"
        ;;
esac

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

FILES_TO_CREATE=(
    "config/oauth2/"
    "config/oauth2/oauth2-config.json"
    "config/oauth2/realm-export.json"
    ".env.oauth2"
    "docker-compose.oauth2.yml"
)

pre_execution_confirm "$SCRIPT_NAME" "OAuth2 Authentication Configuration" \
    "${FILES_TO_CREATE[@]}"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check if project directory exists
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"

# Check if we can write to project
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

log_success "Environment validated"

# ===================================================================
# Create OAuth2 Directory Structure
# ===================================================================

log_info "Creating OAuth2 directory structure..."

if ! dir_exists "$PROJECT_ROOT/config/oauth2"; then
    ensure_dir "$PROJECT_ROOT/config/oauth2"
    log_dir_created "$SCRIPT_NAME" "config/oauth2/"
fi

log_success "Directory structure created"

# ===================================================================
# Create OAuth2 Configuration File
# ===================================================================

log_info "Creating OAuth2 configuration file..."

OAUTH2_CONFIG_FILE="$PROJECT_ROOT/config/oauth2/oauth2-config.json"

if file_exists "$OAUTH2_CONFIG_FILE"; then
    backup_file "$OAUTH2_CONFIG_FILE"
    SKIPPED_FILES+=("config/oauth2/oauth2-config.json (backed up)")
    log_warning "oauth2-config.json already exists, backed up"
else
    cat > "$OAUTH2_CONFIG_FILE" << 'EOFCONFIG'
{
  "provider": "{{OAUTH2_PROVIDER}}",
  "issuerUrl": "{{OAUTH2_ISSUER_URL}}",
  "authorizationEndpoint": "{{OAUTH2_ISSUER_URL}}/protocol/openid-connect/auth",
  "tokenEndpoint": "{{OAUTH2_ISSUER_URL}}/protocol/openid-connect/token",
  "userInfoEndpoint": "{{OAUTH2_ISSUER_URL}}/protocol/openid-connect/userinfo",
  "jwksUri": "{{OAUTH2_ISSUER_URL}}/protocol/openid-connect/certs",
  "endSessionEndpoint": "{{OAUTH2_ISSUER_URL}}/protocol/openid-connect/logout",
  "clientId": "{{OAUTH2_CLIENT_ID}}",
  "clientSecret": "{{OAUTH2_CLIENT_SECRET}}",
  "redirectUris": [
    {{OAUTH2_REDIRECT_URIS_JSON}}
  ],
  "webOrigins": [
    {{OAUTH2_WEB_ORIGINS_JSON}}
  ],
  "scopes": [
    {{OAUTH2_SCOPES_JSON}}
  ],
  "responseType": "code",
  "grantTypes": [
    "authorization_code",
    "refresh_token"
  ],
  "tokenEndpointAuthMethod": "client_secret_basic",
  "pkceEnabled": true,
  "pkceMethod": "S256"
}
EOFCONFIG

    # Convert comma-separated lists to JSON arrays
    REDIRECT_URIS_JSON=$(echo "$OAUTH2_REDIRECT_URIS" | sed 's/,/", "/g' | sed 's/^/"/' | sed 's/$/"/')
    WEB_ORIGINS_JSON=$(echo "$OAUTH2_WEB_ORIGINS" | sed 's/,/", "/g' | sed 's/^/"/' | sed 's/$/"/')
    SCOPES_JSON=$(echo "$OAUTH2_SCOPES" | sed 's/,/", "/g' | sed 's/^/"/' | sed 's/$/"/')

    # Replace placeholders
    sed -i "s|{{OAUTH2_PROVIDER}}|$OAUTH2_PROVIDER|g" "$OAUTH2_CONFIG_FILE"
    sed -i "s|{{OAUTH2_ISSUER_URL}}|$OAUTH2_ISSUER_URL|g" "$OAUTH2_CONFIG_FILE"
    sed -i "s|{{OAUTH2_CLIENT_ID}}|$OAUTH2_CLIENT_ID|g" "$OAUTH2_CONFIG_FILE"
    sed -i "s|{{OAUTH2_CLIENT_SECRET}}|$OAUTH2_CLIENT_SECRET|g" "$OAUTH2_CONFIG_FILE"
    sed -i "s|{{OAUTH2_REDIRECT_URIS_JSON}}|$REDIRECT_URIS_JSON|g" "$OAUTH2_CONFIG_FILE"
    sed -i "s|{{OAUTH2_WEB_ORIGINS_JSON}}|$WEB_ORIGINS_JSON|g" "$OAUTH2_CONFIG_FILE"
    sed -i "s|{{OAUTH2_SCOPES_JSON}}|$SCOPES_JSON|g" "$OAUTH2_CONFIG_FILE"

    verify_file "$OAUTH2_CONFIG_FILE"
    log_file_created "$SCRIPT_NAME" "config/oauth2/oauth2-config.json"
    CREATED_FILES+=("config/oauth2/oauth2-config.json")
fi

# ===================================================================
# Create Keycloak Realm Export (if provider is Keycloak)
# ===================================================================

if [[ "$OAUTH2_PROVIDER" == "keycloak" ]]; then
    log_info "Creating Keycloak realm export template..."

    REALM_EXPORT_FILE="$PROJECT_ROOT/config/oauth2/realm-export.json"

    if file_exists "$REALM_EXPORT_FILE"; then
        backup_file "$REALM_EXPORT_FILE"
        SKIPPED_FILES+=("config/oauth2/realm-export.json (backed up)")
        log_warning "realm-export.json already exists, backed up"
    else
        cat > "$REALM_EXPORT_FILE" << 'EOFREALM'
{
  "realm": "{{OAUTH2_REALM}}",
  "enabled": true,
  "sslRequired": "external",
  "registrationAllowed": false,
  "loginWithEmailAllowed": true,
  "duplicateEmailsAllowed": false,
  "resetPasswordAllowed": true,
  "editUsernameAllowed": false,
  "bruteForceProtected": true,
  "permanentLockout": false,
  "maxFailureWaitSeconds": 900,
  "minimumQuickLoginWaitSeconds": 60,
  "waitIncrementSeconds": 60,
  "quickLoginCheckMilliSeconds": 1000,
  "maxDeltaTimeSeconds": 43200,
  "failureFactor": 5,
  "defaultSignatureAlgorithm": "RS256",
  "offlineSessionMaxLifespan": 5184000,
  "offlineSessionMaxLifespanEnabled": false,
  "accessTokenLifespan": 300,
  "accessTokenLifespanForImplicitFlow": 900,
  "ssoSessionIdleTimeout": 1800,
  "ssoSessionMaxLifespan": 36000,
  "clients": [
    {
      "clientId": "{{OAUTH2_CLIENT_ID}}",
      "enabled": true,
      "protocol": "openid-connect",
      "publicClient": false,
      "bearerOnly": false,
      "consentRequired": false,
      "standardFlowEnabled": true,
      "implicitFlowEnabled": false,
      "directAccessGrantsEnabled": true,
      "serviceAccountsEnabled": false,
      "authorizationServicesEnabled": false,
      "redirectUris": [
        {{OAUTH2_REDIRECT_URIS_JSON}}
      ],
      "webOrigins": [
        {{OAUTH2_WEB_ORIGINS_JSON}}
      ],
      "secret": "{{OAUTH2_CLIENT_SECRET}}",
      "attributes": {
        "pkce.code.challenge.method": "S256"
      },
      "protocolMappers": [
        {
          "name": "email",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usermodel-property-mapper",
          "consentRequired": false,
          "config": {
            "userinfo.token.claim": "true",
            "user.attribute": "email",
            "id.token.claim": "true",
            "access.token.claim": "true",
            "claim.name": "email",
            "jsonType.label": "String"
          }
        },
        {
          "name": "username",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usermodel-property-mapper",
          "consentRequired": false,
          "config": {
            "userinfo.token.claim": "true",
            "user.attribute": "username",
            "id.token.claim": "true",
            "access.token.claim": "true",
            "claim.name": "preferred_username",
            "jsonType.label": "String"
          }
        },
        {
          "name": "profile",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usermodel-attribute-mapper",
          "consentRequired": false,
          "config": {
            "userinfo.token.claim": "true",
            "user.attribute": "profile",
            "id.token.claim": "true",
            "access.token.claim": "true",
            "claim.name": "profile",
            "jsonType.label": "String"
          }
        }
      ]
    }
  ],
  "roles": {
    "realm": [
      {
        "name": "user",
        "description": "Standard user role"
      },
      {
        "name": "admin",
        "description": "Administrator role"
      }
    ]
  },
  "defaultRoles": ["user"],
  "users": []
}
EOFREALM

        # Convert comma-separated lists to JSON arrays
        REDIRECT_URIS_JSON=$(echo "$OAUTH2_REDIRECT_URIS" | sed 's/,/", "/g' | sed 's/^/"/' | sed 's/$/"/')
        WEB_ORIGINS_JSON=$(echo "$OAUTH2_WEB_ORIGINS" | sed 's/,/", "/g' | sed 's/^/"/' | sed 's/$/"/')

        # Replace placeholders
        sed -i "s|{{OAUTH2_REALM}}|$OAUTH2_REALM|g" "$REALM_EXPORT_FILE"
        sed -i "s|{{OAUTH2_CLIENT_ID}}|$OAUTH2_CLIENT_ID|g" "$REALM_EXPORT_FILE"
        sed -i "s|{{OAUTH2_CLIENT_SECRET}}|$OAUTH2_CLIENT_SECRET|g" "$REALM_EXPORT_FILE"
        sed -i "s|{{OAUTH2_REDIRECT_URIS_JSON}}|$REDIRECT_URIS_JSON|g" "$REALM_EXPORT_FILE"
        sed -i "s|{{OAUTH2_WEB_ORIGINS_JSON}}|$WEB_ORIGINS_JSON|g" "$REALM_EXPORT_FILE"

        verify_file "$REALM_EXPORT_FILE"
        log_file_created "$SCRIPT_NAME" "config/oauth2/realm-export.json"
        CREATED_FILES+=("config/oauth2/realm-export.json")
    fi
fi

# ===================================================================
# Create Environment File
# ===================================================================

log_info "Creating OAuth2 environment configuration..."

ENV_FILE="$PROJECT_ROOT/.env.oauth2"

if file_exists "$ENV_FILE"; then
    backup_file "$ENV_FILE"
    SKIPPED_FILES+=(".env.oauth2 (backed up)")
    log_warning ".env.oauth2 already exists, backed up"
else
    cat > "$ENV_FILE" << 'EOFENV'
# ===================================================================
# OAuth2 Authentication Environment Configuration
# Auto-generated by bootstrap-auth-oauth2.sh
# ===================================================================

# OAuth2 Provider Configuration
OAUTH2_PROVIDER={{OAUTH2_PROVIDER}}
OAUTH2_ISSUER_URL={{OAUTH2_ISSUER_URL}}
OAUTH2_CLIENT_ID={{OAUTH2_CLIENT_ID}}
OAUTH2_CLIENT_SECRET={{OAUTH2_CLIENT_SECRET}}

# OAuth2 Endpoints (for Keycloak)
OAUTH2_AUTHORIZATION_URL={{OAUTH2_ISSUER_URL}}/protocol/openid-connect/auth
OAUTH2_TOKEN_URL={{OAUTH2_ISSUER_URL}}/protocol/openid-connect/token
OAUTH2_USERINFO_URL={{OAUTH2_ISSUER_URL}}/protocol/openid-connect/userinfo
OAUTH2_JWKS_URI={{OAUTH2_ISSUER_URL}}/protocol/openid-connect/certs
OAUTH2_LOGOUT_URL={{OAUTH2_ISSUER_URL}}/protocol/openid-connect/logout

# OAuth2 Redirect & CORS Configuration
OAUTH2_REDIRECT_URI=http://localhost:3000/callback
OAUTH2_POST_LOGOUT_REDIRECT_URI=http://localhost:3000
OAUTH2_WEB_ORIGINS={{OAUTH2_WEB_ORIGINS}}

# OAuth2 Scopes
OAUTH2_SCOPES={{OAUTH2_SCOPES}}

# OAuth2 Security
OAUTH2_PKCE_ENABLED=true
OAUTH2_PKCE_METHOD=S256
OAUTH2_STATE_COOKIE_NAME=oauth2_state
OAUTH2_SESSION_COOKIE_NAME=oauth2_session

# Session Configuration
SESSION_SECRET={{SESSION_SECRET}}
SESSION_MAX_AGE=86400000
SESSION_SECURE=false
SESSION_HTTP_ONLY=true
SESSION_SAME_SITE=lax

# Token Configuration
ACCESS_TOKEN_LIFETIME=300
REFRESH_TOKEN_LIFETIME=2592000
ID_TOKEN_LIFETIME=300

# Keycloak Admin (for development only)
KEYCLOAK_ADMIN={{OAUTH2_ADMIN_USER}}
KEYCLOAK_ADMIN_PASSWORD={{OAUTH2_ADMIN_PASSWORD}}

# Keycloak Database (internal)
KC_DB=postgres
KC_DB_URL_HOST=postgres
KC_DB_URL_DATABASE={{PROJECT_NAME}}_keycloak
KC_DB_USERNAME=keycloak
KC_DB_PASSWORD=keycloak

# Security Headers
OAUTH2_VALIDATE_ISSUER=true
OAUTH2_VALIDATE_AUDIENCE=true
OAUTH2_REQUIRE_HTTPS=false

# Logging
OAUTH2_LOG_LEVEL=info
OAUTH2_DEBUG=false
EOFENV

    # Generate a random session secret
    SESSION_SECRET=$(openssl rand -hex 32 2>/dev/null || echo 'change-me-in-production-to-random-string')

    # Replace placeholders
    sed -i "s|{{OAUTH2_PROVIDER}}|$OAUTH2_PROVIDER|g" "$ENV_FILE"
    sed -i "s|{{OAUTH2_ISSUER_URL}}|$OAUTH2_ISSUER_URL|g" "$ENV_FILE"
    sed -i "s|{{OAUTH2_CLIENT_ID}}|$OAUTH2_CLIENT_ID|g" "$ENV_FILE"
    sed -i "s|{{OAUTH2_CLIENT_SECRET}}|$OAUTH2_CLIENT_SECRET|g" "$ENV_FILE"
    sed -i "s|{{OAUTH2_ADMIN_USER}}|$OAUTH2_ADMIN_USER|g" "$ENV_FILE"
    sed -i "s|{{OAUTH2_ADMIN_PASSWORD}}|$OAUTH2_ADMIN_PASSWORD|g" "$ENV_FILE"
    sed -i "s|{{OAUTH2_WEB_ORIGINS}}|$OAUTH2_WEB_ORIGINS|g" "$ENV_FILE"
    sed -i "s|{{OAUTH2_SCOPES}}|$OAUTH2_SCOPES|g" "$ENV_FILE"
    sed -i "s|{{SESSION_SECRET}}|$SESSION_SECRET|g" "$ENV_FILE"
    sed -i "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" "$ENV_FILE"

    verify_file "$ENV_FILE"
    log_file_created "$SCRIPT_NAME" ".env.oauth2"
    CREATED_FILES+=(".env.oauth2")
fi

# ===================================================================
# Create Docker Compose Configuration (Keycloak)
# ===================================================================

if [[ "$OAUTH2_PROVIDER" == "keycloak" ]]; then
    log_info "Creating Docker Compose configuration for Keycloak..."

    DOCKER_COMPOSE_FILE="$PROJECT_ROOT/docker-compose.oauth2.yml"

    if file_exists "$DOCKER_COMPOSE_FILE"; then
        backup_file "$DOCKER_COMPOSE_FILE"
        SKIPPED_FILES+=("docker-compose.oauth2.yml (backed up)")
        log_warning "docker-compose.oauth2.yml already exists, backed up"
    else
        cat > "$DOCKER_COMPOSE_FILE" << 'EOFDOCKER'
version: '3.8'

services:
  keycloak:
    image: quay.io/keycloak/keycloak:{{OAUTH2_VERSION}}
    container_name: {{PROJECT_NAME}}-keycloak
    command: start-dev --import-realm
    environment:
      # Admin credentials
      KEYCLOAK_ADMIN: {{OAUTH2_ADMIN_USER}}
      KEYCLOAK_ADMIN_PASSWORD: {{OAUTH2_ADMIN_PASSWORD}}

      # Database configuration
      KC_DB: postgres
      KC_DB_URL_HOST: postgres
      KC_DB_URL_DATABASE: {{PROJECT_NAME}}_keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: keycloak
      KC_DB_SCHEMA: public

      # Hostname configuration
      KC_HOSTNAME_STRICT: false
      KC_HOSTNAME_STRICT_HTTPS: false
      KC_HTTP_ENABLED: true

      # Proxy configuration
      KC_PROXY: edge

      # Health check
      KC_HEALTH_ENABLED: true
      KC_METRICS_ENABLED: true
    ports:
      - "{{OAUTH2_PORT}}:8080"
      - "8443:8443"
    volumes:
      - keycloak_data:/opt/keycloak/data
      - ./config/oauth2/realm-export.json:/opt/keycloak/data/import/realm-export.json:ro
    depends_on:
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "exec 3<>/dev/tcp/127.0.0.1/8080 && echo -e 'GET /health/ready HTTP/1.1\\r\\nhost: 127.0.0.1\\r\\nConnection: close\\r\\n\\r\\n' >&3 && cat <&3 | grep -q '200 OK'"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 60s
    networks:
      - {{PROJECT_NAME}}-net
    restart: unless-stopped

  postgres:
    image: postgres:15-alpine
    container_name: {{PROJECT_NAME}}-keycloak-postgres
    environment:
      POSTGRES_DB: {{PROJECT_NAME}}_keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: keycloak
    volumes:
      - postgres_keycloak_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U keycloak -d {{PROJECT_NAME}}_keycloak"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - {{PROJECT_NAME}}-net
    restart: unless-stopped

volumes:
  keycloak_data:
    driver: local
  postgres_keycloak_data:
    driver: local

networks:
  {{PROJECT_NAME}}-net:
    driver: bridge
EOFDOCKER

        # Replace placeholders
        sed -i "s|{{OAUTH2_VERSION}}|$OAUTH2_VERSION|g" "$DOCKER_COMPOSE_FILE"
        sed -i "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" "$DOCKER_COMPOSE_FILE"
        sed -i "s|{{OAUTH2_ADMIN_USER}}|$OAUTH2_ADMIN_USER|g" "$DOCKER_COMPOSE_FILE"
        sed -i "s|{{OAUTH2_ADMIN_PASSWORD}}|$OAUTH2_ADMIN_PASSWORD|g" "$DOCKER_COMPOSE_FILE"
        sed -i "s|{{OAUTH2_PORT}}|$OAUTH2_PORT|g" "$DOCKER_COMPOSE_FILE"

        verify_file "$DOCKER_COMPOSE_FILE"
        log_file_created "$SCRIPT_NAME" "docker-compose.oauth2.yml"
        CREATED_FILES+=("docker-compose.oauth2.yml")
    fi
fi

# ===================================================================
# Create README Documentation
# ===================================================================

log_info "Creating OAuth2 setup documentation..."

README_FILE="$PROJECT_ROOT/config/oauth2/README.md"

if file_exists "$README_FILE"; then
    backup_file "$README_FILE"
    SKIPPED_FILES+=("config/oauth2/README.md (backed up)")
    log_warning "README.md already exists, backed up"
else
    cat > "$README_FILE" << 'EOFREADME'
# OAuth2 Authentication Setup

Auto-generated by `bootstrap-auth-oauth2.sh`

## Provider: {{OAUTH2_PROVIDER}}

### Quick Start

1. **Start the OAuth2 provider:**
   ```bash
   docker-compose -f docker-compose.oauth2.yml up -d
   ```

2. **Wait for Keycloak to be ready (first start takes ~60s):**
   ```bash
   docker-compose -f docker-compose.oauth2.yml logs -f keycloak
   # Wait for "Keycloak ... started in ..."
   ```

3. **Access Keycloak Admin Console:**
   - URL: http://localhost:{{OAUTH2_PORT}}/admin
   - Username: `{{OAUTH2_ADMIN_USER}}`
   - Password: `{{OAUTH2_ADMIN_PASSWORD}}`

4. **Verify realm import:**
   - Navigate to realm dropdown (top-left)
   - Select "{{OAUTH2_REALM}}" realm
   - Go to Clients → "{{OAUTH2_CLIENT_ID}}"
   - Verify redirect URIs and web origins

### Configuration Files

- **oauth2-config.json** - OAuth2 client configuration (use in your app)
- **realm-export.json** - Keycloak realm template (imported on startup)
- **.env.oauth2** - Environment variables for Docker & app

### Application Integration

#### Environment Variables

Load `.env.oauth2` in your application:

```javascript
// Node.js example
import dotenv from 'dotenv';
dotenv.config({ path: '.env.oauth2' });

const oauth2Config = {
  issuerUrl: process.env.OAUTH2_ISSUER_URL,
  clientId: process.env.OAUTH2_CLIENT_ID,
  clientSecret: process.env.OAUTH2_CLIENT_SECRET,
  redirectUri: process.env.OAUTH2_REDIRECT_URI,
  scopes: process.env.OAUTH2_SCOPES.split(',')
};
```

#### Authorization Code Flow (with PKCE)

1. **Generate PKCE verifier and challenge:**
   ```javascript
   const codeVerifier = generateRandomString(128);
   const codeChallenge = base64UrlEncode(sha256(codeVerifier));
   ```

2. **Redirect to authorization endpoint:**
   ```javascript
   const authUrl = new URL(process.env.OAUTH2_AUTHORIZATION_URL);
   authUrl.searchParams.set('client_id', process.env.OAUTH2_CLIENT_ID);
   authUrl.searchParams.set('redirect_uri', process.env.OAUTH2_REDIRECT_URI);
   authUrl.searchParams.set('response_type', 'code');
   authUrl.searchParams.set('scope', process.env.OAUTH2_SCOPES);
   authUrl.searchParams.set('code_challenge', codeChallenge);
   authUrl.searchParams.set('code_challenge_method', 'S256');

   res.redirect(authUrl.toString());
   ```

3. **Exchange code for tokens:**
   ```javascript
   const tokenResponse = await fetch(process.env.OAUTH2_TOKEN_URL, {
     method: 'POST',
     headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
     body: new URLSearchParams({
       grant_type: 'authorization_code',
       code: authorizationCode,
       redirect_uri: process.env.OAUTH2_REDIRECT_URI,
       client_id: process.env.OAUTH2_CLIENT_ID,
       client_secret: process.env.OAUTH2_CLIENT_SECRET,
       code_verifier: codeVerifier
     })
   });

   const tokens = await tokenResponse.json();
   // tokens.access_token, tokens.id_token, tokens.refresh_token
   ```

4. **Validate and decode JWT:**
   ```javascript
   import jwt from 'jsonwebtoken';
   import jwksClient from 'jwks-rsa';

   const client = jwksClient({ jwksUri: process.env.OAUTH2_JWKS_URI });
   const getKey = (header, callback) => {
     client.getSigningKey(header.kid, (err, key) => {
       callback(null, key.getPublicKey());
     });
   };

   jwt.verify(tokens.id_token, getKey, { algorithms: ['RS256'] }, (err, decoded) => {
     if (err) throw err;
     // decoded.sub = user ID
     // decoded.email = user email
     // decoded.preferred_username = username
   });
   ```

### Endpoints

- **Authorization:** `{{OAUTH2_ISSUER_URL}}/protocol/openid-connect/auth`
- **Token:** `{{OAUTH2_ISSUER_URL}}/protocol/openid-connect/token`
- **UserInfo:** `{{OAUTH2_ISSUER_URL}}/protocol/openid-connect/userinfo`
- **JWKS:** `{{OAUTH2_ISSUER_URL}}/protocol/openid-connect/certs`
- **Logout:** `{{OAUTH2_ISSUER_URL}}/protocol/openid-connect/logout`

### Security Best Practices

1. **Change default passwords** in `.env.oauth2`:
   - `OAUTH2_CLIENT_SECRET`
   - `KEYCLOAK_ADMIN_PASSWORD`
   - `SESSION_SECRET`

2. **Enable HTTPS in production:**
   - Set `OAUTH2_REQUIRE_HTTPS=true`
   - Set `SESSION_SECURE=true`
   - Configure reverse proxy (nginx/traefik)

3. **Use PKCE** (enabled by default):
   - Protects against authorization code interception

4. **Validate tokens:**
   - Always verify JWT signature against JWKS
   - Check `iss` (issuer) claim
   - Check `aud` (audience) claim
   - Check `exp` (expiration) claim

5. **Store tokens securely:**
   - Use httpOnly, secure, sameSite cookies
   - Never expose tokens in URLs
   - Implement proper logout

### Creating Test Users

**Via Keycloak Admin Console:**
1. Navigate to Users → Add User
2. Fill in username, email, first/last name
3. Save user
4. Go to Credentials tab
5. Set temporary password
6. Disable "Temporary" if desired

**Via REST API:**
```bash
# Get admin token
ADMIN_TOKEN=$(curl -X POST "http://localhost:{{OAUTH2_PORT}}/realms/master/protocol/openid-connect/token" \
  -d "client_id=admin-cli" \
  -d "username={{OAUTH2_ADMIN_USER}}" \
  -d "password={{OAUTH2_ADMIN_PASSWORD}}" \
  -d "grant_type=password" | jq -r '.access_token')

# Create user
curl -X POST "http://localhost:{{OAUTH2_PORT}}/admin/realms/{{OAUTH2_REALM}}/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "enabled": true,
    "credentials": [{
      "type": "password",
      "value": "password123",
      "temporary": false
    }]
  }'
```

### Troubleshooting

**Keycloak won't start:**
- Check logs: `docker-compose -f docker-compose.oauth2.yml logs keycloak`
- Ensure PostgreSQL is healthy: `docker-compose -f docker-compose.oauth2.yml ps`
- Wait for health check (can take 60s on first start)

**Invalid redirect URI:**
- Verify redirect URIs in Keycloak client settings
- Must match exactly (including trailing slash)
- Check CORS settings (Web Origins)

**Token validation fails:**
- Ensure JWKS URI is accessible
- Verify issuer URL matches token `iss` claim
- Check system clock synchronization

**Session issues:**
- Verify `SESSION_SECRET` is set and random
- Check cookie settings (secure, httpOnly, sameSite)
- Ensure same domain for app and cookies

### Useful Commands

```bash
# View Keycloak logs
docker-compose -f docker-compose.oauth2.yml logs -f keycloak

# Restart Keycloak
docker-compose -f docker-compose.oauth2.yml restart keycloak

# Access Keycloak shell
docker-compose -f docker-compose.oauth2.yml exec keycloak /bin/bash

# Export realm configuration
docker-compose -f docker-compose.oauth2.yml exec keycloak \
  /opt/keycloak/bin/kc.sh export --realm {{OAUTH2_REALM}} --file /tmp/realm-export.json

# Import realm configuration
docker-compose -f docker-compose.oauth2.yml exec keycloak \
  /opt/keycloak/bin/kc.sh import --file /tmp/realm-export.json

# Stop and remove all data
docker-compose -f docker-compose.oauth2.yml down -v
```

## Production Deployment Notes

### Phase 4: CI/CD & Deployment Considerations

1. **Secrets Management:**
   - Use secrets manager (AWS Secrets Manager, HashiCorp Vault)
   - Inject secrets at runtime, never commit to git
   - Rotate secrets regularly

2. **High Availability:**
   - Run multiple Keycloak replicas
   - Use external PostgreSQL cluster (RDS, Cloud SQL)
   - Configure health checks and auto-scaling

3. **SSL/TLS:**
   - Terminate SSL at load balancer or reverse proxy
   - Configure `KC_PROXY=edge` for X-Forwarded headers
   - Use valid SSL certificates (Let's Encrypt, ACM)

4. **Monitoring:**
   - Enable Keycloak metrics: `KC_METRICS_ENABLED=true`
   - Monitor login success/failure rates
   - Alert on unusual patterns

5. **Backup & Recovery:**
   - Regular PostgreSQL backups
   - Export realm configuration periodically
   - Test restore procedures

6. **Network Security:**
   - Use internal networking for Keycloak ↔ PostgreSQL
   - Restrict admin console access (IP whitelist, VPN)
   - Enable rate limiting on auth endpoints

---

**Generated:** {{DATE}}
**Provider:** {{OAUTH2_PROVIDER}}
**Realm:** {{OAUTH2_REALM}}
**Client ID:** {{OAUTH2_CLIENT_ID}}
EOFREADME

    # Replace placeholders
    sed -i "s|{{OAUTH2_PROVIDER}}|$OAUTH2_PROVIDER|g" "$README_FILE"
    sed -i "s|{{OAUTH2_PORT}}|$OAUTH2_PORT|g" "$README_FILE"
    sed -i "s|{{OAUTH2_ADMIN_USER}}|$OAUTH2_ADMIN_USER|g" "$README_FILE"
    sed -i "s|{{OAUTH2_ADMIN_PASSWORD}}|$OAUTH2_ADMIN_PASSWORD|g" "$README_FILE"
    sed -i "s|{{OAUTH2_REALM}}|$OAUTH2_REALM|g" "$README_FILE"
    sed -i "s|{{OAUTH2_CLIENT_ID}}|$OAUTH2_CLIENT_ID|g" "$README_FILE"
    sed -i "s|{{OAUTH2_ISSUER_URL}}|$OAUTH2_ISSUER_URL|g" "$README_FILE"
    sed -i "s|{{DATE}}|$(date +%Y-%m-%d)|g" "$README_FILE"

    verify_file "$README_FILE"
    log_file_created "$SCRIPT_NAME" "config/oauth2/README.md"
    CREATED_FILES+=("config/oauth2/README.md")
fi

# ===================================================================
# Display Created Files
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#CREATED_FILES[@]} files created"

echo ""
log_section "OAuth2 Bootstrap Complete"

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
echo -e "${BLUE}OAuth2 Configuration:${NC}"
echo "  Provider: $OAUTH2_PROVIDER"
echo "  Issuer URL: $OAUTH2_ISSUER_URL"
echo "  Client ID: $OAUTH2_CLIENT_ID"
echo "  Realm: $OAUTH2_REALM"
echo "  Port: $OAUTH2_PORT"
echo ""

if [[ "$OAUTH2_PROVIDER" == "keycloak" ]]; then
    echo -e "${BLUE}Quick Start:${NC}"
    echo "  1. Start Keycloak container:"
    echo "     docker-compose -f docker-compose.oauth2.yml up -d"
    echo ""
    echo "  2. Wait for startup (check logs):"
    echo "     docker-compose -f docker-compose.oauth2.yml logs -f keycloak"
    echo ""
    echo "  3. Access Admin Console:"
    echo "     http://localhost:$OAUTH2_PORT/admin"
    echo "     Username: $OAUTH2_ADMIN_USER"
    echo "     Password: $OAUTH2_ADMIN_PASSWORD"
    echo ""
    echo "  4. View documentation:"
    echo "     cat config/oauth2/README.md"
    echo ""
fi

echo -e "${BLUE}Files Created:${NC}"
echo "  Configuration: ${#CREATED_FILES[@]} files"
echo "  Location: $PROJECT_ROOT"
echo ""

echo -e "${YELLOW}Security Reminder:${NC}"
echo "  • Change OAUTH2_CLIENT_SECRET in .env.oauth2 (current: ${OAUTH2_CLIENT_SECRET:0:8}...)"
echo "  • Change KEYCLOAK_ADMIN_PASSWORD in .env.oauth2 (current: $OAUTH2_ADMIN_PASSWORD)"
echo "  • Never commit .env.oauth2 to git"
echo "  • Enable HTTPS for production"
echo "  • Use secure session secrets"
echo ""

show_log_location
