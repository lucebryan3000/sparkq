#!/bin/bash
# =============================================================================
# @script         bootstrap-email-service
# @version        1.0.0
# @phase          5
# @category       config
# @priority       50
# @short          Email service integration setup
# @description    Sets up email service integration with provider configuration
#                 (SendGrid, AWS SES, etc), Handlebars email templates,
#                 template layouts, Redis queue support, and rate limiting
#                 for email delivery.
#
# @creates        config/email/email-provider.config.json
# @creates        config/email/templates/welcome.hbs
# @creates        config/email/templates/password-reset.hbs
# @creates        .env.email
#
# @detects        has_email-provider.config
# @questions      none
# @defaults       EMAIL_PROVIDER=sendgrid, EMAIL_QUEUE_ENABLED=true
# @detects        has_email-provider.config
# @questions      none
# @defaults       TEMPLATE_ENGINE=handlebars, RATE_LIMIT_PER_HOUR=100
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
#
# @config_section  email
# @env_vars        AWS_ACCESS_KEY_ID,AWS_REGION,AWS_SECRET_ACCESS_KEY,BLUE,CREATED_FILES,EMAIL_API_KEY,EMAIL_FROM_ADDRESS,EMAIL_FROM_NAME,EMAIL_PROVIDER,EMAIL_QUEUE_ENABLED,EMAIL_QUEUE_SERVICE,ENABLED,ENV_FILE,FILES_TO_CREATE,GREEN,LAYOUT_TEMPLATE,MAILGUN_DOMAIN,NC,NOTIFICATION_TEMPLATE,PROVIDER_CONFIG,RATE_LIMIT_PER_HOUR,REDIS_HOST,REDIS_PASSWORD,REDIS_PORT,RESET_TEMPLATE,SKIPPED_FILES,SMTP_HOST,SMTP_PASSWORD,SMTP_PORT,SMTP_USER,WELCOME_TEMPLATE,YELLOW
# @interactive     no
# @platforms       all
# @conflicts       none
# @rollback        rm -rf config/email/email-provider.config.json config/email/templates/welcome.hbs config/email/templates/password-reset.hbs .env.email
# @verify          test -f config/email/email-provider.config.json
# @docs            https://nodemailer.com/about/
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
init_script "bootstrap-email-service"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-email-service"

# Track created files for display
declare -a CREATED_FILES=()
declare -a SKIPPED_FILES=()

# ===================================================================
# Read Configuration
# ===================================================================

# Check if this bootstrap should run
ENABLED=$(config_get "email.enabled" "true")
if [[ "$ENABLED" != "true" ]]; then
    log_info "Email service bootstrap disabled in config"
    exit 0
fi

# Read email-specific settings
EMAIL_PROVIDER=$(config_get "email.provider" "sendgrid")
EMAIL_API_KEY=$(config_get "email.api_key" "your-api-key-here")
EMAIL_FROM_ADDRESS=$(config_get "email.from_address" "noreply@example.com")
EMAIL_FROM_NAME=$(config_get "email.from_name" "App Notifications")
SMTP_HOST=$(config_get "email.smtp_host" "smtp.gmail.com")
SMTP_PORT=$(config_get "email.smtp_port" "587")
SMTP_USER=$(config_get "email.smtp_user" "")
SMTP_PASSWORD=$(config_get "email.smtp_password" "")
EMAIL_QUEUE_ENABLED=$(config_get "email.queue_enabled" "true")
EMAIL_QUEUE_SERVICE=$(config_get "email.queue_service" "redis")
TEMPLATE_ENGINE=$(config_get "email.template_engine" "handlebars")
RATE_LIMIT_PER_HOUR=$(config_get "email.rate_limit_per_hour" "100")

# Get project name
PROJECT_NAME=$(config_get "project.name" "app")

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

FILES_TO_CREATE=(
    "config/email/"
    "config/email/email-provider.config.json"
    "config/email/templates/"
    "config/email/templates/welcome.hbs"
    "config/email/templates/password-reset.hbs"
    "config/email/templates/notification.hbs"
    "config/email/templates/layouts/base.hbs"
    ".env.email"
)

pre_execution_confirm "$SCRIPT_NAME" "Email Service Configuration" \
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
# Create Email Directory Structure
# ===================================================================

log_info "Creating email service directory structure..."

if ! dir_exists "$PROJECT_ROOT/config/email"; then
    ensure_dir "$PROJECT_ROOT/config/email"
    log_dir_created "$SCRIPT_NAME" "config/email/"
fi

if ! dir_exists "$PROJECT_ROOT/config/email/templates"; then
    ensure_dir "$PROJECT_ROOT/config/email/templates"
    log_dir_created "$SCRIPT_NAME" "config/email/templates/"
fi

if ! dir_exists "$PROJECT_ROOT/config/email/templates/layouts"; then
    ensure_dir "$PROJECT_ROOT/config/email/templates/layouts"
    log_dir_created "$SCRIPT_NAME" "config/email/templates/layouts/"
fi

log_success "Directory structure created"

# ===================================================================
# Create Email Provider Configuration
# ===================================================================

log_info "Creating email provider configuration..."

PROVIDER_CONFIG="$PROJECT_ROOT/config/email/email-provider.config.json"

if file_exists "$PROVIDER_CONFIG"; then
    backup_file "$PROVIDER_CONFIG"
    SKIPPED_FILES+=("config/email/email-provider.config.json (backed up)")
    log_warning "email-provider.config.json already exists, backed up"
else
    cat > "$PROVIDER_CONFIG" << 'EOFPROVIDER'
{
  "provider": "{{EMAIL_PROVIDER}}",
  "from": {
    "email": "{{EMAIL_FROM_ADDRESS}}",
    "name": "{{EMAIL_FROM_NAME}}"
  },
  "providers": {
    "sendgrid": {
      "apiKey": "${EMAIL_API_KEY}",
      "endpoint": "https://api.sendgrid.com/v3/mail/send"
    },
    "mailgun": {
      "apiKey": "${EMAIL_API_KEY}",
      "domain": "${MAILGUN_DOMAIN}",
      "endpoint": "https://api.mailgun.net/v3"
    },
    "smtp": {
      "host": "{{SMTP_HOST}}",
      "port": {{SMTP_PORT}},
      "secure": true,
      "auth": {
        "user": "${SMTP_USER}",
        "pass": "${SMTP_PASSWORD}"
      }
    },
    "ses": {
      "region": "${AWS_REGION}",
      "accessKeyId": "${AWS_ACCESS_KEY_ID}",
      "secretAccessKey": "${AWS_SECRET_ACCESS_KEY}"
    }
  },
  "templates": {
    "engine": "{{TEMPLATE_ENGINE}}",
    "directory": "./config/email/templates",
    "layoutsDirectory": "./config/email/templates/layouts",
    "partialsDirectory": "./config/email/templates/partials",
    "defaultLayout": "base",
    "cache": true
  },
  "queue": {
    "enabled": {{EMAIL_QUEUE_ENABLED}},
    "service": "{{EMAIL_QUEUE_SERVICE}}",
    "redis": {
      "host": "${REDIS_HOST:-localhost}",
      "port": "${REDIS_PORT:-6379}",
      "password": "${REDIS_PASSWORD}",
      "db": 2
    },
    "options": {
      "attempts": 3,
      "backoff": {
        "type": "exponential",
        "delay": 5000
      },
      "removeOnComplete": true,
      "removeOnFail": false
    }
  },
  "rateLimiting": {
    "enabled": true,
    "maxPerHour": {{RATE_LIMIT_PER_HOUR}},
    "strategy": "sliding-window"
  },
  "retry": {
    "enabled": true,
    "maxAttempts": 3,
    "initialDelay": 1000,
    "maxDelay": 60000,
    "backoffMultiplier": 2
  },
  "tracking": {
    "opens": false,
    "clicks": false,
    "deliveryStatus": true
  },
  "healthCheck": {
    "enabled": true,
    "endpoint": "/health/email",
    "interval": 60000
  }
}
EOFPROVIDER

    # Replace placeholders
    sed -i "s/{{EMAIL_PROVIDER}}/$EMAIL_PROVIDER/g" "$PROVIDER_CONFIG"
    sed -i "s/{{EMAIL_FROM_ADDRESS}}/$EMAIL_FROM_ADDRESS/g" "$PROVIDER_CONFIG"
    sed -i "s/{{EMAIL_FROM_NAME}}/$EMAIL_FROM_NAME/g" "$PROVIDER_CONFIG"
    sed -i "s/{{SMTP_HOST}}/$SMTP_HOST/g" "$PROVIDER_CONFIG"
    sed -i "s/{{SMTP_PORT}}/$SMTP_PORT/g" "$PROVIDER_CONFIG"
    sed -i "s/{{TEMPLATE_ENGINE}}/$TEMPLATE_ENGINE/g" "$PROVIDER_CONFIG"
    sed -i "s/{{EMAIL_QUEUE_ENABLED}}/$EMAIL_QUEUE_ENABLED/g" "$PROVIDER_CONFIG"
    sed -i "s/{{EMAIL_QUEUE_SERVICE}}/$EMAIL_QUEUE_SERVICE/g" "$PROVIDER_CONFIG"
    sed -i "s/{{RATE_LIMIT_PER_HOUR}}/$RATE_LIMIT_PER_HOUR/g" "$PROVIDER_CONFIG"

    verify_file "$PROVIDER_CONFIG"
    log_file_created "$SCRIPT_NAME" "config/email/email-provider.config.json"
    CREATED_FILES+=("config/email/email-provider.config.json")
fi

# ===================================================================
# Create Email Templates
# ===================================================================

log_info "Creating email templates..."

# Base Layout Template
LAYOUT_TEMPLATE="$PROJECT_ROOT/config/email/templates/layouts/base.hbs"

if file_exists "$LAYOUT_TEMPLATE"; then
    backup_file "$LAYOUT_TEMPLATE"
    SKIPPED_FILES+=("config/email/templates/layouts/base.hbs (backed up)")
    log_warning "base.hbs layout already exists, backed up"
else
    cat > "$LAYOUT_TEMPLATE" << 'EOFLAYOUT'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{subject}}</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .email-container {
            background-color: #ffffff;
            border-radius: 8px;
            padding: 40px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #f0f0f0;
        }
        .logo {
            font-size: 24px;
            font-weight: bold;
            color: #2563eb;
        }
        .content {
            margin: 20px 0;
        }
        .button {
            display: inline-block;
            padding: 12px 24px;
            background-color: #2563eb;
            color: #ffffff;
            text-decoration: none;
            border-radius: 6px;
            margin: 20px 0;
        }
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #e5e5e5;
            text-align: center;
            font-size: 12px;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <div class="logo">{{appName}}</div>
        </div>
        <div class="content">
            {{{body}}}
        </div>
        <div class="footer">
            <p>&copy; {{year}} {{appName}}. All rights reserved.</p>
            <p>
                <a href="{{unsubscribeUrl}}" style="color: #666;">Unsubscribe</a> |
                <a href="{{preferencesUrl}}" style="color: #666;">Preferences</a>
            </p>
        </div>
    </div>
</body>
</html>
EOFLAYOUT

    verify_file "$LAYOUT_TEMPLATE"
    log_file_created "$SCRIPT_NAME" "config/email/templates/layouts/base.hbs"
    CREATED_FILES+=("config/email/templates/layouts/base.hbs")
fi

# Welcome Email Template
WELCOME_TEMPLATE="$PROJECT_ROOT/config/email/templates/welcome.hbs"

if file_exists "$WELCOME_TEMPLATE"; then
    backup_file "$WELCOME_TEMPLATE"
    SKIPPED_FILES+=("config/email/templates/welcome.hbs (backed up)")
    log_warning "welcome.hbs already exists, backed up"
else
    cat > "$WELCOME_TEMPLATE" << 'EOFWELCOME'
<h1>Welcome to {{appName}}, {{userName}}!</h1>

<p>Thank you for joining us. We're excited to have you on board!</p>

<p>Your account has been successfully created with the email address: <strong>{{userEmail}}</strong></p>

<h2>Getting Started</h2>
<ul>
    <li>Complete your profile to get personalized recommendations</li>
    <li>Explore our features and discover what we can do for you</li>
    <li>Join our community and connect with other users</li>
</ul>

<p style="text-align: center;">
    <a href="{{dashboardUrl}}" class="button">Go to Dashboard</a>
</p>

<p>If you have any questions, feel free to reach out to our support team.</p>

<p>Best regards,<br>The {{appName}} Team</p>
EOFWELCOME

    verify_file "$WELCOME_TEMPLATE"
    log_file_created "$SCRIPT_NAME" "config/email/templates/welcome.hbs"
    CREATED_FILES+=("config/email/templates/welcome.hbs")
fi

# Password Reset Template
RESET_TEMPLATE="$PROJECT_ROOT/config/email/templates/password-reset.hbs"

if file_exists "$RESET_TEMPLATE"; then
    backup_file "$RESET_TEMPLATE"
    SKIPPED_FILES+=("config/email/templates/password-reset.hbs (backed up)")
    log_warning "password-reset.hbs already exists, backed up"
else
    cat > "$RESET_TEMPLATE" << 'EOFRESET'
<h1>Password Reset Request</h1>

<p>Hi {{userName}},</p>

<p>We received a request to reset your password for your {{appName}} account.</p>

<p>Click the button below to reset your password. This link will expire in <strong>{{expiryMinutes}} minutes</strong>.</p>

<p style="text-align: center;">
    <a href="{{resetUrl}}" class="button">Reset Password</a>
</p>

<p>Or copy and paste this URL into your browser:</p>
<p style="word-break: break-all; color: #666;">{{resetUrl}}</p>

<p><strong>If you didn't request this password reset, you can safely ignore this email.</strong> Your password will remain unchanged.</p>

<h3>Security Tips</h3>
<ul>
    <li>Never share your password with anyone</li>
    <li>Use a unique password for each account</li>
    <li>Enable two-factor authentication for added security</li>
</ul>

<p>Best regards,<br>The {{appName}} Team</p>
EOFRESET

    verify_file "$RESET_TEMPLATE"
    log_file_created "$SCRIPT_NAME" "config/email/templates/password-reset.hbs"
    CREATED_FILES+=("config/email/templates/password-reset.hbs")
fi

# Notification Template
NOTIFICATION_TEMPLATE="$PROJECT_ROOT/config/email/templates/notification.hbs"

if file_exists "$NOTIFICATION_TEMPLATE"; then
    backup_file "$NOTIFICATION_TEMPLATE"
    SKIPPED_FILES+=("config/email/templates/notification.hbs (backed up)")
    log_warning "notification.hbs already exists, backed up"
else
    cat > "$NOTIFICATION_TEMPLATE" << 'EOFNOTIFICATION'
<h1>{{notificationTitle}}</h1>

<p>Hi {{userName}},</p>

<p>{{notificationMessage}}</p>

{{#if actionUrl}}
<p style="text-align: center;">
    <a href="{{actionUrl}}" class="button">{{actionText}}</a>
</p>
{{/if}}

{{#if additionalInfo}}
<div style="background-color: #f9fafb; padding: 15px; border-radius: 6px; margin: 20px 0;">
    <p style="margin: 0;"><strong>Additional Information:</strong></p>
    <p style="margin: 10px 0 0 0;">{{additionalInfo}}</p>
</div>
{{/if}}

{{#if timestamp}}
<p style="font-size: 12px; color: #666;">This notification was sent on {{timestamp}}</p>
{{/if}}

<p>Best regards,<br>The {{appName}} Team</p>
EOFNOTIFICATION

    verify_file "$NOTIFICATION_TEMPLATE"
    log_file_created "$SCRIPT_NAME" "config/email/templates/notification.hbs"
    CREATED_FILES+=("config/email/templates/notification.hbs")
fi

# ===================================================================
# Create Environment File
# ===================================================================

log_info "Creating email service environment configuration..."

ENV_FILE="$PROJECT_ROOT/.env.email"

if file_exists "$ENV_FILE"; then
    backup_file "$ENV_FILE"
    SKIPPED_FILES+=(".env.email (backed up)")
    log_warning ".env.email already exists, backed up"
else
    cat > "$ENV_FILE" << 'EOFENV'
# ===================================================================
# Email Service Environment Configuration
# Auto-generated by bootstrap-email-service.sh
# ===================================================================

# Email Provider Configuration
EMAIL_PROVIDER={{EMAIL_PROVIDER}}
EMAIL_API_KEY={{EMAIL_API_KEY}}
EMAIL_FROM_ADDRESS={{EMAIL_FROM_ADDRESS}}
EMAIL_FROM_NAME="{{EMAIL_FROM_NAME}}"

# SMTP Configuration (if using SMTP provider)
SMTP_HOST={{SMTP_HOST}}
SMTP_PORT={{SMTP_PORT}}
SMTP_USER={{SMTP_USER}}
SMTP_PASSWORD={{SMTP_PASSWORD}}
SMTP_SECURE=true

# AWS SES Configuration (if using SES provider)
# AWS_REGION=us-east-1
# AWS_ACCESS_KEY_ID=your-access-key
# AWS_SECRET_ACCESS_KEY=your-secret-key

# Mailgun Configuration (if using Mailgun provider)
# MAILGUN_DOMAIN=mg.example.com
# MAILGUN_API_KEY=your-mailgun-api-key

# Queue Configuration
EMAIL_QUEUE_ENABLED={{EMAIL_QUEUE_ENABLED}}
EMAIL_QUEUE_SERVICE={{EMAIL_QUEUE_SERVICE}}
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# Template Engine
TEMPLATE_ENGINE={{TEMPLATE_ENGINE}}

# Rate Limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_PER_HOUR={{RATE_LIMIT_PER_HOUR}}

# Retry Configuration
RETRY_MAX_ATTEMPTS=3
RETRY_INITIAL_DELAY=1000
RETRY_MAX_DELAY=60000

# Tracking
EMAIL_TRACK_OPENS=false
EMAIL_TRACK_CLICKS=false
EMAIL_TRACK_DELIVERY=true

# Health Check
EMAIL_HEALTH_CHECK_ENABLED=true
EMAIL_HEALTH_CHECK_INTERVAL=60000

# Application Context
APP_NAME={{PROJECT_NAME}}
APP_URL=http://localhost:3000
DASHBOARD_URL=http://localhost:3000/dashboard
UNSUBSCRIBE_URL=http://localhost:3000/unsubscribe
PREFERENCES_URL=http://localhost:3000/preferences

# Development/Debug
EMAIL_DEBUG=false
EMAIL_DRY_RUN=false
EOFENV

    # Replace placeholders
    sed -i "s/{{EMAIL_PROVIDER}}/$EMAIL_PROVIDER/g" "$ENV_FILE"
    sed -i "s/{{EMAIL_API_KEY}}/$EMAIL_API_KEY/g" "$ENV_FILE"
    sed -i "s/{{EMAIL_FROM_ADDRESS}}/$EMAIL_FROM_ADDRESS/g" "$ENV_FILE"
    sed -i "s/{{EMAIL_FROM_NAME}}/$EMAIL_FROM_NAME/g" "$ENV_FILE"
    sed -i "s/{{SMTP_HOST}}/$SMTP_HOST/g" "$ENV_FILE"
    sed -i "s/{{SMTP_PORT}}/$SMTP_PORT/g" "$ENV_FILE"
    sed -i "s/{{SMTP_USER}}/$SMTP_USER/g" "$ENV_FILE"
    sed -i "s/{{SMTP_PASSWORD}}/$SMTP_PASSWORD/g" "$ENV_FILE"
    sed -i "s/{{EMAIL_QUEUE_ENABLED}}/$EMAIL_QUEUE_ENABLED/g" "$ENV_FILE"
    sed -i "s/{{EMAIL_QUEUE_SERVICE}}/$EMAIL_QUEUE_SERVICE/g" "$ENV_FILE"
    sed -i "s/{{TEMPLATE_ENGINE}}/$TEMPLATE_ENGINE/g" "$ENV_FILE"
    sed -i "s/{{RATE_LIMIT_PER_HOUR}}/$RATE_LIMIT_PER_HOUR/g" "$ENV_FILE"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$ENV_FILE"

    verify_file "$ENV_FILE"
    log_file_created "$SCRIPT_NAME" ".env.email"
    CREATED_FILES+=(".env.email")
fi

# ===================================================================
# Display Created Files
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#CREATED_FILES[@]} files created"

echo ""
log_section "Email Service Bootstrap Complete"

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
echo -e "${BLUE}Email Service Configuration:${NC}"
echo "  Provider: $EMAIL_PROVIDER"
echo "  From Address: $EMAIL_FROM_ADDRESS"
echo "  From Name: $EMAIL_FROM_NAME"
echo "  Template Engine: $TEMPLATE_ENGINE"
echo "  Queue Enabled: $EMAIL_QUEUE_ENABLED"
echo "  Rate Limit: $RATE_LIMIT_PER_HOUR emails/hour"
echo ""

echo -e "${BLUE}Available Templates:${NC}"
echo "  • welcome.hbs - New user welcome email"
echo "  • password-reset.hbs - Password reset request"
echo "  • notification.hbs - General notifications"
echo ""

echo -e "${BLUE}Integration Examples:${NC}"
case "$EMAIL_PROVIDER" in
    sendgrid)
        echo "  SendGrid API integration configured"
        echo "  Set EMAIL_API_KEY in .env.email or environment"
        ;;
    mailgun)
        echo "  Mailgun API integration configured"
        echo "  Set EMAIL_API_KEY and MAILGUN_DOMAIN in .env.email"
        ;;
    smtp)
        echo "  SMTP integration configured"
        echo "  Host: $SMTP_HOST:$SMTP_PORT"
        echo "  Set SMTP_USER and SMTP_PASSWORD in .env.email"
        ;;
    ses)
        echo "  AWS SES integration configured"
        echo "  Set AWS credentials in .env.email"
        ;;
esac
echo ""

if [[ "$EMAIL_QUEUE_ENABLED" == "true" ]]; then
    echo -e "${BLUE}Queue Configuration:${NC}"
    echo "  Service: $EMAIL_QUEUE_SERVICE"
    if [[ "$EMAIL_QUEUE_SERVICE" == "redis" ]]; then
        echo "  Ensure Redis is running and accessible"
        echo "  Configure REDIS_HOST and REDIS_PORT in .env.email"
    fi
    echo ""
fi

echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Update credentials in .env.email"
echo "  2. Install email provider SDK (npm install @sendgrid/mail, nodemailer, etc.)"
echo "  3. Install template engine (npm install handlebars)"
if [[ "$EMAIL_QUEUE_ENABLED" == "true" ]]; then
    echo "  4. Install queue library (npm install bull redis)"
    echo "  5. Start Redis service"
fi
echo "  6. Test email sending with your provider"
echo ""

echo -e "${YELLOW}Security Reminder:${NC}"
echo "  • Never commit .env.email to git"
echo "  • Use environment variables in production"
echo "  • Rotate API keys regularly"
echo "  • Enable DKIM/SPF for better deliverability"
echo "  • Monitor rate limits to avoid provider throttling"
echo ""

show_log_location
