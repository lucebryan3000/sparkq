#!/bin/bash
# =============================================================================
# @name           bootstrap-elasticsearch
# @phase          5
# @category       config
# @short          Elasticsearch cluster infrastructure config
# @description    Configures Elasticsearch cluster with analysis plugins,
#                 security settings, Docker Compose orchestration, persistent
#                 data/log volumes, and environment configuration for search
#                 and analytics capabilities.
#
# @creates        infrastructure/elasticsearch/elasticsearch.yml
# @creates        infrastructure/elasticsearch/analysis.yml
# @creates        .env.elasticsearch
# @creates        docker-compose.elasticsearch.yml
#
# @defaults       ES_VERSION=8.0, ES_PORT=9200, ES_MEMORY=512m
# @defaults       ES_DISCOVERY_TYPE=single-node, ES_SECURITY_ENABLED=false
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
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

# Source Docker utilities
source "${BOOTSTRAP_DIR}/lib/docker-utils.sh"

# Initialize script
init_script "bootstrap-elasticsearch"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-elasticsearch"

# Track created files for display
declare -a CREATED_FILES=()
declare -a SKIPPED_FILES=()

# ===================================================================
# Read Configuration
# ===================================================================

# Check if this bootstrap should run
ENABLED=$(config_get "elasticsearch.enabled" "true")
if [[ "$ENABLED" != "true" ]]; then
    log_info "Elasticsearch bootstrap disabled in config"
    exit 0
fi

# Read Elasticsearch-specific settings
ES_VERSION=$(config_get "elasticsearch.version" "8.0")
ES_NODE_NAME=$(config_get "elasticsearch.node_name" "node-1")
ES_CLUSTER_NAME=$(config_get "elasticsearch.cluster_name" "elasticsearch")
ES_PORT=$(config_get "elasticsearch.port" "9200")
ES_MEMORY=$(config_get "elasticsearch.memory" "512m")
ES_DISCOVERY_TYPE=$(config_get "elasticsearch.discovery_type" "single-node")
ES_SECURITY_ENABLED=$(config_get "elasticsearch.security_enabled" "false")
ES_PASSWORD=$(config_get "elasticsearch.password" "changeme")

# Get project name for Docker
PROJECT_NAME=$(config_get "project.name" "app")

# Detect Docker environment
if is_in_docker; then
    log_info "Running inside Docker (Tier $(get_docker_tier))"
    ES_BIND_HOST="0.0.0.0"
else
    ES_BIND_HOST="0.0.0.0"
fi

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

FILES_TO_CREATE=(
    "infrastructure/elasticsearch/"
    "infrastructure/elasticsearch/elasticsearch.yml"
    "infrastructure/elasticsearch/analysis.yml"
    ".env.elasticsearch"
    "docker-compose.elasticsearch.yml"
)

pre_execution_confirm "$SCRIPT_NAME" "Elasticsearch Configuration" \
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
# Create Elasticsearch Directory Structure
# ===================================================================

log_info "Creating Elasticsearch directory structure..."

if ! dir_exists "$PROJECT_ROOT/infrastructure/elasticsearch"; then
    ensure_dir "$PROJECT_ROOT/infrastructure/elasticsearch"
    log_dir_created "$SCRIPT_NAME" "infrastructure/elasticsearch/"
fi

if ! dir_exists "$PROJECT_ROOT/infrastructure/elasticsearch/data"; then
    ensure_dir "$PROJECT_ROOT/infrastructure/elasticsearch/data"
    log_dir_created "$SCRIPT_NAME" "infrastructure/elasticsearch/data/"
fi

if ! dir_exists "$PROJECT_ROOT/infrastructure/elasticsearch/logs"; then
    ensure_dir "$PROJECT_ROOT/infrastructure/elasticsearch/logs"
    log_dir_created "$SCRIPT_NAME" "infrastructure/elasticsearch/logs/"
fi

log_success "Directory structure created"

# ===================================================================
# Create Elasticsearch Configuration
# ===================================================================

log_info "Creating Elasticsearch configuration..."

ES_CONFIG_FILE="$PROJECT_ROOT/infrastructure/elasticsearch/elasticsearch.yml"

if file_exists "$ES_CONFIG_FILE"; then
    backup_file "$ES_CONFIG_FILE"
    SKIPPED_FILES+=("infrastructure/elasticsearch/elasticsearch.yml (backed up)")
    log_warning "elasticsearch.yml already exists, backed up"
else
    cat > "$ES_CONFIG_FILE" << 'EOFCONFIG'
# ===================================================================
# Elasticsearch Configuration
# Auto-generated by bootstrap-elasticsearch.sh
# ===================================================================

# Cluster Configuration
cluster.name: {{CLUSTER_NAME}}
node.name: {{NODE_NAME}}

# Network Configuration
network.host: {{BIND_HOST}}
http.port: {{ES_PORT}}

# Discovery Configuration (single-node for development)
discovery.type: {{DISCOVERY_TYPE}}

# Path Configuration
path.data: /usr/share/elasticsearch/data
path.logs: /usr/share/elasticsearch/logs

# Memory Lock
bootstrap.memory_lock: true

# Security Configuration
xpack.security.enabled: {{SECURITY_ENABLED}}
xpack.security.enrollment.enabled: false
xpack.security.http.ssl.enabled: false
xpack.security.transport.ssl.enabled: false

# Monitoring
xpack.monitoring.collection.enabled: true

# Index Lifecycle Management
xpack.ilm.enabled: true

# Machine Learning (disable for development)
xpack.ml.enabled: false

# Index Configuration
action.auto_create_index: true
action.destructive_requires_name: true

# Thread Pool Configuration
thread_pool.write.queue_size: 1000
thread_pool.search.queue_size: 1000

# Query Configuration
indices.query.bool.max_clause_count: 10000

# ===================================================================
# Performance Tuning
# ===================================================================

# Disable swapping
bootstrap.mlockall: true

# Field data cache
indices.fielddata.cache.size: 20%

# Circuit Breaker
indices.breaker.fielddata.limit: 40%
indices.breaker.request.limit: 60%
indices.breaker.total.limit: 70%
EOFCONFIG

    # Replace placeholders
    sed -i "s/{{CLUSTER_NAME}}/$ES_CLUSTER_NAME/g" "$ES_CONFIG_FILE"
    sed -i "s/{{NODE_NAME}}/$ES_NODE_NAME/g" "$ES_CONFIG_FILE"
    sed -i "s/{{BIND_HOST}}/$ES_BIND_HOST/g" "$ES_CONFIG_FILE"
    sed -i "s/{{ES_PORT}}/$ES_PORT/g" "$ES_CONFIG_FILE"
    sed -i "s/{{DISCOVERY_TYPE}}/$ES_DISCOVERY_TYPE/g" "$ES_CONFIG_FILE"
    sed -i "s/{{SECURITY_ENABLED}}/$ES_SECURITY_ENABLED/g" "$ES_CONFIG_FILE"

    verify_file "$ES_CONFIG_FILE"
    log_file_created "$SCRIPT_NAME" "infrastructure/elasticsearch/elasticsearch.yml"
    CREATED_FILES+=("infrastructure/elasticsearch/elasticsearch.yml")
fi

# ===================================================================
# Create Analysis Configuration
# ===================================================================

log_info "Creating Elasticsearch analysis configuration..."

ANALYSIS_FILE="$PROJECT_ROOT/infrastructure/elasticsearch/analysis.yml"

if file_exists "$ANALYSIS_FILE"; then
    backup_file "$ANALYSIS_FILE"
    SKIPPED_FILES+=("infrastructure/elasticsearch/analysis.yml (backed up)")
    log_warning "analysis.yml already exists, backed up"
else
    cat > "$ANALYSIS_FILE" << 'EOFANALYSIS'
# ===================================================================
# Elasticsearch Analysis Configuration
# Auto-generated by bootstrap-elasticsearch.sh
# ===================================================================

# Custom Analyzers (apply via index templates)
# This file contains example analyzer configurations
# Use these in your index templates or settings

# Example: Standard analyzer with lowercase filter
# PUT /my_index
# {
#   "settings": {
#     "analysis": {
#       "analyzer": {
#         "standard_lowercase": {
#           "type": "standard",
#           "stopwords": "_english_"
#         }
#       }
#     }
#   }
# }

# Example: Custom analyzer with edge ngrams for autocomplete
# PUT /autocomplete_index
# {
#   "settings": {
#     "analysis": {
#       "filter": {
#         "autocomplete_filter": {
#           "type": "edge_ngram",
#           "min_gram": 2,
#           "max_gram": 20
#         }
#       },
#       "analyzer": {
#         "autocomplete": {
#           "type": "custom",
#           "tokenizer": "standard",
#           "filter": [
#             "lowercase",
#             "autocomplete_filter"
#           ]
#         }
#       }
#     }
#   }
# }

# Example: Full-text search analyzer
# PUT /search_index
# {
#   "settings": {
#     "analysis": {
#       "analyzer": {
#         "fulltext_search": {
#           "type": "custom",
#           "tokenizer": "standard",
#           "filter": [
#             "lowercase",
#             "stop",
#             "snowball"
#           ]
#         }
#       }
#     }
#   }
# }

# Example: Path hierarchy tokenizer for file paths
# PUT /path_index
# {
#   "settings": {
#     "analysis": {
#       "tokenizer": {
#         "path_tokenizer": {
#           "type": "path_hierarchy",
#           "delimiter": "/"
#         }
#       },
#       "analyzer": {
#         "path_analyzer": {
#           "type": "custom",
#           "tokenizer": "path_tokenizer"
#         }
#       }
#     }
#   }
# }

# ===================================================================
# Index Template Example
# ===================================================================

# Default template for application indices
# PUT _index_template/app_template
# {
#   "index_patterns": ["app-*"],
#   "template": {
#     "settings": {
#       "number_of_shards": 1,
#       "number_of_replicas": 0,
#       "refresh_interval": "1s",
#       "max_result_window": 10000
#     }
#   }
# }
EOFANALYSIS

    verify_file "$ANALYSIS_FILE"
    log_file_created "$SCRIPT_NAME" "infrastructure/elasticsearch/analysis.yml"
    CREATED_FILES+=("infrastructure/elasticsearch/analysis.yml")
fi

# ===================================================================
# Create Environment File
# ===================================================================

log_info "Creating Elasticsearch environment configuration..."

ENV_FILE="$PROJECT_ROOT/.env.elasticsearch"

if file_exists "$ENV_FILE"; then
    backup_file "$ENV_FILE"
    SKIPPED_FILES+=(".env.elasticsearch (backed up)")
    log_warning ".env.elasticsearch already exists, backed up"
else
    cat > "$ENV_FILE" << 'EOFENV'
# ===================================================================
# Elasticsearch Environment Configuration
# Auto-generated by bootstrap-elasticsearch.sh
# ===================================================================

# Cluster Configuration
ELASTICSEARCH_CLUSTER_NAME={{CLUSTER_NAME}}
ELASTICSEARCH_NODE_NAME={{NODE_NAME}}

# Connection
ELASTICSEARCH_URL=http://localhost:{{ES_PORT}}
ELASTICSEARCH_HOST=localhost
ELASTICSEARCH_PORT={{ES_PORT}}

# Security
ELASTICSEARCH_SECURITY_ENABLED={{SECURITY_ENABLED}}
ELASTICSEARCH_USERNAME=elastic
ELASTICSEARCH_PASSWORD={{ES_PASSWORD}}

# Java Options
ES_JAVA_OPTS=-Xms{{ES_MEMORY}} -Xmx{{ES_MEMORY}}

# Discovery
ELASTICSEARCH_DISCOVERY_TYPE={{DISCOVERY_TYPE}}

# Monitoring
ELASTICSEARCH_MONITORING_ENABLED=true

# Index Configuration
ELASTICSEARCH_AUTO_CREATE_INDEX=true
ELASTICSEARCH_DEFAULT_SHARDS=1
ELASTICSEARCH_DEFAULT_REPLICAS=0

# Performance
ELASTICSEARCH_MAX_RESULT_WINDOW=10000
ELASTICSEARCH_REFRESH_INTERVAL=1s

# Logging
ELASTICSEARCH_LOG_LEVEL=info
EOFENV

    # Replace placeholders
    sed -i "s/{{CLUSTER_NAME}}/$ES_CLUSTER_NAME/g" "$ENV_FILE"
    sed -i "s/{{NODE_NAME}}/$ES_NODE_NAME/g" "$ENV_FILE"
    sed -i "s/{{ES_PORT}}/$ES_PORT/g" "$ENV_FILE"
    sed -i "s/{{ES_MEMORY}}/$ES_MEMORY/g" "$ENV_FILE"
    sed -i "s/{{SECURITY_ENABLED}}/$ES_SECURITY_ENABLED/g" "$ENV_FILE"
    sed -i "s/{{DISCOVERY_TYPE}}/$ES_DISCOVERY_TYPE/g" "$ENV_FILE"
    sed -i "s/{{ES_PASSWORD}}/$ES_PASSWORD/g" "$ENV_FILE"

    verify_file "$ENV_FILE"
    log_file_created "$SCRIPT_NAME" ".env.elasticsearch"
    CREATED_FILES+=(".env.elasticsearch")
fi

# ===================================================================
# Create Docker Compose Configuration
# ===================================================================

log_info "Creating Docker Compose configuration..."

DOCKER_COMPOSE_FILE="$PROJECT_ROOT/docker-compose.elasticsearch.yml"

if file_exists "$DOCKER_COMPOSE_FILE"; then
    backup_file "$DOCKER_COMPOSE_FILE"
    SKIPPED_FILES+=("docker-compose.elasticsearch.yml (backed up)")
    log_warning "docker-compose.elasticsearch.yml already exists, backed up"
else
    cat > "$DOCKER_COMPOSE_FILE" << 'EOFDOCKER'
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:{{ES_VERSION}}
    container_name: {{PROJECT_NAME}}-elasticsearch
    environment:
      - cluster.name={{CLUSTER_NAME}}
      - node.name={{NODE_NAME}}
      - discovery.type={{DISCOVERY_TYPE}}
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms{{ES_MEMORY}} -Xmx{{ES_MEMORY}}"
      - xpack.security.enabled={{SECURITY_ENABLED}}
      - xpack.security.enrollment.enabled=false
      - xpack.security.http.ssl.enabled=false
      - xpack.security.transport.ssl.enabled=false
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    ports:
      - "{{ES_PORT}}:9200"
      - "9300:9300"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
      - elasticsearch_logs:/usr/share/elasticsearch/logs
      - ./infrastructure/elasticsearch/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml:ro
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9200/_cluster/health || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s
    networks:
      - {{PROJECT_NAME}}-net
    restart: unless-stopped

volumes:
  elasticsearch_data:
    driver: local
  elasticsearch_logs:
    driver: local

networks:
  {{PROJECT_NAME}}-net:
    driver: bridge
EOFDOCKER

    # Replace placeholders
    sed -i "s/{{ES_VERSION}}/$ES_VERSION/g" "$DOCKER_COMPOSE_FILE"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$DOCKER_COMPOSE_FILE"
    sed -i "s/{{CLUSTER_NAME}}/$ES_CLUSTER_NAME/g" "$DOCKER_COMPOSE_FILE"
    sed -i "s/{{NODE_NAME}}/$ES_NODE_NAME/g" "$DOCKER_COMPOSE_FILE"
    sed -i "s/{{DISCOVERY_TYPE}}/$ES_DISCOVERY_TYPE/g" "$DOCKER_COMPOSE_FILE"
    sed -i "s/{{ES_MEMORY}}/$ES_MEMORY/g" "$DOCKER_COMPOSE_FILE"
    sed -i "s/{{SECURITY_ENABLED}}/$ES_SECURITY_ENABLED/g" "$DOCKER_COMPOSE_FILE"
    sed -i "s/{{ES_PORT}}/$ES_PORT/g" "$DOCKER_COMPOSE_FILE"

    verify_file "$DOCKER_COMPOSE_FILE"
    log_file_created "$SCRIPT_NAME" "docker-compose.elasticsearch.yml"
    CREATED_FILES+=("docker-compose.elasticsearch.yml")
fi

# ===================================================================
# Display Created Files
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#CREATED_FILES[@]} files created"

echo ""
log_section "Elasticsearch Bootstrap Complete"

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
echo -e "${BLUE}Elasticsearch Configuration:${NC}"
echo "  Cluster: $ES_CLUSTER_NAME"
echo "  Node: $ES_NODE_NAME"
echo "  Port: $ES_PORT"
echo "  Memory: $ES_MEMORY"
echo "  Discovery: $ES_DISCOVERY_TYPE"
echo "  Security: $ES_SECURITY_ENABLED"
echo ""

echo -e "${BLUE}Quick Start:${NC}"
echo "  1. Start Elasticsearch container:"
echo "     docker-compose -f docker-compose.elasticsearch.yml up -d"
echo ""
echo "  2. Verify cluster health:"
echo "     curl http://localhost:$ES_PORT/_cluster/health?pretty"
echo ""
echo "  3. List indices:"
echo "     curl http://localhost:$ES_PORT/_cat/indices?v"
echo ""
echo "  4. Create an index:"
echo "     curl -X PUT http://localhost:$ES_PORT/my_index"
echo ""

echo -e "${BLUE}Files Created:${NC}"
echo "  Infrastructure: ${#CREATED_FILES[@]} files"
echo "  Location: $PROJECT_ROOT"
echo ""

if [[ "$ES_SECURITY_ENABLED" == "true" ]]; then
    echo -e "${YELLOW}Security Reminder:${NC}"
    echo "  • Security is ENABLED"
    echo "  • Default password: $ES_PASSWORD"
    echo "  • Change password in .env.elasticsearch"
    echo "  • Never commit .env.elasticsearch to git"
    echo ""
else
    echo -e "${YELLOW}Security Reminder:${NC}"
    echo "  • Security is DISABLED (development mode)"
    echo "  • Enable security for production:"
    echo "    Set elasticsearch.security_enabled=true in bootstrap.config"
    echo "  • Never commit .env.elasticsearch to git"
    echo ""
fi

echo -e "${BLUE}Next Steps:${NC}"
echo "  • Review elasticsearch.yml for custom settings"
echo "  • Check analysis.yml for analyzer examples"
echo "  • Create index templates for your data"
echo "  • Configure index lifecycle policies (ILM)"
echo ""

show_log_location
