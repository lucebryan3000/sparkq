#!/bin/bash
# =============================================================================
# @script         bootstrap-rate-limiting
# @version        1.0.0
# @phase          2
# @category       config
# @priority       50
# @short          Redis-based rate limiting service configuration
# @description    Sets up Redis-based rate limiting infrastructure with token
#                 bucket strategy, Lua scripts for atomic operations, endpoint
#                 configuration, Docker Compose for Redis, environment setup,
#                 and example integration code.
#
# @creates        config/rate-limiting/rate-limit.config.json
# @creates        config/rate-limiting/redis-init.lua
# @creates        config/rate-limiting/strategies.lua
# @creates        config/rate-limiting/endpoints.json
# @creates        config/rate-limiting/example-integration.js
# @creates        .env.rate-limiting
# @creates        docker-compose.rate-limiting.yml
#
# @detects        has_rate-limit.config
# @questions      rate-limiting
# @defaults       redis_version=7.0, redis_port=6379, window_seconds=60
# @detects        has_rate-limit.config
# @questions      rate-limiting
# @defaults       max_requests=100, strategy=token-bucket
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
#
# @config_section  rate_limiting
# @env_vars        BLUE,CONFIG_FILE,CREATED_FILES,DOCKER_COMPOSE_FILE,ENABLED,ENDPOINTS_FILE,ENV_FILE,EXAMPLE_FILE,FILES_TO_CREATE,GREEN,LUA_INIT_FILE,NC,RATE_LIMIT_KEYS_PATTERN,RATE_LIMIT_MAX_REQUESTS,RATE_LIMIT_STRATEGY,RATE_LIMIT_WINDOW,REDIS_DB,REDIS_PASSWORD,REDIS_PORT,REDIS_VERSION,SKIPPED_FILES,STRATEGIES_FILE,YELLOW
# @interactive     no
# @platforms       all
# @conflicts       none
# @rollback        rm -rf config/rate-limiting/rate-limit.config.json config/rate-limiting/redis-init.lua config/rate-limiting/strategies.lua config/rate-limiting/endpoints.json config/rate-limiting/example-integration.js .env.rate-limiting docker-compose.rate-limiting.yml
# @verify          test -f config/rate-limiting/rate-limit.config.json
# @docs            https://github.com/express-rate-limit/express-rate-limit
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
init_script "bootstrap-rate-limiting"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-rate-limiting"

# Track created files for display
declare -a CREATED_FILES=()
declare -a SKIPPED_FILES=()

# ===================================================================
# Read Configuration
# ===================================================================

# Check if this bootstrap should run
ENABLED=$(config_get "rate_limiting.enabled" "true")
if [[ "$ENABLED" != "true" ]]; then
    log_info "Rate limiting bootstrap disabled in config"
    exit 0
fi

# Read rate limiting specific settings
REDIS_VERSION=$(config_get "rate_limiting.redis_version" "7.0")
REDIS_PORT=$(config_get "rate_limiting.redis_port" "6379")
REDIS_PASSWORD=$(config_get "rate_limiting.redis_password" "")
REDIS_DB=$(config_get "rate_limiting.redis_db" "1")
RATE_LIMIT_WINDOW=$(config_get "rate_limiting.window_seconds" "60")
RATE_LIMIT_MAX_REQUESTS=$(config_get "rate_limiting.max_requests" "100")
RATE_LIMIT_STRATEGY=$(config_get "rate_limiting.strategy" "token-bucket")
RATE_LIMIT_KEYS_PATTERN=$(config_get "rate_limiting.keys_pattern" "ratelimit:*")

# Get project name for Docker
PROJECT_NAME=$(config_get "project.name" "app")

# Generate Redis password if not provided
if [[ -z "$REDIS_PASSWORD" ]]; then
    REDIS_PASSWORD=$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)
fi

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

FILES_TO_CREATE=(
    "config/rate-limiting/"
    "config/rate-limiting/rate-limit.config.json"
    "config/rate-limiting/redis-init.lua"
    "config/rate-limiting/strategies.lua"
    "config/rate-limiting/endpoints.json"
    ".env.rate-limiting"
    "docker-compose.rate-limiting.yml"
)

pre_execution_confirm "$SCRIPT_NAME" "Rate Limiting Configuration" \
    "${FILES_TO_CREATE[@]}"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check if project directory exists
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"

# Check if we can write to project
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Check if Redis is already running (optional health check)
if command -v redis-cli &>/dev/null; then
    if redis-cli -p "$REDIS_PORT" ping 2>/dev/null | grep -q PONG; then
        log_warning "Redis already running on port $REDIS_PORT"
    fi
fi

log_success "Environment validated"

# ===================================================================
# Create Rate Limiting Directory Structure
# ===================================================================

log_info "Creating rate limiting directory structure..."

if ! dir_exists "$PROJECT_ROOT/config/rate-limiting"; then
    ensure_dir "$PROJECT_ROOT/config/rate-limiting"
    log_dir_created "$SCRIPT_NAME" "config/rate-limiting/"
fi

if ! dir_exists "$PROJECT_ROOT/config/rate-limiting/scripts"; then
    ensure_dir "$PROJECT_ROOT/config/rate-limiting/scripts"
    log_dir_created "$SCRIPT_NAME" "config/rate-limiting/scripts/"
fi

log_success "Directory structure created"

# ===================================================================
# Create Rate Limit Configuration
# ===================================================================

log_info "Creating rate limit configuration..."

CONFIG_FILE="$PROJECT_ROOT/config/rate-limiting/rate-limit.config.json"

if file_exists "$CONFIG_FILE"; then
    backup_file "$CONFIG_FILE"
    SKIPPED_FILES+=("config/rate-limiting/rate-limit.config.json (backed up)")
    log_warning "rate-limit.config.json already exists, backed up"
else
    cat > "$CONFIG_FILE" << 'EOFCONFIG'
{
  "redis": {
    "host": "{{REDIS_HOST}}",
    "port": {{REDIS_PORT}},
    "db": {{REDIS_DB}},
    "password": "{{REDIS_PASSWORD}}",
    "keyPrefix": "ratelimit:",
    "connectTimeout": 5000,
    "commandTimeout": 2000,
    "retryStrategy": {
      "maxAttempts": 3,
      "initialDelay": 100,
      "maxDelay": 1000,
      "multiplier": 2
    }
  },
  "strategies": {
    "token-bucket": {
      "enabled": true,
      "refillRate": 10,
      "bucketSize": 100,
      "description": "Allows bursts but enforces average rate"
    },
    "sliding-window": {
      "enabled": true,
      "windowSize": 60,
      "maxRequests": 100,
      "description": "Smooths traffic over time window"
    },
    "leaky-bucket": {
      "enabled": false,
      "capacity": 100,
      "leakRate": 10,
      "description": "Processes requests at constant rate"
    },
    "fixed-window": {
      "enabled": false,
      "windowSize": 60,
      "maxRequests": 100,
      "description": "Simple per-minute limit"
    }
  },
  "defaultStrategy": "{{RATE_LIMIT_STRATEGY}}",
  "globalLimits": {
    "perSecond": null,
    "perMinute": {{RATE_LIMIT_MAX_REQUESTS}},
    "perHour": null,
    "perDay": null
  },
  "monitoring": {
    "enabled": true,
    "logViolations": true,
    "metricsEnabled": true,
    "alertThreshold": 0.8
  },
  "keys": {
    "pattern": "{{RATE_LIMIT_KEYS_PATTERN}}",
    "ttl": {{RATE_LIMIT_WINDOW}},
    "separator": ":"
  },
  "headers": {
    "limit": "X-RateLimit-Limit",
    "remaining": "X-RateLimit-Remaining",
    "reset": "X-RateLimit-Reset",
    "retryAfter": "Retry-After"
  },
  "responses": {
    "statusCode": 429,
    "message": "Too Many Requests",
    "includeRetryAfter": true
  }
}
EOFCONFIG

    # Replace placeholders
    sed -i "s/{{REDIS_HOST}}/localhost/g" "$CONFIG_FILE"
    sed -i "s/{{REDIS_PORT}}/$REDIS_PORT/g" "$CONFIG_FILE"
    sed -i "s/{{REDIS_DB}}/$REDIS_DB/g" "$CONFIG_FILE"
    sed -i "s/{{REDIS_PASSWORD}}/$REDIS_PASSWORD/g" "$CONFIG_FILE"
    sed -i "s/{{RATE_LIMIT_STRATEGY}}/$RATE_LIMIT_STRATEGY/g" "$CONFIG_FILE"
    sed -i "s/{{RATE_LIMIT_MAX_REQUESTS}}/$RATE_LIMIT_MAX_REQUESTS/g" "$CONFIG_FILE"
    sed -i "s/{{RATE_LIMIT_KEYS_PATTERN}}/$RATE_LIMIT_KEYS_PATTERN/g" "$CONFIG_FILE"
    sed -i "s/{{RATE_LIMIT_WINDOW}}/$RATE_LIMIT_WINDOW/g" "$CONFIG_FILE"

    verify_file "$CONFIG_FILE"
    log_file_created "$SCRIPT_NAME" "config/rate-limiting/rate-limit.config.json"
    CREATED_FILES+=("config/rate-limiting/rate-limit.config.json")
fi

# ===================================================================
# Create Redis Initialization Lua Script
# ===================================================================

log_info "Creating Redis Lua script for atomic rate limiting..."

LUA_INIT_FILE="$PROJECT_ROOT/config/rate-limiting/redis-init.lua"

if file_exists "$LUA_INIT_FILE"; then
    backup_file "$LUA_INIT_FILE"
    SKIPPED_FILES+=("config/rate-limiting/redis-init.lua (backed up)")
    log_warning "redis-init.lua already exists, backed up"
else
    cat > "$LUA_INIT_FILE" << 'EOFLUA'
-- ===================================================================
-- Redis Rate Limiting - Atomic Operations
-- Auto-generated by bootstrap-rate-limiting.sh
-- ===================================================================

-- Token Bucket Implementation
-- KEYS[1]: bucket key
-- ARGV[1]: bucket size (max tokens)
-- ARGV[2]: refill rate (tokens per second)
-- ARGV[3]: requested tokens
-- ARGV[4]: current timestamp
local function token_bucket(keys, argv)
    local bucket_key = keys[1]
    local bucket_size = tonumber(argv[1])
    local refill_rate = tonumber(argv[2])
    local requested = tonumber(argv[3])
    local now = tonumber(argv[4])

    local bucket = redis.call('HMGET', bucket_key, 'tokens', 'last_refill')
    local tokens = tonumber(bucket[1]) or bucket_size
    local last_refill = tonumber(bucket[2]) or now

    -- Calculate refill
    local time_passed = now - last_refill
    local refill_amount = time_passed * refill_rate
    tokens = math.min(bucket_size, tokens + refill_amount)

    -- Check if request can be satisfied
    if tokens >= requested then
        tokens = tokens - requested
        redis.call('HMSET', bucket_key, 'tokens', tokens, 'last_refill', now)
        redis.call('EXPIRE', bucket_key, 3600)
        return {1, tokens, bucket_size - tokens}
    else
        return {0, tokens, bucket_size - tokens}
    end
end

-- Sliding Window Implementation
-- KEYS[1]: window key
-- ARGV[1]: window size (seconds)
-- ARGV[2]: max requests
-- ARGV[3]: current timestamp
local function sliding_window(keys, argv)
    local window_key = keys[1]
    local window_size = tonumber(argv[1])
    local max_requests = tonumber(argv[2])
    local now = tonumber(argv[3])

    local window_start = now - window_size

    -- Remove old entries
    redis.call('ZREMRANGEBYSCORE', window_key, '-inf', window_start)

    -- Count current requests
    local current_count = redis.call('ZCARD', window_key)

    if current_count < max_requests then
        redis.call('ZADD', window_key, now, now .. ':' .. math.random(1000000))
        redis.call('EXPIRE', window_key, window_size * 2)
        return {1, max_requests - current_count - 1, current_count + 1}
    else
        return {0, 0, current_count}
    end
end

-- Fixed Window Implementation
-- KEYS[1]: window key
-- ARGV[1]: window size (seconds)
-- ARGV[2]: max requests
-- ARGV[3]: current timestamp
local function fixed_window(keys, argv)
    local window_key = keys[1]
    local window_size = tonumber(argv[1])
    local max_requests = tonumber(argv[2])
    local now = tonumber(argv[3])

    local current_window = math.floor(now / window_size)
    local key = window_key .. ':' .. current_window

    local current_count = tonumber(redis.call('GET', key)) or 0

    if current_count < max_requests then
        redis.call('INCR', key)
        redis.call('EXPIRE', key, window_size * 2)
        return {1, max_requests - current_count - 1, current_count + 1}
    else
        return {0, 0, current_count}
    end
end

-- Leaky Bucket Implementation
-- KEYS[1]: bucket key
-- ARGV[1]: capacity
-- ARGV[2]: leak rate (requests per second)
-- ARGV[3]: current timestamp
local function leaky_bucket(keys, argv)
    local bucket_key = keys[1]
    local capacity = tonumber(argv[1])
    local leak_rate = tonumber(argv[2])
    local now = tonumber(argv[3])

    local bucket = redis.call('HMGET', bucket_key, 'level', 'last_leak')
    local level = tonumber(bucket[1]) or 0
    local last_leak = tonumber(bucket[2]) or now

    -- Calculate leak
    local time_passed = now - last_leak
    local leaked = time_passed * leak_rate
    level = math.max(0, level - leaked)

    -- Check if bucket has capacity
    if level < capacity then
        level = level + 1
        redis.call('HMSET', bucket_key, 'level', level, 'last_leak', now)
        redis.call('EXPIRE', bucket_key, 3600)
        return {1, capacity - level, level}
    else
        return {0, 0, level}
    end
end

-- Main dispatch function
local strategy = ARGV[1]

if strategy == 'token-bucket' then
    return token_bucket({KEYS[1]}, {ARGV[2], ARGV[3], ARGV[4], ARGV[5]})
elseif strategy == 'sliding-window' then
    return sliding_window({KEYS[1]}, {ARGV[2], ARGV[3], ARGV[4]})
elseif strategy == 'fixed-window' then
    return fixed_window({KEYS[1]}, {ARGV[2], ARGV[3], ARGV[4]})
elseif strategy == 'leaky-bucket' then
    return leaky_bucket({KEYS[1]}, {ARGV[2], ARGV[3], ARGV[4]})
else
    return {0, 0, 0, 'Unknown strategy'}
end
EOFLUA

    verify_file "$LUA_INIT_FILE"
    log_file_created "$SCRIPT_NAME" "config/rate-limiting/redis-init.lua"
    CREATED_FILES+=("config/rate-limiting/redis-init.lua")
fi

# ===================================================================
# Create Strategy Helper Lua Scripts
# ===================================================================

log_info "Creating strategy helper scripts..."

STRATEGIES_FILE="$PROJECT_ROOT/config/rate-limiting/strategies.lua"

if file_exists "$STRATEGIES_FILE"; then
    backup_file "$STRATEGIES_FILE"
    SKIPPED_FILES+=("config/rate-limiting/strategies.lua (backed up)")
    log_warning "strategies.lua already exists, backed up"
else
    cat > "$STRATEGIES_FILE" << 'EOFSTRATEGIES'
-- ===================================================================
-- Rate Limiting Strategies - Helper Functions
-- Auto-generated by bootstrap-rate-limiting.sh
-- ===================================================================

-- Get remaining quota for a key
-- KEYS[1]: rate limit key
-- ARGV[1]: strategy type
-- ARGV[2]: max limit
local function get_remaining_quota(keys, argv)
    local key = keys[1]
    local strategy = argv[1]
    local max_limit = tonumber(argv[2])

    if strategy == 'token-bucket' then
        local tokens = tonumber(redis.call('HGET', key, 'tokens')) or max_limit
        return tokens
    elseif strategy == 'sliding-window' then
        local count = redis.call('ZCARD', key)
        return math.max(0, max_limit - count)
    elseif strategy == 'fixed-window' then
        local count = tonumber(redis.call('GET', key)) or 0
        return math.max(0, max_limit - count)
    elseif strategy == 'leaky-bucket' then
        local level = tonumber(redis.call('HGET', key, 'level')) or 0
        return math.max(0, max_limit - level)
    end

    return 0
end

-- Reset rate limit for a key
-- KEYS[1]: rate limit key
local function reset_limit(keys, argv)
    redis.call('DEL', keys[1])
    return 1
end

-- Get rate limit info
-- KEYS[1]: rate limit key
-- ARGV[1]: strategy type
local function get_limit_info(keys, argv)
    local key = keys[1]
    local strategy = argv[1]

    local info = {}

    if strategy == 'token-bucket' then
        local bucket = redis.call('HMGET', key, 'tokens', 'last_refill')
        info.tokens = bucket[1]
        info.last_refill = bucket[2]
        info.ttl = redis.call('TTL', key)
    elseif strategy == 'sliding-window' then
        info.count = redis.call('ZCARD', key)
        info.oldest = redis.call('ZRANGE', key, 0, 0, 'WITHSCORES')
        info.ttl = redis.call('TTL', key)
    elseif strategy == 'fixed-window' then
        info.count = redis.call('GET', key)
        info.ttl = redis.call('TTL', key)
    elseif strategy == 'leaky-bucket' then
        local bucket = redis.call('HMGET', key, 'level', 'last_leak')
        info.level = bucket[1]
        info.last_leak = bucket[2]
        info.ttl = redis.call('TTL', key)
    end

    return cjson.encode(info)
end

-- Dispatch based on operation
local operation = ARGV[1]

if operation == 'get_remaining' then
    return get_remaining_quota({KEYS[1]}, {ARGV[2], ARGV[3]})
elseif operation == 'reset' then
    return reset_limit({KEYS[1]}, {})
elseif operation == 'get_info' then
    return get_limit_info({KEYS[1]}, {ARGV[2]})
else
    return redis.error_reply('Unknown operation: ' .. operation)
end
EOFSTRATEGIES

    verify_file "$STRATEGIES_FILE"
    log_file_created "$SCRIPT_NAME" "config/rate-limiting/strategies.lua"
    CREATED_FILES+=("config/rate-limiting/strategies.lua")
fi

# ===================================================================
# Create Endpoint-Specific Rate Limits
# ===================================================================

log_info "Creating endpoint configuration..."

ENDPOINTS_FILE="$PROJECT_ROOT/config/rate-limiting/endpoints.json"

if file_exists "$ENDPOINTS_FILE"; then
    backup_file "$ENDPOINTS_FILE"
    SKIPPED_FILES+=("config/rate-limiting/endpoints.json (backed up)")
    log_warning "endpoints.json already exists, backed up"
else
    cat > "$ENDPOINTS_FILE" << 'EOFENDPOINTS'
{
  "endpoints": [
    {
      "path": "/api/auth/login",
      "method": "POST",
      "strategy": "fixed-window",
      "limits": {
        "perMinute": 5,
        "perHour": 20
      },
      "identifierType": "ip",
      "blockDuration": 900,
      "description": "Prevent brute force login attempts"
    },
    {
      "path": "/api/auth/register",
      "method": "POST",
      "strategy": "fixed-window",
      "limits": {
        "perMinute": 3,
        "perHour": 10
      },
      "identifierType": "ip",
      "blockDuration": 3600,
      "description": "Prevent account creation abuse"
    },
    {
      "path": "/api/*",
      "method": "*",
      "strategy": "token-bucket",
      "limits": {
        "perMinute": 100,
        "perHour": 1000
      },
      "identifierType": "user",
      "fallbackIdentifier": "ip",
      "description": "General API rate limit"
    },
    {
      "path": "/api/search",
      "method": "GET",
      "strategy": "sliding-window",
      "limits": {
        "perMinute": 30,
        "perHour": 500
      },
      "identifierType": "user",
      "description": "Expensive search operations"
    },
    {
      "path": "/api/upload",
      "method": "POST",
      "strategy": "leaky-bucket",
      "limits": {
        "perMinute": 10,
        "perHour": 100
      },
      "identifierType": "user",
      "description": "File upload rate limiting"
    },
    {
      "path": "/api/export",
      "method": "GET",
      "strategy": "fixed-window",
      "limits": {
        "perMinute": 5,
        "perHour": 20
      },
      "identifierType": "user",
      "description": "Data export operations"
    }
  ],
  "whitelist": {
    "ips": [
      "127.0.0.1",
      "::1"
    ],
    "userIds": []
  },
  "blacklist": {
    "ips": [],
    "userIds": []
  }
}
EOFENDPOINTS

    verify_file "$ENDPOINTS_FILE"
    log_file_created "$SCRIPT_NAME" "config/rate-limiting/endpoints.json"
    CREATED_FILES+=("config/rate-limiting/endpoints.json")
fi

# ===================================================================
# Create Environment File
# ===================================================================

log_info "Creating rate limiting environment configuration..."

ENV_FILE="$PROJECT_ROOT/.env.rate-limiting"

if file_exists "$ENV_FILE"; then
    backup_file "$ENV_FILE"
    SKIPPED_FILES+=(".env.rate-limiting (backed up)")
    log_warning ".env.rate-limiting already exists, backed up"
else
    cat > "$ENV_FILE" << 'EOFENV'
# ===================================================================
# Rate Limiting Environment Configuration
# Auto-generated by bootstrap-rate-limiting.sh
# ===================================================================

# Redis Connection
REDIS_HOST=localhost
REDIS_PORT={{REDIS_PORT}}
REDIS_DB={{REDIS_DB}}
REDIS_PASSWORD={{REDIS_PASSWORD}}

# Rate Limiting Strategy
RATE_LIMIT_STRATEGY={{RATE_LIMIT_STRATEGY}}
RATE_LIMIT_WINDOW={{RATE_LIMIT_WINDOW}}
RATE_LIMIT_MAX_REQUESTS={{RATE_LIMIT_MAX_REQUESTS}}

# Redis Connection Pool
REDIS_POOL_MIN=2
REDIS_POOL_MAX=10
REDIS_IDLE_TIMEOUT=10000
REDIS_CONNECT_TIMEOUT=5000

# Monitoring
RATE_LIMIT_LOGGING=true
RATE_LIMIT_METRICS=true
RATE_LIMIT_ALERT_THRESHOLD=0.8

# Keys
RATE_LIMIT_KEY_PREFIX=ratelimit:
RATE_LIMIT_KEY_SEPARATOR=:

# Response Headers
RATE_LIMIT_HEADER_ENABLED=true
RATE_LIMIT_RETRY_AFTER_ENABLED=true

# Cleanup
RATE_LIMIT_CLEANUP_ENABLED=true
RATE_LIMIT_CLEANUP_INTERVAL=3600

# Development
RATE_LIMIT_DISABLED=false
RATE_LIMIT_DEBUG=false
EOFENV

    # Replace placeholders
    sed -i "s/{{REDIS_PORT}}/$REDIS_PORT/g" "$ENV_FILE"
    sed -i "s/{{REDIS_DB}}/$REDIS_DB/g" "$ENV_FILE"
    sed -i "s/{{REDIS_PASSWORD}}/$REDIS_PASSWORD/g" "$ENV_FILE"
    sed -i "s/{{RATE_LIMIT_STRATEGY}}/$RATE_LIMIT_STRATEGY/g" "$ENV_FILE"
    sed -i "s/{{RATE_LIMIT_WINDOW}}/$RATE_LIMIT_WINDOW/g" "$ENV_FILE"
    sed -i "s/{{RATE_LIMIT_MAX_REQUESTS}}/$RATE_LIMIT_MAX_REQUESTS/g" "$ENV_FILE"

    verify_file "$ENV_FILE"
    log_file_created "$SCRIPT_NAME" ".env.rate-limiting"
    CREATED_FILES+=(".env.rate-limiting")
fi

# ===================================================================
# Create Docker Compose Configuration
# ===================================================================

log_info "Creating Docker Compose configuration..."

DOCKER_COMPOSE_FILE="$PROJECT_ROOT/docker-compose.rate-limiting.yml"

if file_exists "$DOCKER_COMPOSE_FILE"; then
    backup_file "$DOCKER_COMPOSE_FILE"
    SKIPPED_FILES+=("docker-compose.rate-limiting.yml (backed up)")
    log_warning "docker-compose.rate-limiting.yml already exists, backed up"
else
    cat > "$DOCKER_COMPOSE_FILE" << 'EOFDOCKER'
version: '3.8'

services:
  redis:
    image: redis:{{REDIS_VERSION}}-alpine
    container_name: {{PROJECT_NAME}}-redis
    command: >
      redis-server
      --requirepass {{REDIS_PASSWORD}}
      --maxmemory 256mb
      --maxmemory-policy allkeys-lru
      --save ""
      --appendonly no
      --databases 16
    ports:
      - "{{REDIS_PORT}}:6379"
    volumes:
      - redis_data:/data
      - ./config/rate-limiting/redis-init.lua:/usr/local/share/redis/redis-init.lua:ro
      - ./config/rate-limiting/strategies.lua:/usr/local/share/redis/strategies.lua:ro
    environment:
      - REDIS_PASSWORD={{REDIS_PASSWORD}}
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
      start_period: 5s
    networks:
      - {{PROJECT_NAME}}-net
    restart: unless-stopped
    sysctls:
      - net.core.somaxconn=511
    ulimits:
      nofile:
        soft: 65536
        hard: 65536

volumes:
  redis_data:
    driver: local

networks:
  {{PROJECT_NAME}}-net:
    driver: bridge
EOFDOCKER

    # Replace placeholders
    sed -i "s/{{REDIS_VERSION}}/$REDIS_VERSION/g" "$DOCKER_COMPOSE_FILE"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$DOCKER_COMPOSE_FILE"
    sed -i "s/{{REDIS_PORT}}/$REDIS_PORT/g" "$DOCKER_COMPOSE_FILE"
    sed -i "s/{{REDIS_PASSWORD}}/$REDIS_PASSWORD/g" "$DOCKER_COMPOSE_FILE"

    verify_file "$DOCKER_COMPOSE_FILE"
    log_file_created "$SCRIPT_NAME" "docker-compose.rate-limiting.yml"
    CREATED_FILES+=("docker-compose.rate-limiting.yml")
fi

# ===================================================================
# Create Example Integration Code
# ===================================================================

log_info "Creating example integration code..."

EXAMPLE_FILE="$PROJECT_ROOT/config/rate-limiting/example-integration.js"

if file_exists "$EXAMPLE_FILE"; then
    backup_file "$EXAMPLE_FILE"
    SKIPPED_FILES+=("config/rate-limiting/example-integration.js (backed up)")
    log_warning "example-integration.js already exists, backed up"
else
    cat > "$EXAMPLE_FILE" << 'EOFEXAMPLE'
/**
 * Rate Limiting Integration Example
 * Auto-generated by bootstrap-rate-limiting.sh
 *
 * This file demonstrates how to integrate the Redis-based rate limiting
 * into your application using the generated Lua scripts.
 */

const Redis = require('ioredis');
const fs = require('fs');
const path = require('path');

// Load configuration
const config = require('./rate-limit.config.json');

// Create Redis client
const redis = new Redis({
  host: config.redis.host,
  port: config.redis.port,
  db: config.redis.db,
  password: config.redis.password,
  keyPrefix: config.redis.keyPrefix,
  connectTimeout: config.redis.connectTimeout,
  commandTimeout: config.redis.commandTimeout,
  retryStrategy: (times) => {
    const delay = Math.min(times * config.redis.retryStrategy.multiplier *
                          config.redis.retryStrategy.initialDelay,
                          config.redis.retryStrategy.maxDelay);
    return delay;
  }
});

// Load Lua scripts
const rateLimitScript = fs.readFileSync(
  path.join(__dirname, 'redis-init.lua'),
  'utf8'
);

// Define Lua script SHA (computed on first load)
let rateLimitScriptSha = null;

// Initialize scripts
async function initializeScripts() {
  rateLimitScriptSha = await redis.script('LOAD', rateLimitScript);
  console.log('Rate limiting scripts loaded:', rateLimitScriptSha);
}

/**
 * Check rate limit for a given identifier
 *
 * @param {string} identifier - User ID, IP address, or API key
 * @param {string} endpoint - Endpoint path
 * @param {object} options - Rate limit options
 * @returns {Promise<object>} Result with allowed, remaining, and reset info
 */
async function checkRateLimit(identifier, endpoint = 'default', options = {}) {
  const strategy = options.strategy || config.defaultStrategy;
  const limit = options.limit || config.globalLimits.perMinute;
  const window = options.window || config.keys.ttl;

  const key = `${identifier}:${endpoint}`;
  const now = Math.floor(Date.now() / 1000);

  try {
    // Execute rate limit check using Lua script
    const result = await redis.evalsha(
      rateLimitScriptSha,
      1,
      key,
      strategy,
      limit,
      10, // refill rate (for token bucket)
      1,  // requested tokens
      now
    );

    const [allowed, remaining, used] = result;

    return {
      allowed: allowed === 1,
      remaining: remaining,
      used: used,
      limit: limit,
      reset: now + window,
      retryAfter: allowed === 1 ? null : window
    };
  } catch (error) {
    console.error('Rate limit check failed:', error);
    // Fail open - allow request if rate limiting fails
    return {
      allowed: true,
      remaining: limit,
      used: 0,
      limit: limit,
      error: error.message
    };
  }
}

/**
 * Express.js middleware for rate limiting
 */
function rateLimitMiddleware(options = {}) {
  return async (req, res, next) => {
    // Determine identifier (user ID or IP)
    const identifier = req.user?.id ||
                      req.ip ||
                      req.connection.remoteAddress;

    const endpoint = req.path;

    try {
      const result = await checkRateLimit(identifier, endpoint, options);

      // Set rate limit headers
      if (config.headers) {
        res.set(config.headers.limit, result.limit);
        res.set(config.headers.remaining, result.remaining);
        res.set(config.headers.reset, result.reset);

        if (result.retryAfter) {
          res.set(config.headers.retryAfter, result.retryAfter);
        }
      }

      if (!result.allowed) {
        // Log rate limit violation
        if (config.monitoring.logViolations) {
          console.warn('Rate limit exceeded:', {
            identifier,
            endpoint,
            limit: result.limit,
            used: result.used
          });
        }

        return res.status(config.responses.statusCode).json({
          error: config.responses.message,
          retryAfter: result.retryAfter
        });
      }

      next();
    } catch (error) {
      console.error('Rate limit middleware error:', error);
      // Fail open on error
      next();
    }
  };
}

/**
 * Get rate limit status for an identifier
 */
async function getRateLimitStatus(identifier, endpoint = 'default') {
  const key = `${identifier}:${endpoint}`;
  const strategy = config.defaultStrategy;

  try {
    const result = await redis.eval(
      fs.readFileSync(path.join(__dirname, 'strategies.lua'), 'utf8'),
      1,
      key,
      'get_info',
      strategy
    );

    return JSON.parse(result);
  } catch (error) {
    console.error('Failed to get rate limit status:', error);
    return null;
  }
}

/**
 * Reset rate limit for an identifier
 */
async function resetRateLimit(identifier, endpoint = 'default') {
  const key = `${identifier}:${endpoint}`;

  try {
    await redis.del(key);
    return true;
  } catch (error) {
    console.error('Failed to reset rate limit:', error);
    return false;
  }
}

// Initialize on module load
initializeScripts().catch(console.error);

module.exports = {
  redis,
  checkRateLimit,
  rateLimitMiddleware,
  getRateLimitStatus,
  resetRateLimit
};
EOFEXAMPLE

    verify_file "$EXAMPLE_FILE"
    log_file_created "$SCRIPT_NAME" "config/rate-limiting/example-integration.js"
    CREATED_FILES+=("config/rate-limiting/example-integration.js")
fi

# ===================================================================
# Display Created Files
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#CREATED_FILES[@]} files created"

echo ""
log_section "Rate Limiting Bootstrap Complete"

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
echo -e "${BLUE}Rate Limiting Configuration:${NC}"
echo "  Redis Version: $REDIS_VERSION"
echo "  Redis Port: $REDIS_PORT"
echo "  Redis DB: $REDIS_DB"
echo "  Strategy: $RATE_LIMIT_STRATEGY"
echo "  Max Requests: $RATE_LIMIT_MAX_REQUESTS / ${RATE_LIMIT_WINDOW}s"
echo ""

echo -e "${BLUE}Available Strategies:${NC}"
echo "  • token-bucket: Allows bursts but enforces average rate"
echo "  • sliding-window: Smooths traffic over time window"
echo "  • leaky-bucket: Processes requests at constant rate"
echo "  • fixed-window: Simple per-minute limit"
echo ""

echo -e "${BLUE}Quick Start:${NC}"
echo "  1. Start Redis container:"
echo "     docker-compose -f docker-compose.rate-limiting.yml up -d"
echo ""
echo "  2. Verify Redis connection:"
echo "     docker-compose -f docker-compose.rate-limiting.yml exec redis redis-cli -a $REDIS_PASSWORD ping"
echo ""
echo "  3. Test rate limiting:"
echo "     docker-compose -f docker-compose.rate-limiting.yml exec redis redis-cli -a $REDIS_PASSWORD --eval config/rate-limiting/redis-init.lua"
echo ""
echo "  4. Load Lua scripts into Redis:"
echo "     docker-compose -f docker-compose.rate-limiting.yml exec redis redis-cli -a $REDIS_PASSWORD SCRIPT LOAD \"\$(cat config/rate-limiting/redis-init.lua)\""
echo ""

echo -e "${BLUE}Integration:${NC}"
echo "  • Configuration: config/rate-limiting/rate-limit.config.json"
echo "  • Endpoints: config/rate-limiting/endpoints.json"
echo "  • Example Code: config/rate-limiting/example-integration.js"
echo "  • Lua Scripts: config/rate-limiting/*.lua"
echo ""

echo -e "${BLUE}Files Created:${NC}"
echo "  Configuration: ${#CREATED_FILES[@]} files"
echo "  Location: $PROJECT_ROOT"
echo ""

echo -e "${YELLOW}Security Reminder:${NC}"
echo "  • Change REDIS_PASSWORD in .env.rate-limiting"
echo "  • Never commit .env.rate-limiting to git"
echo "  • Use Redis AUTH in production"
echo "  • Enable TLS for production deployments"
echo "  • Monitor rate limit violations"
echo "  • Set up alerts for abuse patterns"
echo ""

echo -e "${BLUE}Monitoring:${NC}"
echo "  • Check Redis stats: INFO stats"
echo "  • Monitor key count: DBSIZE"
echo "  • View rate limit keys: SCAN 0 MATCH ratelimit:*"
echo "  • Check memory usage: INFO memory"
echo ""

show_log_location
