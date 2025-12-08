/**
 * New Relic Agent Configuration
 * Documentation: https://docs.newrelic.com/docs/apm/agents/nodejs-agent/installation-configuration/nodejs-agent-configuration/
 */
'use strict'

exports.config = {
  /**
   * Application name
   * This name will appear in the New Relic UI
   */
  app_name: ['{{PROJECT_NAME}}'],

  /**
   * License key
   * Get this from your New Relic account settings
   */
  license_key: '{{NEWRELIC_LICENSE_KEY}}',

  /**
   * Logging configuration
   */
  logging: {
    level: '{{NEWRELIC_LOG_LEVEL}}',
    filepath: 'stdout',
  },

  /**
   * Transaction tracer configuration
   */
  transaction_tracer: {
    enabled: {{NEWRELIC_TRANSACTION_TRACER}},
    transaction_threshold: 'apdex_f',
    record_sql: 'obfuscated',
    explain_threshold: 500,
  },

  /**
   * Error collector configuration
   */
  error_collector: {
    enabled: {{NEWRELIC_ERROR_COLLECTOR}},
    ignore_status_codes: [404],
    expected_messages: {},
    expected_classes: [],
  },

  /**
   * Distributed tracing
   */
  distributed_tracing: {
    enabled: {{NEWRELIC_DISTRIBUTED_TRACING}},
  },

  /**
   * Slow SQL queries
   */
  slow_sql: {
    enabled: {{NEWRELIC_SLOW_SQL}},
  },

  /**
   * Browser monitoring (RUM)
   */
  browser_monitoring: {
    enable: {{NEWRELIC_BROWSER_MONITORING}},
  },

  /**
   * Custom instrumentation
   */
  custom_instrumentation: {},

  /**
   * Application logging
   */
  application_logging: {
    enabled: {{NEWRELIC_APP_LOGGING}},
    forwarding: {
      enabled: {{NEWRELIC_LOG_FORWARDING}},
      max_samples_stored: 10000,
    },
    metrics: {
      enabled: {{NEWRELIC_LOG_METRICS}},
    },
    local_decorating: {
      enabled: {{NEWRELIC_LOG_DECORATING}},
    },
  },

  /**
   * Labels for filtering in New Relic UI
   */
  labels: {
    environment: '{{ENVIRONMENT}}',
    team: '{{TEAM_NAME}}',
  },
}
