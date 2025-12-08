# Test Suite Templates

Generic, reusable test suite templates for any project. Supports pytest, Jest, Vitest, Playwright, and Puppeteer.

## Quick Start

```bash
# Install full test suite in current project
./bootstrap-test-suite.sh

# Install minimal suite (starter tests only)
./bootstrap-test-suite.sh --minimal

# Preview what would be installed
./bootstrap-test-suite.sh --dry-run

# Install specific frameworks
./bootstrap-test-suite.sh --frameworks=pytest,vitest,playwright
```

## What's Included

### Test Categories

| Category | Description | Frameworks |
|----------|-------------|------------|
| **Unit** | Fast, isolated tests for individual functions/classes | pytest |
| **Integration** | API validation, CLI testing, service integration | pytest |
| **E2E** | End-to-end system tests | pytest |
| **Browser** | UI testing with headless browsers | Jest+Puppeteer, Playwright |

### Framework Configurations

| Framework | Config File | Setup File |
|-----------|-------------|------------|
| pytest | `pytest.ini` | `tests/conftest.py` |
| Jest | `tests/jest.config.js` | `tests/jest.setup.js` |
| Vitest | `vitest.config.ts` | `tests/vitest.setup.ts` |
| Playwright | `playwright.config.ts` | `tests/playwright.setup.ts` |

## Directory Structure

After installation:

```
your-project/
├── tests/
│   ├── conftest.py          # Pytest fixtures and configuration
│   ├── jest.config.js       # Jest configuration
│   ├── TEST_CONTRACT.md     # Test coverage requirements
│   ├── patterns.md          # Testing patterns guide
│   ├── unit/                # Unit tests
│   │   ├── test_storage.py
│   │   └── test_*.py
│   ├── integration/         # Integration tests
│   │   ├── test_api_validation.py
│   │   ├── test_cli.py
│   │   └── test_*.py
│   ├── e2e/                 # End-to-end tests
│   │   ├── test_health_endpoint.py
│   │   └── test_*.py
│   ├── browser/             # Browser/UI tests
│   │   ├── helpers/
│   │   ├── test_*.test.js
│   │   └── README.md
│   └── logs/                # Test output (gitignored)
├── pytest.ini               # Root pytest config
├── vitest.config.ts         # Vitest config (if selected)
└── playwright.config.ts     # Playwright config (if selected)
```

## Template Variables

The templates use placeholders that are replaced during installation:

| Variable | Description | Example |
|----------|-------------|---------|
| `{{PROJECT_NAME}}` | kebab-case project name | `my-app` |
| `{{PROJECT_NAME_PASCAL}}` | PascalCase | `MyApp` |
| `{{PROJECT_NAME_SNAKE}}` | snake_case | `my_app` |
| `{{PROJECT_NAME_UPPER}}` | SCREAMING_SNAKE | `MY_APP` |
| `{{SRC_DIR}}` | Source directory | `src` |
| `{{TESTS_DIR}}` | Tests directory | `tests` |
| `{{API_PORT}}` | API port | `5000` |
| `{{API_BASE_URL}}` | Full API URL | `http://localhost:5000` |
| `{{TZ}}` | Timezone | `America/Chicago` |

## Configuration

### test-suite.config

Copy and customize for your project:

```bash
# Project identification
PROJECT_NAME="my-app"
PROJECT_NAME_PASCAL="MyApp"

# Directory structure
SRC_DIR="src"
TESTS_DIR="tests"

# API settings
API_PORT="5000"

# Framework selection
PYTHON_FRAMEWORK="pytest"
JS_FRAMEWORK="jest"           # or "vitest"
BROWSER_FRAMEWORK="puppeteer" # or "playwright" or "none"

# Mode
INSTALL_MODE="full"           # or "minimal"
```

## Installation Modes

### Full Mode (default)

Installs complete test suite with:
- All test categories (unit, integration, e2e, browser)
- Storage-based fixtures (requires your project to have a Storage class)
- Comprehensive test patterns

```bash
./bootstrap-test-suite.sh --full
```

### Minimal Mode

Installs starter tests only:
- Basic example tests
- No storage dependencies
- Good starting point for new projects

```bash
./bootstrap-test-suite.sh --minimal
```

## Framework Detection

The script auto-detects frameworks from your project:

- **pytest**: If `pyproject.toml`, `requirements.txt`, or `.py` files exist
- **jest**: If `package.json` contains `"jest"`
- **vitest**: If `package.json` contains `"vitest"`
- **playwright**: If `package.json` contains `"@playwright/test"`
- **puppeteer**: If `package.json` contains `"puppeteer"`

Override with:
```bash
./bootstrap-test-suite.sh --frameworks=pytest,vitest
```

## Running Tests

### Python (pytest)

```bash
# Run all tests
pytest

# Run specific category
pytest tests/unit/
pytest tests/integration/
pytest tests/e2e/

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test
pytest tests/unit/test_storage.py -v
```

### JavaScript (Jest)

```bash
# Run all tests
npm test

# Run browser tests
npm run test:browser

# Run with coverage
npm test -- --coverage
```

### JavaScript (Vitest)

```bash
# Run all tests
npm test

# Run in watch mode
npm test -- --watch

# Run with coverage
npm test -- --coverage
```

### Browser (Playwright)

```bash
# Run all browsers
npx playwright test

# Run specific browser
npx playwright test --project=chromium

# Run with UI
npx playwright test --ui

# Generate report
npx playwright show-report
```

## Customization

### Adding Project-Specific Fixtures

Edit `tests/conftest.py` to add fixtures for your project:

```python
@pytest.fixture
def my_service(storage):
    """Create instance of your service."""
    return MyService(storage=storage)
```

### Storage Integration

The templates include a conditional Storage import. If your project has a `src/storage.py` module with a `Storage` class, the fixtures will work automatically. Otherwise, storage-dependent tests will be skipped.

### Browser Test Configuration

Edit `tests/browser/helpers/puppeteer_setup.js` or `playwright.config.ts` to customize:
- Base URL
- Browser options
- Timeouts
- Screenshots/videos

## Test Contract

See `tests/TEST_CONTRACT.md` for coverage requirements:

- **API**: Every endpoint needs validation tests
- **CLI**: Every command needs smoke tests
- **Storage**: Every public method needs unit tests
- **UI**: Every page needs browser smoke tests

## Logs and Reports

Test artifacts are saved to `tests/logs/`:

```
tests/logs/
├── latest/              # Symlink to most recent run
│   ├── pytest.log
│   ├── junit_report.xml
│   ├── test_summary.txt
│   └── browser-test-report.html
└── MM-DD-YYYY_HH-MMam/  # Timestamped directories
```

Old log directories are automatically cleaned up (keeps last 3 runs).

## Dependencies

### Python

```bash
pip install pytest pytest-asyncio pytest-cov
```

### Jest + Puppeteer

```bash
npm install --save-dev jest puppeteer jest-html-reporter
```

### Vitest

```bash
npm install --save-dev vitest @vitest/coverage-v8
```

### Playwright

```bash
npm install --save-dev @playwright/test
npx playwright install
```

## Troubleshooting

### Storage module not found

If tests skip with "Storage module not found":
1. Ensure your project has `src/storage.py` with a `Storage` class
2. Or use `--minimal` mode for projects without storage

### Import errors

Ensure your `src/` directory is in the Python path. The `conftest.py` adds it automatically, but you may need to run pytest from the project root.

### Browser tests fail to connect

1. Ensure your server is running on the configured port
2. Check the `{{PROJECT_NAME_UPPER}}_URL` environment variable
3. For CI, use the `webServer` option in Playwright config

## Contributing

To modify the templates:

1. Edit files in `__bootbuild/templates/test/`
2. Use `{{VARIABLE}}` syntax for project-specific values
3. Test with `./bootstrap-test-suite.sh --dry-run`
4. Update this README if adding new features
