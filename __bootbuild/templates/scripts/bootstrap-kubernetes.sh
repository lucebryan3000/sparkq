#!/bin/bash
# =============================================================================
# @script         bootstrap-kubernetes
# @version        1.0.0
# @phase          4
# @category       deploy
# @priority       50
# @short          Kubernetes deployment and Helm chart config
# @description    Generates Kubernetes deployment configuration with Kustomize
#                 for environment-specific overlays (dev/staging/prod) and Helm
#                 chart for package management. Includes base manifests for
#                 deployments, services, ingress, ConfigMaps, and secrets.
#
# @creates        kubernetes/base/deployment.yaml
# @creates        kubernetes/base/service.yaml
# @creates        kubernetes/base/ingress.yaml
# @creates        kubernetes/base/kustomization.yaml
# @creates        kubernetes/overlays/dev/kustomization.yaml
# @creates        kubernetes/helm-chart/Chart.yaml
# @creates        kubernetes/helm-chart/values.yaml
# @creates        kubernetes/README.md
#
# @depends        docker
# @detects        has_k8s_config
# @questions      kubernetes
# @defaults       replicas=2, container_port=3000
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
#
# @config_section  none
# @env_vars        ANSWERS_FILE,APP_PORT,K8S_DIR,K8S_TEMPLATE_DIR
# @interactive     no
# @platforms       all
# @conflicts       none
# @rollback        rm -rf kubernetes/base/deployment.yaml kubernetes/base/service.yaml kubernetes/base/ingress.yaml kubernetes/base/kustomization.yaml kubernetes/overlays/dev/kustomization.yaml kubernetes/helm-chart/Chart.yaml kubernetes/helm-chart/values.yaml kubernetes/README.md
# @verify          test -f kubernetes/base/deployment.yaml
# @docs            https://kubernetes.io/docs/home/
# =============================================================================

set -euo pipefail

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-kubernetes.sh"

# Source additional libraries
source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
source "${BOOTSTRAP_DIR}/lib/validation-common.sh"
source "${BOOTSTRAP_DIR}/lib/config-manager.sh"

# Get project root
PROJECT_ROOT=$(get_project_root "${1:-.}")
TEMPLATE_ROOT="${TEMPLATES_DIR}/root"
K8S_DIR="${PROJECT_ROOT}/kubernetes"
K8S_TEMPLATE_DIR="${TEMPLATE_ROOT}/kubernetes"

# Script identifier and answers file
SCRIPT_NAME="bootstrap-kubernetes"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "kubectl docker" \
    --scripts "bootstrap-docker" \
    --optional "helm"

ANSWERS_FILE=".bootstrap-answers.env"

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Kubernetes Configuration" \
    "kubernetes/deployment.yaml" \
    "kubernetes/service.yaml" \
    "kubernetes/ingress.yaml" \
    "kubernetes/configmap.yaml" \
    "kubernetes/secret.yaml" \
    "kubernetes/helm-chart/"

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping Kubernetes configuration..."

require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Check if kubectl is installed (informational only)
if require_command "kubectl" 2>/dev/null; then
    log_success "kubectl is installed: $(kubectl version --client --short 2>/dev/null || echo 'version check failed')"
else
    track_warning "kubectl is not installed (required to deploy to Kubernetes)"
    log_warning "kubectl is not installed (required for K8s deployments)"
fi

# Check if helm is installed (informational only)
if require_command "helm" 2>/dev/null; then
    log_success "Helm is installed: $(helm version --short 2>/dev/null || echo 'version check failed')"
else
    track_warning "Helm is not installed (optional, for Helm chart deployment)"
    log_warning "Helm is not installed (optional, for chart-based deployments)"
fi

# ===================================================================
# Create Directory Structure
# ===================================================================

log_info "Creating kubernetes directory structure..."
mkdir -p "$K8S_DIR"/{base,overlays/{dev,staging,prod},helm-chart/{templates,charts}}
log_success "Directory structure created"

# ===================================================================
# Create Deployment Manifest
# ===================================================================

log_info "Creating deployment.yaml..."

if file_exists "$K8S_DIR/base/deployment.yaml"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$K8S_DIR/base/deployment.yaml"
    else
        track_skipped "deployment.yaml"
        log_warning "deployment.yaml already exists, skipping"
    fi
fi

if file_exists "$K8S_TEMPLATE_DIR/deployment.yaml"; then
    if cp "$K8S_TEMPLATE_DIR/deployment.yaml" "$K8S_DIR/base/"; then
        if verify_file "$K8S_DIR/base/deployment.yaml"; then
            track_created "kubernetes/base/deployment.yaml"
            log_file_created "$SCRIPT_NAME" "kubernetes/base/deployment.yaml"
        fi
    else
        log_fatal "Failed to copy deployment.yaml"
    fi
else
    log_info "Creating default deployment.yaml..."
    cat > "$K8S_DIR/base/deployment.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  labels:
    app: app
    version: v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
        version: v1
    spec:
      containers:
      - name: app
        image: registry.example.com/app:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3000
          name: http
          protocol: TCP
        env:
        - name: NODE_ENV
          value: production
        - name: PORT
          value: "3000"
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
EOF
    track_created "kubernetes/base/deployment.yaml"
    log_file_created "$SCRIPT_NAME" "kubernetes/base/deployment.yaml"
fi

# ===================================================================
# Create Service Manifest
# ===================================================================

log_info "Creating service.yaml..."

if file_exists "$K8S_DIR/base/service.yaml"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$K8S_DIR/base/service.yaml"
    else
        track_skipped "service.yaml"
        log_warning "service.yaml already exists, skipping"
    fi
fi

if file_exists "$K8S_TEMPLATE_DIR/service.yaml"; then
    if cp "$K8S_TEMPLATE_DIR/service.yaml" "$K8S_DIR/base/"; then
        if verify_file "$K8S_DIR/base/service.yaml"; then
            track_created "kubernetes/base/service.yaml"
            log_file_created "$SCRIPT_NAME" "kubernetes/base/service.yaml"
        fi
    else
        log_fatal "Failed to copy service.yaml"
    fi
else
    log_info "Creating default service.yaml..."
    cat > "$K8S_DIR/base/service.yaml" << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: app
  labels:
    app: app
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
    name: http
  selector:
    app: app
EOF
    track_created "kubernetes/base/service.yaml"
    log_file_created "$SCRIPT_NAME" "kubernetes/base/service.yaml"
fi

# ===================================================================
# Create Ingress Manifest
# ===================================================================

log_info "Creating ingress.yaml..."

if file_exists "$K8S_DIR/base/ingress.yaml"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$K8S_DIR/base/ingress.yaml"
    else
        track_skipped "ingress.yaml"
        log_warning "ingress.yaml already exists, skipping"
    fi
fi

if file_exists "$K8S_TEMPLATE_DIR/ingress.yaml"; then
    if cp "$K8S_TEMPLATE_DIR/ingress.yaml" "$K8S_DIR/base/"; then
        if verify_file "$K8S_DIR/base/ingress.yaml"; then
            track_created "kubernetes/base/ingress.yaml"
            log_file_created "$SCRIPT_NAME" "kubernetes/base/ingress.yaml"
        fi
    else
        log_fatal "Failed to copy ingress.yaml"
    fi
else
    log_info "Creating default ingress.yaml..."
    cat > "$K8S_DIR/base/ingress.yaml" << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.example.com
    secretName: app-tls
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app
            port:
              number: 80
EOF
    track_created "kubernetes/base/ingress.yaml"
    log_file_created "$SCRIPT_NAME" "kubernetes/base/ingress.yaml"
fi

# ===================================================================
# Create ConfigMap Manifest
# ===================================================================

log_info "Creating configmap.yaml..."

if file_exists "$K8S_DIR/base/configmap.yaml"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$K8S_DIR/base/configmap.yaml"
    else
        track_skipped "configmap.yaml"
        log_warning "configmap.yaml already exists, skipping"
    fi
fi

if file_exists "$K8S_TEMPLATE_DIR/configmap.yaml"; then
    if cp "$K8S_TEMPLATE_DIR/configmap.yaml" "$K8S_DIR/base/"; then
        if verify_file "$K8S_DIR/base/configmap.yaml"; then
            track_created "kubernetes/base/configmap.yaml"
            log_file_created "$SCRIPT_NAME" "kubernetes/base/configmap.yaml"
        fi
    else
        log_fatal "Failed to copy configmap.yaml"
    fi
else
    log_info "Creating default configmap.yaml..."
    cat > "$K8S_DIR/base/configmap.yaml" << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  LOG_LEVEL: "info"
  API_TIMEOUT: "30000"
  CACHE_TTL: "3600"
EOF
    track_created "kubernetes/base/configmap.yaml"
    log_file_created "$SCRIPT_NAME" "kubernetes/base/configmap.yaml"
fi

# ===================================================================
# Create Secret Template
# ===================================================================

log_info "Creating secret.yaml..."

if file_exists "$K8S_DIR/base/secret.yaml"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$K8S_DIR/base/secret.yaml"
    else
        track_skipped "secret.yaml"
        log_warning "secret.yaml already exists, skipping"
    fi
fi

if file_exists "$K8S_TEMPLATE_DIR/secret.yaml"; then
    if cp "$K8S_TEMPLATE_DIR/secret.yaml" "$K8S_DIR/base/"; then
        if verify_file "$K8S_DIR/base/secret.yaml"; then
            track_created "kubernetes/base/secret.yaml"
            log_file_created "$SCRIPT_NAME" "kubernetes/base/secret.yaml"
        fi
    else
        log_fatal "Failed to copy secret.yaml"
    fi
else
    log_info "Creating default secret.yaml template..."
    cat > "$K8S_DIR/base/secret.yaml" << 'EOF'
# NOTE: Do not commit actual secrets to version control
# Use external secret management (e.g., sealed-secrets, external-secrets)
# This is a template only
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  DATABASE_URL: "postgresql://user:password@postgres:5432/dbname"
  API_KEY: "your-api-key-here"
  JWT_SECRET: "your-jwt-secret-here"
EOF
    track_created "kubernetes/base/secret.yaml"
    log_file_created "$SCRIPT_NAME" "kubernetes/base/secret.yaml"
fi

# ===================================================================
# Create Kustomization Files
# ===================================================================

log_info "Creating kustomization files for overlays..."

# Base kustomization
cat > "$K8S_DIR/base/kustomization.yaml" << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - ingress.yaml
  - configmap.yaml
  - secret.yaml

commonLabels:
  app: app
EOF
track_created "kubernetes/base/kustomization.yaml"
log_file_created "$SCRIPT_NAME" "kubernetes/base/kustomization.yaml"

# Dev overlay
cat > "$K8S_DIR/overlays/dev/kustomization.yaml" << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: dev

bases:
  - ../../base

patchesStrategicMerge:
  - deployment-patch.yaml

commonLabels:
  environment: dev
EOF
track_created "kubernetes/overlays/dev/kustomization.yaml"
log_file_created "$SCRIPT_NAME" "kubernetes/overlays/dev/kustomization.yaml"

cat > "$K8S_DIR/overlays/dev/deployment-patch.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: app
        image: registry.example.com/app:dev
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "250m"
EOF
track_created "kubernetes/overlays/dev/deployment-patch.yaml"
log_file_created "$SCRIPT_NAME" "kubernetes/overlays/dev/deployment-patch.yaml"

# Staging overlay
cat > "$K8S_DIR/overlays/staging/kustomization.yaml" << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: staging

bases:
  - ../../base

patchesStrategicMerge:
  - deployment-patch.yaml

commonLabels:
  environment: staging
EOF
track_created "kubernetes/overlays/staging/kustomization.yaml"
log_file_created "$SCRIPT_NAME" "kubernetes/overlays/staging/kustomization.yaml"

cat > "$K8S_DIR/overlays/staging/deployment-patch.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: app
        image: registry.example.com/app:staging
EOF
track_created "kubernetes/overlays/staging/deployment-patch.yaml"
log_file_created "$SCRIPT_NAME" "kubernetes/overlays/staging/deployment-patch.yaml"

# Production overlay
cat > "$K8S_DIR/overlays/prod/kustomization.yaml" << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: production

bases:
  - ../../base

patchesStrategicMerge:
  - deployment-patch.yaml

commonLabels:
  environment: production
EOF
track_created "kubernetes/overlays/prod/kustomization.yaml"
log_file_created "$SCRIPT_NAME" "kubernetes/overlays/prod/kustomization.yaml"

cat > "$K8S_DIR/overlays/prod/deployment-patch.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: registry.example.com/app:latest
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
EOF
track_created "kubernetes/overlays/prod/deployment-patch.yaml"
log_file_created "$SCRIPT_NAME" "kubernetes/overlays/prod/deployment-patch.yaml"

# ===================================================================
# Create Helm Chart
# ===================================================================

log_info "Creating Helm chart structure..."

cat > "$K8S_DIR/helm-chart/Chart.yaml" << 'EOF'
apiVersion: v2
name: app
description: A Helm chart for app deployment
type: application
version: 0.1.0
appVersion: "1.0.0"

maintainers:
  - name: Your Team
    email: team@example.com

keywords:
  - app
  - kubernetes

home: https://github.com/example/app
sources:
  - https://github.com/example/app
EOF
track_created "kubernetes/helm-chart/Chart.yaml"
log_file_created "$SCRIPT_NAME" "kubernetes/helm-chart/Chart.yaml"

cat > "$K8S_DIR/helm-chart/values.yaml" << 'EOF'
# Default values for app
replicaCount: 2

image:
  repository: registry.example.com/app
  pullPolicy: IfNotPresent
  tag: "latest"

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations: {}

podSecurityContext: {}

securityContext: {}

service:
  type: ClusterIP
  port: 80
  targetPort: 3000

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts:
        - app.example.com

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: false
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

nodeSelector: {}

tolerations: []

affinity: {}

env:
  - name: NODE_ENV
    value: production
  - name: PORT
    value: "3000"
EOF
track_created "kubernetes/helm-chart/values.yaml"
log_file_created "$SCRIPT_NAME" "kubernetes/helm-chart/values.yaml"

cat > "$K8S_DIR/helm-chart/templates/deployment.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "app.fullname" . }}
  labels:
    {{- include "app.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "app.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "app.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
      - name: {{ .Chart.Name }}
        securityContext:
          {{- toYaml .Values.securityContext | nindent 12 }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ .Values.service.targetPort }}
          protocol: TCP
        {{- with .Values.env }}
        env:
          {{- toYaml . | nindent 12 }}
        {{- end }}
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
        resources:
          {{- toYaml .Values.resources | nindent 12 }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
EOF
track_created "kubernetes/helm-chart/templates/deployment.yaml"
log_file_created "$SCRIPT_NAME" "kubernetes/helm-chart/templates/deployment.yaml"

cat > "$K8S_DIR/helm-chart/templates/_helpers.tpl" << 'EOF'
{{/*
Expand the name of the chart.
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
helm.sh/chart: {{ include "app.chart" . }}
{{ include "app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
EOF
track_created "kubernetes/helm-chart/templates/_helpers.tpl"
log_file_created "$SCRIPT_NAME" "kubernetes/helm-chart/templates/_helpers.tpl"

# ===================================================================
# Create README
# ===================================================================

log_info "Creating kubernetes/README.md..."

cat > "$K8S_DIR/README.md" << 'EOF'
# Kubernetes Deployment

This directory contains Kubernetes manifests and Helm charts for deploying the application.

## Structure

```
kubernetes/
├── base/                  # Base Kubernetes manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   └── kustomization.yaml
├── overlays/              # Environment-specific overlays
│   ├── dev/
│   ├── staging/
│   └── prod/
└── helm-chart/            # Helm chart
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
```

## Deployment Methods

### Option 1: kubectl with kustomize

Deploy to development:
```bash
kubectl apply -k kubernetes/overlays/dev
```

Deploy to staging:
```bash
kubectl apply -k kubernetes/overlays/staging
```

Deploy to production:
```bash
kubectl apply -k kubernetes/overlays/prod
```

### Option 2: Helm

Install/upgrade the chart:
```bash
helm upgrade --install app ./kubernetes/helm-chart \
  --namespace production \
  --create-namespace \
  --values kubernetes/helm-chart/values.yaml
```

With custom values:
```bash
helm upgrade --install app ./kubernetes/helm-chart \
  --namespace production \
  --set image.tag=v1.2.3 \
  --set replicaCount=5
```

## Configuration

### Environment Variables

Edit `kubernetes/base/configmap.yaml` for non-sensitive configuration.

### Secrets

**IMPORTANT:** Never commit actual secrets to version control.

Use one of these approaches:

1. **kubectl create secret:**
   ```bash
   kubectl create secret generic app-secrets \
     --from-literal=DATABASE_URL="postgresql://..." \
     --from-literal=API_KEY="..." \
     -n production
   ```

2. **Sealed Secrets:**
   ```bash
   kubeseal --format=yaml < secret.yaml > sealed-secret.yaml
   ```

3. **External Secrets Operator:**
   Configure external secret store (AWS Secrets Manager, Vault, etc.)

### Image Tags

Update image tags in:
- Kustomize: `kubernetes/overlays/{env}/deployment-patch.yaml`
- Helm: `kubernetes/helm-chart/values.yaml` or via `--set`

## Resource Limits

Default resource limits per environment:

| Environment | Replicas | Memory Request | Memory Limit | CPU Request | CPU Limit |
|-------------|----------|----------------|--------------|-------------|-----------|
| Dev         | 1        | 64Mi           | 256Mi        | 50m         | 250m      |
| Staging     | 2        | 128Mi          | 512Mi        | 100m        | 500m      |
| Production  | 3        | 256Mi          | 1Gi          | 200m        | 1000m     |

## Health Checks

- **Liveness probe:** `/health` endpoint (port 3000)
- **Readiness probe:** `/ready` endpoint (port 3000)

Ensure your application implements these endpoints.

## Monitoring

View logs:
```bash
kubectl logs -l app=app -n production --tail=100 -f
```

Check pod status:
```bash
kubectl get pods -l app=app -n production
```

Describe deployment:
```bash
kubectl describe deployment app -n production
```

## Troubleshooting

### Pod not starting

```bash
kubectl describe pod <pod-name> -n production
kubectl logs <pod-name> -n production
```

### ImagePullBackOff

Verify image exists and registry credentials are configured:
```bash
kubectl get events -n production | grep -i pull
```

### CrashLoopBackOff

Check application logs:
```bash
kubectl logs <pod-name> -n production --previous
```

## CI/CD Integration

Example GitHub Actions deployment:

```yaml
- name: Deploy to Kubernetes
  run: |
    kubectl apply -k kubernetes/overlays/prod
    kubectl rollout status deployment/app -n production
```

Example Helm deployment:

```yaml
- name: Deploy with Helm
  run: |
    helm upgrade --install app ./kubernetes/helm-chart \
      --namespace production \
      --set image.tag=${{ github.sha }}
```
EOF
track_created "kubernetes/README.md"
log_file_created "$SCRIPT_NAME" "kubernetes/README.md"

# ===================================================================
# Validation & Testing (Self-Testing Protocol)
# ===================================================================

validate_bootstrap() {
    local errors=0

    log_info "Validating bootstrap configuration..."
    echo ""

    # Test 1: Directory structure
    log_info "Checking directory structure..."
    for dir in base overlays/dev overlays/staging overlays/prod helm-chart/templates; do
        if [[ -d "$K8S_DIR/$dir" ]]; then
            log_success "Directory: kubernetes/$dir exists"
        else
            log_warning "Directory: kubernetes/$dir not found"
            errors=$((errors + 1))
        fi
    done

    # Test 2: Base manifests
    log_info "Checking base manifests..."
    for file in deployment.yaml service.yaml ingress.yaml configmap.yaml secret.yaml kustomization.yaml; do
        if [[ -f "$K8S_DIR/base/$file" ]]; then
            log_success "File: kubernetes/base/$file exists"
        else
            log_warning "File: kubernetes/base/$file not found"
            errors=$((errors + 1))
        fi
    done

    # Test 3: Validate YAML syntax
    log_info "Validating YAML syntax..."
    local yaml_errors=0
    for yaml_file in "$K8S_DIR/base"/*.yaml "$K8S_DIR/overlays"/*/*.yaml "$K8S_DIR/helm-chart"/*.yaml; do
        if [[ -f "$yaml_file" ]]; then
            if python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null; then
                log_success "YAML: $(basename $yaml_file) is valid"
            else
                log_warning "YAML: $yaml_file has syntax issues"
                yaml_errors=$((yaml_errors + 1))
            fi
        fi
    done
    if [[ $yaml_errors -gt 0 ]]; then
        errors=$((errors + yaml_errors))
    fi

    # Test 4: Validate K8s manifests (if kubectl available)
    if command -v kubectl &> /dev/null; then
        log_info "Validating K8s manifests with kubectl..."
        for manifest in "$K8S_DIR/base"/{deployment,service,ingress,configmap,secret}.yaml; do
            if [[ -f "$manifest" ]]; then
                if kubectl apply --dry-run=client -f "$manifest" &> /dev/null; then
                    log_success "K8s: $(basename $manifest) is valid"
                else
                    log_warning "K8s: $(basename $manifest) validation failed"
                fi
            fi
        done
    fi

    # Test 5: Check Helm chart structure
    log_info "Checking Helm chart structure..."
    for file in Chart.yaml values.yaml templates/deployment.yaml templates/_helpers.tpl; do
        if [[ -f "$K8S_DIR/helm-chart/$file" ]]; then
            log_success "Helm: $file exists"
        else
            log_warning "Helm: $file not found"
            errors=$((errors + 1))
        fi
    done

    # Test 6: Validate Helm chart (if helm available)
    if command -v helm &> /dev/null; then
        log_info "Validating Helm chart..."
        if helm lint "$K8S_DIR/helm-chart" &> /dev/null; then
            log_success "Helm: Chart validation passed"
        else
            log_warning "Helm: Chart validation failed"
        fi
    fi

    # Summary
    echo ""
    if [[ $errors -eq 0 ]]; then
        log_success "All validation checks passed!"
        return 0
    else
        log_warning "Validation found $errors issue(s) (non-critical)"
        return 0
    fi
}

# ===================================================================
# Template Customization
# ===================================================================

customize_templates() {
    log_info "Customizing templates with your configuration..."

    # Only customize if answers file exists
    if [[ ! -f "$ANSWERS_FILE" ]]; then
        log_warning "No answers file found. Skipping customization."
        return 0
    fi

    # Source answers
    source "$ANSWERS_FILE"

    local customized=0

    # Update project name in manifests
    if [[ -n "${PROJECT_NAME:-}" ]]; then
        log_info "Updating project name to ${PROJECT_NAME}..."

        # Update in base manifests
        for file in "$K8S_DIR/base"/*.yaml; do
            if [[ -f "$file" ]]; then
                sed -i "s/name: app$/name: ${PROJECT_NAME}/g" "$file"
                sed -i "s/app: app$/app: ${PROJECT_NAME}/g" "$file"
            fi
        done

        # Update in Helm chart
        if [[ -f "$K8S_DIR/helm-chart/Chart.yaml" ]]; then
            sed -i "s/name: app$/name: ${PROJECT_NAME}/g" "$K8S_DIR/helm-chart/Chart.yaml"
        fi

        ((customized++))
    fi

    # Update container port if specified
    if [[ -n "${APP_PORT:-}" ]]; then
        log_info "Updating container port to ${APP_PORT}..."
        sed -i "s/containerPort: 3000/containerPort: ${APP_PORT}/g" "$K8S_DIR/base/deployment.yaml"
        sed -i "s/targetPort: 3000/targetPort: ${APP_PORT}/g" "$K8S_DIR/base/service.yaml"
        ((customized++))
    fi

    # Update config with answers
    config_update_from_answers "$ANSWERS_FILE"

    if [[ $customized -gt 0 ]]; then
        log_success "Applied $customized customizations"
    else
        log_info "No customizations applied"
    fi

    return 0
}

# Run customization if answers exist
if [[ -f "$ANSWERS_FILE" ]]; then
    customize_templates
    echo ""
fi

# ===================================================================
# Summary & Next Steps
# ===================================================================

validate_bootstrap

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"
show_summary
show_log_location

log_info "Next steps:"
if [[ -f "$ANSWERS_FILE" ]]; then
    echo "  ✓ Kubernetes manifests customized with your configuration"
    echo "  1. Update kubernetes/base/secret.yaml with actual secrets (DO NOT COMMIT)"
    echo "  2. Update image registry URLs in manifests"
    echo "  3. Deploy: kubectl apply -k kubernetes/overlays/dev"
    echo "  4. Or use Helm: helm install app ./kubernetes/helm-chart"
else
    echo "  1. Update kubernetes/base/ manifests for your app"
    echo "  2. Configure secrets (use sealed-secrets or external-secrets)"
    echo "  3. Update image registry URLs"
    echo "  4. Deploy: kubectl apply -k kubernetes/overlays/dev"
    echo "  5. Commit: git add kubernetes/ && git commit -m 'Add Kubernetes configuration'"
fi
echo ""
