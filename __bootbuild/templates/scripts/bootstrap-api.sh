#!/bin/bash

# ===================================================================
# bootstrap-api.sh
#
# Bootstrap API configuration and standards
# Creates OpenAPI/Swagger specs, GraphQL schemas, API routes, and mock server
# ===================================================================

set -euo pipefail

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-api.sh"

# Get project root
PROJECT_ROOT=$(get_project_root "${1:-.}")
TEMPLATE_ROOT="${TEMPLATES_DIR}/root/api"

# Script identifier
SCRIPT_NAME="bootstrap-api"

# Pre-execution confirmation
pre_execution_confirm "$SCRIPT_NAME" "API Configuration" \
    "openapi.yaml" "graphql/schema.graphql" \
    "api/ directory" "mock-server.js"

# ===================================================================
# Step 1: Validation
# ===================================================================

log_info "Bootstrapping API configuration..."

# Verify project directory exists
if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_fatal "Project directory not found: $PROJECT_ROOT"
fi

# Verify project directory is writable
if [[ ! -w "$PROJECT_ROOT" ]]; then
    log_fatal "Project directory is not writable: $PROJECT_ROOT"
fi

# ===================================================================
# Step 2: Create API directory structure
# ===================================================================

log_info "Creating API directory structure..."

# Create main API directories
for dir in api api/routes api/middleware api/graphql api/v1 api/v1/routes api/mock; do
    if [[ ! -d "$PROJECT_ROOT/$dir" ]]; then
        if mkdir -p "$PROJECT_ROOT/$dir"; then
            track_created "$dir/"
            log_dir_created "$SCRIPT_NAME" "$dir/"
        else
            log_fatal "Failed to create directory: $dir"
        fi
    else
        track_skipped "$dir/"
        log_warning "Directory already exists: $dir"
    fi
done

# ===================================================================
# Step 3: Create OpenAPI specification
# ===================================================================

log_info "Creating OpenAPI specification..."

if [[ -f "$PROJECT_ROOT/openapi.yaml" ]]; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/openapi.yaml"
    else
        track_skipped "openapi.yaml"
        log_warning "openapi.yaml already exists, skipping"
    fi
fi

if [[ ! -f "$PROJECT_ROOT/openapi.yaml" ]]; then
    if cat > "$PROJECT_ROOT/openapi.yaml" << 'EOFOPENAPI'
openapi: 3.0.3
info:
  title: API Documentation
  description: RESTful API specification
  version: 1.0.0
  contact:
    name: API Support
    email: support@example.com

servers:
  - url: http://localhost:3000/api/v1
    description: Development server
  - url: https://api.example.com/v1
    description: Production server

paths:
  /health:
    get:
      summary: Health check endpoint
      description: Returns API health status
      operationId: healthCheck
      tags:
        - System
      responses:
        '200':
          description: API is healthy
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    example: ok
                  timestamp:
                    type: string
                    format: date-time
                  version:
                    type: string
                    example: 1.0.0

  /api/v1/example:
    get:
      summary: Example endpoint
      description: Template for GET requests
      operationId: getExample
      tags:
        - Example
      parameters:
        - name: id
          in: query
          description: Resource ID
          required: false
          schema:
            type: string
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/ExampleResource'
                  meta:
                    $ref: '#/components/schemas/Meta'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '500':
          $ref: '#/components/responses/InternalError'

    post:
      summary: Create resource
      description: Template for POST requests
      operationId: createExample
      tags:
        - Example
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateExampleRequest'
      responses:
        '201':
          description: Resource created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ExampleResource'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '500':
          $ref: '#/components/responses/InternalError'

components:
  schemas:
    ExampleResource:
      type: object
      required:
        - id
        - name
      properties:
        id:
          type: string
          format: uuid
          description: Unique identifier
        name:
          type: string
          description: Resource name
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time

    CreateExampleRequest:
      type: object
      required:
        - name
      properties:
        name:
          type: string
          minLength: 1
          maxLength: 255

    Meta:
      type: object
      properties:
        page:
          type: integer
          minimum: 1
        perPage:
          type: integer
          minimum: 1
          maximum: 100
        total:
          type: integer
          minimum: 0

    Error:
      type: object
      required:
        - error
      properties:
        error:
          type: object
          required:
            - message
          properties:
            message:
              type: string
            code:
              type: string
            details:
              type: object

  responses:
    BadRequest:
      description: Bad request
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error:
              message: Invalid request parameters
              code: BAD_REQUEST

    Unauthorized:
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error:
              message: Authentication required
              code: UNAUTHORIZED

    InternalError:
      description: Internal server error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error:
              message: An unexpected error occurred
              code: INTERNAL_ERROR

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

security:
  - bearerAuth: []
EOFOPENAPI
    then
        if verify_file "$PROJECT_ROOT/openapi.yaml"; then
            track_created "openapi.yaml"
            log_file_created "$SCRIPT_NAME" "openapi.yaml"
        fi
    else
        log_fatal "Failed to create openapi.yaml"
    fi
fi

# ===================================================================
# Step 4: Create GraphQL schema
# ===================================================================

log_info "Creating GraphQL schema..."

if [[ -f "$PROJECT_ROOT/api/graphql/schema.graphql" ]]; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/api/graphql/schema.graphql"
    else
        track_skipped "api/graphql/schema.graphql"
        log_warning "GraphQL schema already exists, skipping"
    fi
fi

if [[ ! -f "$PROJECT_ROOT/api/graphql/schema.graphql" ]]; then
    if cat > "$PROJECT_ROOT/api/graphql/schema.graphql" << 'EOFGRAPHQL'
"""
Root Query type
"""
type Query {
  """
  Health check endpoint
  """
  health: HealthStatus!

  """
  Get example resource by ID
  """
  example(id: ID!): Example

  """
  List example resources with pagination
  """
  examples(
    page: Int = 1
    perPage: Int = 10
  ): ExampleConnection!
}

"""
Root Mutation type
"""
type Mutation {
  """
  Create a new example resource
  """
  createExample(input: CreateExampleInput!): Example!

  """
  Update an existing example resource
  """
  updateExample(id: ID!, input: UpdateExampleInput!): Example!

  """
  Delete an example resource
  """
  deleteExample(id: ID!): Boolean!
}

"""
Example resource type
"""
type Example {
  id: ID!
  name: String!
  description: String
  createdAt: DateTime!
  updatedAt: DateTime!
}

"""
Input for creating an example resource
"""
input CreateExampleInput {
  name: String!
  description: String
}

"""
Input for updating an example resource
"""
input UpdateExampleInput {
  name: String
  description: String
}

"""
Paginated connection for examples
"""
type ExampleConnection {
  edges: [ExampleEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

"""
Example edge in connection
"""
type ExampleEdge {
  node: Example!
  cursor: String!
}

"""
Pagination information
"""
type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}

"""
Health status response
"""
type HealthStatus {
  status: String!
  timestamp: DateTime!
  version: String!
}

"""
ISO-8601 DateTime scalar
"""
scalar DateTime
EOFGRAPHQL
    then
        if verify_file "$PROJECT_ROOT/api/graphql/schema.graphql"; then
            track_created "api/graphql/schema.graphql"
            log_file_created "$SCRIPT_NAME" "api/graphql/schema.graphql"
        fi
    else
        log_fatal "Failed to create GraphQL schema"
    fi
fi

# ===================================================================
# Step 5: Create API route template
# ===================================================================

log_info "Creating API route template..."

if [[ -f "$PROJECT_ROOT/api/v1/routes/example.ts" ]]; then
    track_skipped "api/v1/routes/example.ts"
    log_warning "API route template already exists, skipping"
fi

if [[ ! -f "$PROJECT_ROOT/api/v1/routes/example.ts" ]]; then
    if cat > "$PROJECT_ROOT/api/v1/routes/example.ts" << 'EOFROUTE'
/**
 * Example API Route
 *
 * Demonstrates REST API conventions:
 * - GET /api/v1/example - List resources
 * - GET /api/v1/example/:id - Get resource by ID
 * - POST /api/v1/example - Create resource
 * - PUT /api/v1/example/:id - Update resource
 * - DELETE /api/v1/example/:id - Delete resource
 */

import { Router, Request, Response } from 'express'

const router = Router()

// List resources
router.get('/', async (req: Request, res: Response) => {
  try {
    const { page = 1, perPage = 10 } = req.query

    // TODO: Implement database query
    const data = []
    const total = 0

    res.json({
      data,
      meta: {
        page: Number(page),
        perPage: Number(perPage),
        total
      }
    })
  } catch (error) {
    res.status(500).json({
      error: {
        message: 'Failed to fetch resources',
        code: 'INTERNAL_ERROR'
      }
    })
  }
})

// Get resource by ID
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params

    // TODO: Implement database query
    const resource = null

    if (!resource) {
      return res.status(404).json({
        error: {
          message: 'Resource not found',
          code: 'NOT_FOUND'
        }
      })
    }

    res.json(resource)
  } catch (error) {
    res.status(500).json({
      error: {
        message: 'Failed to fetch resource',
        code: 'INTERNAL_ERROR'
      }
    })
  }
})

// Create resource
router.post('/', async (req: Request, res: Response) => {
  try {
    const { name } = req.body

    // Validation
    if (!name) {
      return res.status(400).json({
        error: {
          message: 'Name is required',
          code: 'VALIDATION_ERROR'
        }
      })
    }

    // TODO: Implement database insertion
    const resource = {
      id: 'generated-id',
      name,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    }

    res.status(201).json(resource)
  } catch (error) {
    res.status(500).json({
      error: {
        message: 'Failed to create resource',
        code: 'INTERNAL_ERROR'
      }
    })
  }
})

// Update resource
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params
    const { name } = req.body

    // TODO: Implement database update
    const resource = null

    if (!resource) {
      return res.status(404).json({
        error: {
          message: 'Resource not found',
          code: 'NOT_FOUND'
        }
      })
    }

    res.json(resource)
  } catch (error) {
    res.status(500).json({
      error: {
        message: 'Failed to update resource',
        code: 'INTERNAL_ERROR'
      }
    })
  }
})

// Delete resource
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params

    // TODO: Implement database deletion
    const deleted = false

    if (!deleted) {
      return res.status(404).json({
        error: {
          message: 'Resource not found',
          code: 'NOT_FOUND'
        }
      })
    }

    res.status(204).send()
  } catch (error) {
    res.status(500).json({
      error: {
        message: 'Failed to delete resource',
        code: 'INTERNAL_ERROR'
      }
    })
  }
})

export default router
EOFROUTE
    then
        if verify_file "$PROJECT_ROOT/api/v1/routes/example.ts"; then
            track_created "api/v1/routes/example.ts"
            log_file_created "$SCRIPT_NAME" "api/v1/routes/example.ts"
        fi
    else
        log_fatal "Failed to create API route template"
    fi
fi

# ===================================================================
# Step 6: Create middleware templates
# ===================================================================

log_info "Creating API middleware..."

# Error handler middleware
if [[ ! -f "$PROJECT_ROOT/api/middleware/error-handler.ts" ]]; then
    if cat > "$PROJECT_ROOT/api/middleware/error-handler.ts" << 'EOFERROR'
/**
 * Global error handler middleware
 */

import { Request, Response, NextFunction } from 'express'

export interface ApiError extends Error {
  statusCode?: number
  code?: string
  details?: unknown
}

export const errorHandler = (
  error: ApiError,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const statusCode = error.statusCode || 500
  const code = error.code || 'INTERNAL_ERROR'

  console.error('API Error:', {
    statusCode,
    code,
    message: error.message,
    stack: error.stack,
    path: req.path,
    method: req.method
  })

  res.status(statusCode).json({
    error: {
      message: error.message,
      code,
      ...(error.details && { details: error.details })
    }
  })
}
EOFERROR
    then
        if verify_file "$PROJECT_ROOT/api/middleware/error-handler.ts"; then
            track_created "api/middleware/error-handler.ts"
            log_file_created "$SCRIPT_NAME" "api/middleware/error-handler.ts"
        fi
    fi
fi

# Request logging middleware
if [[ ! -f "$PROJECT_ROOT/api/middleware/logger.ts" ]]; then
    if cat > "$PROJECT_ROOT/api/middleware/logger.ts" << 'EOFLOGGER'
/**
 * Request logging middleware
 */

import { Request, Response, NextFunction } from 'express'

export const requestLogger = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const start = Date.now()

  res.on('finish', () => {
    const duration = Date.now() - start
    console.log({
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      timestamp: new Date().toISOString()
    })
  })

  next()
}
EOFLOGGER
    then
        if verify_file "$PROJECT_ROOT/api/middleware/logger.ts"; then
            track_created "api/middleware/logger.ts"
            log_file_created "$SCRIPT_NAME" "api/middleware/logger.ts"
        fi
    fi
fi

# Validation middleware
if [[ ! -f "$PROJECT_ROOT/api/middleware/validate.ts" ]]; then
    if cat > "$PROJECT_ROOT/api/middleware/validate.ts" << 'EOFVALIDATE'
/**
 * Request validation middleware
 */

import { Request, Response, NextFunction } from 'express'
import { z, ZodSchema } from 'zod'

export const validate = (schema: ZodSchema) => {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      schema.parse(req.body)
      next()
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({
          error: {
            message: 'Validation failed',
            code: 'VALIDATION_ERROR',
            details: error.errors
          }
        })
      }
      next(error)
    }
  }
}
EOFVALIDATE
    then
        if verify_file "$PROJECT_ROOT/api/middleware/validate.ts"; then
            track_created "api/middleware/validate.ts"
            log_file_created "$SCRIPT_NAME" "api/middleware/validate.ts"
        fi
    fi
fi

# ===================================================================
# Step 7: Create mock server
# ===================================================================

log_info "Creating mock API server..."

if [[ -f "$PROJECT_ROOT/api/mock/server.js" ]]; then
    track_skipped "api/mock/server.js"
    log_warning "Mock server already exists, skipping"
fi

if [[ ! -f "$PROJECT_ROOT/api/mock/server.js" ]]; then
    if cat > "$PROJECT_ROOT/api/mock/server.js" << 'EOFMOCK'
/**
 * Mock API Server
 *
 * Usage: node api/mock/server.js
 * Server will run on http://localhost:3001
 */

const express = require('express')
const cors = require('cors')

const app = express()
const PORT = process.env.MOCK_PORT || 3001

// Middleware
app.use(cors())
app.use(express.json())

// Request logging
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`)
  next()
})

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  })
})

// Mock data
const mockData = [
  { id: '1', name: 'Example 1', createdAt: new Date().toISOString() },
  { id: '2', name: 'Example 2', createdAt: new Date().toISOString() },
  { id: '3', name: 'Example 3', createdAt: new Date().toISOString() }
]

// Mock endpoints
app.get('/api/v1/example', (req, res) => {
  setTimeout(() => {
    res.json({
      data: mockData,
      meta: { page: 1, perPage: 10, total: mockData.length }
    })
  }, 500) // Simulate network delay
})

app.get('/api/v1/example/:id', (req, res) => {
  const item = mockData.find(d => d.id === req.params.id)
  if (!item) {
    return res.status(404).json({
      error: { message: 'Not found', code: 'NOT_FOUND' }
    })
  }
  setTimeout(() => {
    res.json(item)
  }, 300)
})

app.post('/api/v1/example', (req, res) => {
  const newItem = {
    id: String(mockData.length + 1),
    ...req.body,
    createdAt: new Date().toISOString()
  }
  mockData.push(newItem)
  setTimeout(() => {
    res.status(201).json(newItem)
  }, 400)
})

app.put('/api/v1/example/:id', (req, res) => {
  const index = mockData.findIndex(d => d.id === req.params.id)
  if (index === -1) {
    return res.status(404).json({
      error: { message: 'Not found', code: 'NOT_FOUND' }
    })
  }
  mockData[index] = { ...mockData[index], ...req.body }
  setTimeout(() => {
    res.json(mockData[index])
  }, 400)
})

app.delete('/api/v1/example/:id', (req, res) => {
  const index = mockData.findIndex(d => d.id === req.params.id)
  if (index === -1) {
    return res.status(404).json({
      error: { message: 'Not found', code: 'NOT_FOUND' }
    })
  }
  mockData.splice(index, 1)
  setTimeout(() => {
    res.status(204).send()
  }, 300)
})

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: { message: 'Endpoint not found', code: 'NOT_FOUND' }
  })
})

// Start server
app.listen(PORT, () => {
  console.log(`Mock API server running on http://localhost:${PORT}`)
  console.log(`Health check: http://localhost:${PORT}/health`)
  console.log(`Example endpoint: http://localhost:${PORT}/api/v1/example`)
})
EOFMOCK
    then
        if verify_file "$PROJECT_ROOT/api/mock/server.js"; then
            track_created "api/mock/server.js"
            log_file_created "$SCRIPT_NAME" "api/mock/server.js"
        fi
    else
        log_fatal "Failed to create mock server"
    fi
fi

# ===================================================================
# Step 8: Create API documentation
# ===================================================================

log_info "Creating API documentation..."

if [[ ! -f "$PROJECT_ROOT/api/README.md" ]]; then
    if cat > "$PROJECT_ROOT/api/README.md" << 'EOFDOCS'
# API Documentation

## Overview

This directory contains API configuration, routes, and documentation.

## Structure

```
api/
├── v1/                 # API version 1
│   └── routes/        # Route handlers
├── graphql/           # GraphQL schema
├── middleware/        # Express middleware
├── mock/              # Mock server for development
└── README.md          # This file
```

## OpenAPI Specification

The API is documented using OpenAPI 3.0 specification in `openapi.yaml`.

View documentation:
- Use [Swagger UI](https://swagger.io/tools/swagger-ui/)
- Use [Redoc](https://redocly.github.io/redoc/)
- Use VS Code extension: [OpenAPI (Swagger) Editor](https://marketplace.visualstudio.com/items?itemName=42Crunch.vscode-openapi)

## GraphQL Schema

GraphQL schema is defined in `api/graphql/schema.graphql`.

## REST API Conventions

### Versioning
- API versions in URL: `/api/v1/resource`
- Major version only in path
- Breaking changes require new version

### HTTP Methods
- `GET` - Retrieve resource(s)
- `POST` - Create resource
- `PUT` - Update resource (full replacement)
- `PATCH` - Update resource (partial)
- `DELETE` - Delete resource

### Response Format
```json
{
  "data": {},
  "meta": {
    "page": 1,
    "perPage": 10,
    "total": 100
  }
}
```

### Error Format
```json
{
  "error": {
    "message": "Error description",
    "code": "ERROR_CODE",
    "details": {}
  }
}
```

### Status Codes
- `200` - Success
- `201` - Created
- `204` - No Content
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

## Mock Server

Start mock server for development:
```bash
node api/mock/server.js
```

Mock server runs on `http://localhost:3001`

## Middleware

### Error Handler
Global error handling middleware in `middleware/error-handler.ts`

### Logger
Request logging middleware in `middleware/logger.ts`

### Validation
Zod-based validation middleware in `middleware/validate.ts`

## Development

### Adding a New Endpoint

1. Define in OpenAPI spec (`openapi.yaml`)
2. Create route handler in `api/v1/routes/`
3. Add validation schema using Zod
4. Add to mock server (optional)
5. Update this documentation

### Testing

Use the mock server to test API integration without backend:
```bash
node api/mock/server.js
```

### Documentation

Keep OpenAPI spec and GraphQL schema in sync with implementation.
EOFDOCS
    then
        if verify_file "$PROJECT_ROOT/api/README.md"; then
            track_created "api/README.md"
            log_file_created "$SCRIPT_NAME" "api/README.md"
        fi
    fi
fi

# ===================================================================
# Step 9: Validation & Testing (Self-Testing Protocol)
# ===================================================================

validate_bootstrap() {
    local errors=0

    log_info "Validating bootstrap configuration..."
    echo ""

    # Test 1: Required directories
    log_info "Checking directory structure..."
    for dir in api api/v1 api/v1/routes api/middleware api/graphql api/mock; do
        if [[ -d "$PROJECT_ROOT/$dir" ]]; then
            log_success "Directory: $dir exists"
        else
            log_error "Directory: $dir not found"
            errors=$((errors + 1))
        fi
    done

    # Test 2: OpenAPI specification
    log_info "Checking OpenAPI specification..."
    if [[ -f "$PROJECT_ROOT/openapi.yaml" ]]; then
        log_success "File: openapi.yaml exists"

        if grep -q "openapi: 3.0" "$PROJECT_ROOT/openapi.yaml"; then
            log_success "OpenAPI: Version 3.0 specified"
        else
            log_warning "OpenAPI: Version not found"
            errors=$((errors + 1))
        fi

        if grep -q "paths:" "$PROJECT_ROOT/openapi.yaml"; then
            log_success "OpenAPI: Has paths defined"
        else
            log_warning "OpenAPI: No paths defined"
            errors=$((errors + 1))
        fi

        if grep -q "components:" "$PROJECT_ROOT/openapi.yaml"; then
            log_success "OpenAPI: Has components/schemas"
        fi
    else
        log_error "File: openapi.yaml not found"
        errors=$((errors + 1))
    fi

    # Test 3: GraphQL schema
    log_info "Checking GraphQL schema..."
    if [[ -f "$PROJECT_ROOT/api/graphql/schema.graphql" ]]; then
        log_success "File: GraphQL schema exists"

        if grep -q "type Query" "$PROJECT_ROOT/api/graphql/schema.graphql"; then
            log_success "GraphQL: Has Query type"
        else
            log_warning "GraphQL: No Query type defined"
            errors=$((errors + 1))
        fi

        if grep -q "type Mutation" "$PROJECT_ROOT/api/graphql/schema.graphql"; then
            log_success "GraphQL: Has Mutation type"
        fi
    else
        log_warning "File: GraphQL schema not found (optional)"
    fi

    # Test 4: Route template
    log_info "Checking route templates..."
    if [[ -f "$PROJECT_ROOT/api/v1/routes/example.ts" ]]; then
        log_success "File: Route template exists"

        if grep -q "router.get\|router.post" "$PROJECT_ROOT/api/v1/routes/example.ts"; then
            log_success "Route: Has HTTP method handlers"
        fi
    else
        log_warning "File: Route template not found"
    fi

    # Test 5: Middleware
    log_info "Checking middleware..."
    local middleware_count=0
    for mw in error-handler.ts logger.ts validate.ts; do
        if [[ -f "$PROJECT_ROOT/api/middleware/$mw" ]]; then
            log_success "Middleware: $mw exists"
            middleware_count=$((middleware_count + 1))
        fi
    done

    if [[ $middleware_count -eq 0 ]]; then
        log_warning "No middleware found"
    fi

    # Test 6: Mock server
    log_info "Checking mock server..."
    if [[ -f "$PROJECT_ROOT/api/mock/server.js" ]]; then
        log_success "File: Mock server exists"

        if grep -q "express" "$PROJECT_ROOT/api/mock/server.js"; then
            log_success "Mock: Uses Express"
        fi

        if grep -q "app.listen" "$PROJECT_ROOT/api/mock/server.js"; then
            log_success "Mock: Has server listener"
        fi
    else
        log_warning "File: Mock server not found"
    fi

    # Test 7: Documentation
    log_info "Checking documentation..."
    if [[ -f "$PROJECT_ROOT/api/README.md" ]]; then
        log_success "File: API documentation exists"

        if grep -q "## Overview\|## Structure" "$PROJECT_ROOT/api/README.md"; then
            log_success "Docs: Has proper sections"
        fi
    else
        log_warning "File: API documentation not found"
    fi

    # Summary
    echo ""
    if [[ $errors -eq 0 ]]; then
        log_success "All validation checks passed!"
        return 0
    else
        log_warning "Validation found $errors issue(s)"
        return 0
    fi
}

# ===================================================================
# Step 10: Summary & Next Steps
# ===================================================================

validate_bootstrap

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"
show_summary
show_log_location

log_info "Next steps:"
echo "  1. Review OpenAPI spec: openapi.yaml"
echo "  2. Customize GraphQL schema: api/graphql/schema.graphql"
echo "  3. Install dependencies: npm install express cors zod"
echo "  4. Start mock server: node api/mock/server.js"
echo "  5. Implement route handlers in api/v1/routes/"
echo "  6. View API docs with Swagger UI or Redoc"
echo "  7. Commit: git add api/ openapi.yaml"
echo ""
