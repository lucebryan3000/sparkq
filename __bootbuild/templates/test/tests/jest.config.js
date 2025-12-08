/**
 * Jest configuration for Puppeteer-based browser tests
 * Run with: npm run test:browser
 */
export default {
  testEnvironment: 'node',
  testMatch: ['**/{{TESTS_DIR}}/browser/**/*.test.js'],
  testTimeout: 30000, // 30s for browser tests
  verbose: true,
  collectCoverage: false,
  maxWorkers: 1, // Run browser tests serially to avoid port conflicts
  transform: {},
  testEnvironmentOptions: {
    customExportConditions: ['node', 'node-addons'],
  },

  // Clear mocks between tests
  clearMocks: true,
  resetMocks: true,
  restoreMocks: true,

  // Reporting
  reporters: [
    'default',
    ['jest-html-reporter', {
      pageTitle: '{{PROJECT_NAME_PASCAL}} Browser Test Report',
      outputPath: '{{TESTS_DIR}}/logs/latest/browser-test-report.html',
      includeFailureMsg: true,
      includeConsoleLog: true,
    }],
  ],
};
