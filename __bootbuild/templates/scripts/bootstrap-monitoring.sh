#!/bin/bash
# =============================================================================
# @script         bootstrap-monitoring
# @version        1.0.0
# @phase          5
# @category       config
# @priority       50
# @short          Observability and monitoring setup
# @description    Configures monitoring and observability with Sentry for error
#                 tracking, Prometheus for metrics, Datadog and New Relic
#                 integration options, and alert configuration.
#
# @creates        .sentryrc
# @creates        prometheus.yml
# @creates        monitoring/alerts/alerts.yml
# @creates        datadog.yaml
# @creates        newrelic.js
# @creates        .env.monitoring
#
# @detects        has_monitoring_config
# @questions      monitoring
# @defaults       monitoring.enabled=true, monitoring.sentry_enabled=true
# @detects        has_monitoring_config
# @questions      monitoring
# @defaults       monitoring.prometheus_enabled=true
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
#
# @config_section  monitoring
# @env_vars        APP_PORT,DATADOG_API_KEY,DATADOG_APM_ENABLED,DATADOG_APM_SAMPLE_RATE,DATADOG_APP_KEY,DATADOG_LOGS_ENABLED,DATADOG_NETWORK_ENABLED,DATADOG_PROCESS_ENABLED,DATADOG_SITE,ENABLED,ENABLE_DATADOG,ENABLE_NEWRELIC,ENABLE_PROMETHEUS,ENABLE_SENTRY,ENVIRONMENT,FILES_TO_CREATE,NEWRELIC_APP_LOGGING,NEWRELIC_BROWSER_MONITORING,NEWRELIC_DISTRIBUTED_TRACING,NEWRELIC_ERROR_COLLECTOR,NEWRELIC_LICENSE_KEY,NEWRELIC_LOG_DECORATING,NEWRELIC_LOG_FORWARDING,NEWRELIC_LOG_LEVEL,NEWRELIC_LOG_METRICS,NEWRELIC_SLOW_SQL,NEWRELIC_TRANSACTION_TRACER,PROMETHEUS_EVAL_INTERVAL,PROMETHEUS_SCRAPE_INTERVAL,SENTRY_AUTH_TOKEN,SENTRY_DSN,SENTRY_ORG,SENTRY_PROJECT,SENTRY_TRACES_SAMPLE_RATE,SENTRY_URL,TEAM_NAME,VERSION
# @interactive     no
# @platforms       all
# @conflicts       none
# @rollback        rm -rf .sentryrc prometheus.yml monitoring/alerts/alerts.yml datadog.yaml newrelic.js .env.monitoring
# @verify          test -f .sentryrc
# @docs            https://prometheus.io/docs/
# =============================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-monitoring"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-monitoring"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "" \
    --scripts "" \
    --optional "curl jq"


# ===================================================================
# Read Configuration
# ===================================================================

# Check if this bootstrap should run
ENABLED=$(config_get "monitoring.enabled" "true")
if [[ "$ENABLED" != "true" ]]; then
    log_info "Monitoring bootstrap disabled in config"
    exit 0
fi

# Read monitoring provider settings
ENABLE_SENTRY=$(config_get "monitoring.sentry_enabled" "true")
ENABLE_PROMETHEUS=$(config_get "monitoring.prometheus_enabled" "true")
ENABLE_DATADOG=$(config_get "monitoring.datadog_enabled" "false")
ENABLE_NEWRELIC=$(config_get "monitoring.newrelic_enabled" "false")

# Read configuration values
PROJECT_NAME=$(config_get "project.name" "myproject")
ENVIRONMENT=$(config_get "monitoring.environment" "development")
TEAM_NAME=$(config_get "monitoring.team_name" "engineering")
APP_PORT=$(config_get "monitoring.app_port" "3000")

# Sentry configuration
SENTRY_DSN=$(config_get "monitoring.sentry_dsn" "")
SENTRY_ORG=$(config_get "monitoring.sentry_org" "")
SENTRY_PROJECT=$(config_get "monitoring.sentry_project" "$PROJECT_NAME")
SENTRY_AUTH_TOKEN=$(config_get "monitoring.sentry_auth_token" "")
SENTRY_URL=$(config_get "monitoring.sentry_url" "https://sentry.io/")
SENTRY_TRACES_SAMPLE_RATE=$(config_get "monitoring.sentry_traces_sample_rate" "0.1")

# Datadog configuration
DATADOG_API_KEY=$(config_get "monitoring.datadog_api_key" "")
DATADOG_APP_KEY=$(config_get "monitoring.datadog_app_key" "")
DATADOG_SITE=$(config_get "monitoring.datadog_site" "datadoghq.com")
DATADOG_LOGS_ENABLED=$(config_get "monitoring.datadog_logs_enabled" "true")
DATADOG_APM_ENABLED=$(config_get "monitoring.datadog_apm_enabled" "true")
DATADOG_APM_SAMPLE_RATE=$(config_get "monitoring.datadog_apm_sample_rate" "1.0")
DATADOG_PROCESS_ENABLED=$(config_get "monitoring.datadog_process_enabled" "false")
DATADOG_NETWORK_ENABLED=$(config_get "monitoring.datadog_network_enabled" "false")

# New Relic configuration
NEWRELIC_LICENSE_KEY=$(config_get "monitoring.newrelic_license_key" "")
NEWRELIC_LOG_LEVEL=$(config_get "monitoring.newrelic_log_level" "info")
NEWRELIC_TRANSACTION_TRACER=$(config_get "monitoring.newrelic_transaction_tracer" "true")
NEWRELIC_ERROR_COLLECTOR=$(config_get "monitoring.newrelic_error_collector" "true")
NEWRELIC_DISTRIBUTED_TRACING=$(config_get "monitoring.newrelic_distributed_tracing" "true")
NEWRELIC_SLOW_SQL=$(config_get "monitoring.newrelic_slow_sql" "true")
NEWRELIC_BROWSER_MONITORING=$(config_get "monitoring.newrelic_browser_monitoring" "false")
NEWRELIC_APP_LOGGING=$(config_get "monitoring.newrelic_app_logging" "true")
NEWRELIC_LOG_FORWARDING=$(config_get "monitoring.newrelic_log_forwarding" "true")
NEWRELIC_LOG_METRICS=$(config_get "monitoring.newrelic_log_metrics" "true")
NEWRELIC_LOG_DECORATING=$(config_get "monitoring.newrelic_log_decorating" "true")

# Prometheus configuration
PROMETHEUS_SCRAPE_INTERVAL=$(config_get "monitoring.prometheus_scrape_interval" "15s")
PROMETHEUS_EVAL_INTERVAL=$(config_get "monitoring.prometheus_eval_interval" "15s")

# Version for tracking
VERSION=$(config_get "project.version" "1.0.0")

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

# Build list of files to create based on enabled providers
FILES_TO_CREATE=()

if [[ "$ENABLE_SENTRY" == "true" ]]; then
    FILES_TO_CREATE+=(".sentryrc")
fi

if [[ "$ENABLE_PROMETHEUS" == "true" ]]; then
    FILES_TO_CREATE+=("prometheus.yml" "alerts.yml" "monitoring/ (directory)")
fi

if [[ "$ENABLE_DATADOG" == "true" ]]; then
    FILES_TO_CREATE+=("datadog.yaml")
fi

if [[ "$ENABLE_NEWRELIC" == "true" ]]; then
    FILES_TO_CREATE+=("newrelic.js")
fi

FILES_TO_CREATE+=(".env.monitoring")

pre_execution_confirm "$SCRIPT_NAME" "Monitoring Configuration" \
    "${FILES_TO_CREATE[@]}"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check if project directory exists
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"

# Check if we can write to project
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Validate provider-specific requirements
if [[ "$ENABLE_SENTRY" == "true" && -z "$SENTRY_DSN" ]]; then
    track_warning "Sentry enabled but SENTRY_DSN not configured"
    log_warning "Sentry enabled but SENTRY_DSN not configured in bootstrap.config"
    log_info "You'll need to add your DSN to .env.monitoring after setup"
fi

if [[ "$ENABLE_DATADOG" == "true" && -z "$DATADOG_API_KEY" ]]; then
    track_warning "Datadog enabled but API key not configured"
    log_warning "Datadog enabled but DATADOG_API_KEY not configured in bootstrap.config"
    log_info "You'll need to add your API key to .env.monitoring after setup"
fi

if [[ "$ENABLE_NEWRELIC" == "true" && -z "$NEWRELIC_LICENSE_KEY" ]]; then
    track_warning "New Relic enabled but license key not configured"
    log_warning "New Relic enabled but NEWRELIC_LICENSE_KEY not configured in bootstrap.config"
    log_info "You'll need to add your license key to .env.monitoring after setup"
fi

log_success "Environment validated"

# ===================================================================
# Create Monitoring Directory
# ===================================================================

if [[ "$ENABLE_PROMETHEUS" == "true" ]]; then
    log_info "Creating monitoring directory structure..."

    ensure_dir "$PROJECT_ROOT/monitoring"
    log_dir_created "$SCRIPT_NAME" "monitoring/"

    ensure_dir "$PROJECT_ROOT/monitoring/alerts"
    log_dir_created "$SCRIPT_NAME" "monitoring/alerts/"
fi

# ===================================================================
# Create Sentry Configuration
# ===================================================================

if [[ "$ENABLE_SENTRY" == "true" ]]; then
    log_info "Creating Sentry configuration..."

    if file_exists "$PROJECT_ROOT/.sentryrc"; then
        backup_file "$PROJECT_ROOT/.sentryrc"
        track_skipped ".sentryrc (backed up)"
        log_warning ".sentryrc already exists, backed up"
    else
        copy_template "root/monitoring/.sentryrc" "$PROJECT_ROOT/.sentryrc"

        # Replace placeholders
        source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
        replace_in_file "$PROJECT_ROOT/.sentryrc" "{{SENTRY_URL}}" "$SENTRY_URL"
        replace_in_file "$PROJECT_ROOT/.sentryrc" "{{SENTRY_ORG}}" "$SENTRY_ORG"
        replace_in_file "$PROJECT_ROOT/.sentryrc" "{{SENTRY_PROJECT}}" "$SENTRY_PROJECT"
        replace_in_file "$PROJECT_ROOT/.sentryrc" "{{SENTRY_AUTH_TOKEN}}" "$SENTRY_AUTH_TOKEN"

        log_file_created "$SCRIPT_NAME" ".sentryrc"
        track_created ".sentryrc"
    fi
fi

# ===================================================================
# Create Prometheus Configuration
# ===================================================================

if [[ "$ENABLE_PROMETHEUS" == "true" ]]; then
    log_info "Creating Prometheus configuration..."

    if file_exists "$PROJECT_ROOT/prometheus.yml"; then
        backup_file "$PROJECT_ROOT/prometheus.yml"
        track_skipped "prometheus.yml (backed up)"
        log_warning "prometheus.yml already exists, backed up"
    else
        copy_template "root/monitoring/prometheus.yml" "$PROJECT_ROOT/prometheus.yml"

        # Replace placeholders
        source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
        replace_in_file "$PROJECT_ROOT/prometheus.yml" "{{PROMETHEUS_SCRAPE_INTERVAL}}" "$PROMETHEUS_SCRAPE_INTERVAL"
        replace_in_file "$PROJECT_ROOT/prometheus.yml" "{{PROMETHEUS_EVAL_INTERVAL}}" "$PROMETHEUS_EVAL_INTERVAL"
        replace_in_file "$PROJECT_ROOT/prometheus.yml" "{{PROJECT_NAME}}" "$PROJECT_NAME"
        replace_in_file "$PROJECT_ROOT/prometheus.yml" "{{ENVIRONMENT}}" "$ENVIRONMENT"
        replace_in_file "$PROJECT_ROOT/prometheus.yml" "{{APP_PORT}}" "$APP_PORT"

        log_file_created "$SCRIPT_NAME" "prometheus.yml"
        track_created "prometheus.yml"
    fi

    # Create alert rules
    log_info "Creating Prometheus alert rules..."

    if file_exists "$PROJECT_ROOT/monitoring/alerts/alerts.yml"; then
        backup_file "$PROJECT_ROOT/monitoring/alerts/alerts.yml"
        track_skipped "monitoring/alerts/alerts.yml (backed up)"
        log_warning "monitoring/alerts/alerts.yml already exists, backed up"
    else
        copy_template "root/monitoring/alerts.yml" "$PROJECT_ROOT/monitoring/alerts/alerts.yml"

        # Replace placeholders
        replace_in_file "$PROJECT_ROOT/monitoring/alerts/alerts.yml" "{{TEAM_NAME}}" "$TEAM_NAME"

        log_file_created "$SCRIPT_NAME" "monitoring/alerts/alerts.yml"
        track_created "monitoring/alerts/alerts.yml"
    fi
fi

# ===================================================================
# Create Datadog Configuration
# ===================================================================

if [[ "$ENABLE_DATADOG" == "true" ]]; then
    log_info "Creating Datadog configuration..."

    if file_exists "$PROJECT_ROOT/datadog.yaml"; then
        backup_file "$PROJECT_ROOT/datadog.yaml"
        track_skipped "datadog.yaml (backed up)"
        log_warning "datadog.yaml already exists, backed up"
    else
        copy_template "root/monitoring/datadog.yaml" "$PROJECT_ROOT/datadog.yaml"

        # Replace placeholders
        source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
        replace_in_file "$PROJECT_ROOT/datadog.yaml" "{{DATADOG_API_KEY}}" "$DATADOG_API_KEY"
        replace_in_file "$PROJECT_ROOT/datadog.yaml" "{{DATADOG_SITE}}" "$DATADOG_SITE"
        replace_in_file "$PROJECT_ROOT/datadog.yaml" "{{ENVIRONMENT}}" "$ENVIRONMENT"
        replace_in_file "$PROJECT_ROOT/datadog.yaml" "{{PROJECT_NAME}}" "$PROJECT_NAME"
        replace_in_file "$PROJECT_ROOT/datadog.yaml" "{{TEAM_NAME}}" "$TEAM_NAME"
        replace_in_file "$PROJECT_ROOT/datadog.yaml" "{{DATADOG_LOGS_ENABLED}}" "$DATADOG_LOGS_ENABLED"
        replace_in_file "$PROJECT_ROOT/datadog.yaml" "{{DATADOG_APM_ENABLED}}" "$DATADOG_APM_ENABLED"
        replace_in_file "$PROJECT_ROOT/datadog.yaml" "{{DATADOG_APM_SAMPLE_RATE}}" "$DATADOG_APM_SAMPLE_RATE"
        replace_in_file "$PROJECT_ROOT/datadog.yaml" "{{DATADOG_PROCESS_ENABLED}}" "$DATADOG_PROCESS_ENABLED"
        replace_in_file "$PROJECT_ROOT/datadog.yaml" "{{DATADOG_NETWORK_ENABLED}}" "$DATADOG_NETWORK_ENABLED"

        log_file_created "$SCRIPT_NAME" "datadog.yaml"
        track_created "datadog.yaml"
    fi
fi

# ===================================================================
# Create New Relic Configuration
# ===================================================================

if [[ "$ENABLE_NEWRELIC" == "true" ]]; then
    log_info "Creating New Relic configuration..."

    if file_exists "$PROJECT_ROOT/newrelic.js"; then
        backup_file "$PROJECT_ROOT/newrelic.js"
        track_skipped "newrelic.js (backed up)"
        log_warning "newrelic.js already exists, backed up"
    else
        copy_template "root/monitoring/newrelic.js" "$PROJECT_ROOT/newrelic.js"

        # Replace placeholders
        source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
        replace_in_file "$PROJECT_ROOT/newrelic.js" "{{PROJECT_NAME}}" "$PROJECT_NAME"
        replace_in_file "$PROJECT_ROOT/newrelic.js" "{{NEWRELIC_LICENSE_KEY}}" "$NEWRELIC_LICENSE_KEY"
        replace_in_file "$PROJECT_ROOT/newrelic.js" "{{NEWRELIC_LOG_LEVEL}}" "$NEWRELIC_LOG_LEVEL"
        replace_in_file "$PROJECT_ROOT/newrelic.js" "{{NEWRELIC_TRANSACTION_TRACER}}" "$NEWRELIC_TRANSACTION_TRACER"
        replace_in_file "$PROJECT_ROOT/newrelic.js" "{{NEWRELIC_ERROR_COLLECTOR}}" "$NEWRELIC_ERROR_COLLECTOR"
        replace_in_file "$PROJECT_ROOT/newrelic.js" "{{NEWRELIC_DISTRIBUTED_TRACING}}" "$NEWRELIC_DISTRIBUTED_TRACING"
        replace_in_file "$PROJECT_ROOT/newrelic.js" "{{NEWRELIC_SLOW_SQL}}" "$NEWRELIC_SLOW_SQL"
        replace_in_file "$PROJECT_ROOT/newrelic.js" "{{NEWRELIC_BROWSER_MONITORING}}" "$NEWRELIC_BROWSER_MONITORING"
        replace_in_file "$PROJECT_ROOT/newrelic.js" "{{NEWRELIC_APP_LOGGING}}" "$NEWRELIC_APP_LOGGING"
        replace_in_file "$PROJECT_ROOT/newrelic.js" "{{NEWRELIC_LOG_FORWARDING}}" "$NEWRELIC_LOG_FORWARDING"
        replace_in_file "$PROJECT_ROOT/newrelic.js" "{{NEWRELIC_LOG_METRICS}}" "$NEWRELIC_LOG_METRICS"
        replace_in_file "$PROJECT_ROOT/newrelic.js" "{{NEWRELIC_LOG_DECORATING}}" "$NEWRELIC_LOG_DECORATING"
        replace_in_file "$PROJECT_ROOT/newrelic.js" "{{ENVIRONMENT}}" "$ENVIRONMENT"
        replace_in_file "$PROJECT_ROOT/newrelic.js" "{{TEAM_NAME}}" "$TEAM_NAME"

        log_file_created "$SCRIPT_NAME" "newrelic.js"
        track_created "newrelic.js"
    fi
fi

# ===================================================================
# Create Environment Variables File
# ===================================================================

log_info "Creating monitoring environment variables..."

if file_exists "$PROJECT_ROOT/.env.monitoring"; then
    backup_file "$PROJECT_ROOT/.env.monitoring"
    track_skipped ".env.monitoring (backed up)"
    log_warning ".env.monitoring already exists, backed up"
else
    copy_template "root/monitoring/.env.monitoring" "$PROJECT_ROOT/.env.monitoring"

    # Replace placeholders
    source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{SENTRY_DSN}}" "$SENTRY_DSN"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{SENTRY_AUTH_TOKEN}}" "$SENTRY_AUTH_TOKEN"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{SENTRY_ORG}}" "$SENTRY_ORG"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{SENTRY_PROJECT}}" "$SENTRY_PROJECT"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{SENTRY_URL}}" "$SENTRY_URL"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{SENTRY_TRACES_SAMPLE_RATE}}" "$SENTRY_TRACES_SAMPLE_RATE"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{DATADOG_API_KEY}}" "$DATADOG_API_KEY"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{DATADOG_APP_KEY}}" "$DATADOG_APP_KEY"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{DATADOG_SITE}}" "$DATADOG_SITE"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{DATADOG_LOGS_ENABLED}}" "$DATADOG_LOGS_ENABLED"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{DATADOG_APM_ENABLED}}" "$DATADOG_APM_ENABLED"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{DATADOG_APM_SAMPLE_RATE}}" "$DATADOG_APM_SAMPLE_RATE"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{NEWRELIC_LICENSE_KEY}}" "$NEWRELIC_LICENSE_KEY"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{NEWRELIC_LOG_LEVEL}}" "$NEWRELIC_LOG_LEVEL"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{NEWRELIC_DISTRIBUTED_TRACING}}" "$NEWRELIC_DISTRIBUTED_TRACING"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{PROMETHEUS_SCRAPE_INTERVAL}}" "$PROMETHEUS_SCRAPE_INTERVAL"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{PROMETHEUS_EVAL_INTERVAL}}" "$PROMETHEUS_EVAL_INTERVAL"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{ENVIRONMENT}}" "$ENVIRONMENT"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{PROJECT_NAME}}" "$PROJECT_NAME"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{VERSION}}" "$VERSION"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{TEAM_NAME}}" "$TEAM_NAME"
    replace_in_file "$PROJECT_ROOT/.env.monitoring" "{{APP_PORT}}" "$APP_PORT"

    log_file_created "$SCRIPT_NAME" ".env.monitoring"
    track_created ".env.monitoring"
fi

# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "Monitoring configuration complete!"
echo ""
echo "Enabled providers:"
[[ "$ENABLE_SENTRY" == "true" ]] && echo "  - Sentry (Error Tracking)"
[[ "$ENABLE_PROMETHEUS" == "true" ]] && echo "  - Prometheus (Metrics & Alerting)"
[[ "$ENABLE_DATADOG" == "true" ]] && echo "  - Datadog (APM & Monitoring)"
[[ "$ENABLE_NEWRELIC" == "true" ]] && echo "  - New Relic (APM)"
echo ""
echo "Next steps:"
echo "  1. Review .env.monitoring and add your API keys/tokens"
echo "  2. Install monitoring SDKs for your language:"
if [[ "$ENABLE_SENTRY" == "true" ]]; then
    echo "     - Sentry: npm install @sentry/node @sentry/tracing"
fi
if [[ "$ENABLE_DATADOG" == "true" ]]; then
    echo "     - Datadog: npm install dd-trace"
fi
if [[ "$ENABLE_NEWRELIC" == "true" ]]; then
    echo "     - New Relic: npm install newrelic"
fi
if [[ "$ENABLE_PROMETHEUS" == "true" ]]; then
    echo "     - Prometheus: npm install prom-client"
fi
echo "  3. Initialize monitoring in your application entry point"
echo "  4. Configure alert thresholds in monitoring/alerts/alerts.yml"
echo "  5. Test error tracking by triggering a test error"
echo ""
echo "Configuration tips:"
echo "  - Start with Sentry for error tracking (free tier available)"
echo "  - Use Prometheus for custom metrics and alerting"
echo "  - Datadog/New Relic provide full-stack APM (paid)"
echo "  - Keep .env.monitoring out of version control"
echo "  - Review sample rates in production to manage costs"
echo ""

show_log_location
