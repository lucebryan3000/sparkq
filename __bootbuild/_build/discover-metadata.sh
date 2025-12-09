#!/bin/bash
# =============================================================================
# discover-metadata.sh
# Discovers values for all 8 new metadata fields
# Output: pipe-delimited CSV for easy parsing
#
# Usage: ./discover-metadata.sh > discovery-results.txt
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_SCRIPTS="${SCRIPT_DIR}/../templates/scripts"

# URL mapping for @docs field (from metadata_enhancement2.md)
declare -A DOCS_URLS=(
    ["api"]="https://swagger.io/specification/"
    ["auth-basic"]="https://datatracker.ietf.org/doc/html/rfc7617"
    ["auth-jwt"]="https://jwt.io/introduction"
    ["auth-oauth2"]="https://oauth.net/2/"
    ["backup-service"]="https://www.postgresql.org/docs/current/backup.html"
    ["buildtools"]="https://docs.npmjs.com/cli/commands"
    ["ci-cd"]="https://docs.github.com/en/actions"
    ["cicd"]="https://docs.github.com/en/actions"
    ["claude"]="https://docs.anthropic.com/en/api"
    ["codex"]="https://platform.openai.com/docs/guides/code"
    ["database"]="https://www.postgresql.org/docs/current/"
    ["detect"]="https://www.gnu.org/software/bash/manual/bash.html"
    ["docker-dev"]="https://docs.docker.com/compose/"
    ["docker-prod"]="https://docs.docker.com/compose/"
    ["docker-sandbox"]="https://docs.docker.com/compose/"
    ["docker"]="https://docs.docker.com/compose/"
    ["docs"]="https://jsdoc.app/"
    ["editor"]="https://editorconfig.org/"
    ["elasticsearch"]="https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html"
    ["email-service"]="https://nodemailer.com/about/"
    ["environment"]="https://dotenvx.com/docs"
    ["git"]="https://git-scm.com/doc"
    ["github"]="https://docs.github.com/"
    ["husky"]="https://typicode.github.io/husky/"
    ["kubernetes"]="https://kubernetes.io/docs/home/"
    ["linting"]="https://eslint.org/docs/latest/"
    ["monitoring"]="https://prometheus.io/docs/"
    ["mysql"]="https://dev.mysql.com/doc/"
    ["network-vpn"]="https://www.wireguard.com/quickstart/"
    ["nodejs"]="https://nodejs.org/docs/latest/api/"
    ["packages"]="https://docs.npmjs.com/"
    ["postgres"]="https://www.postgresql.org/docs/current/"
    ["project"]="https://docs.npmjs.com/cli/configuring-npm/package-json"
    ["python"]="https://docs.python.org/3/"
    ["quality"]="https://eslint.org/docs/latest/"
    ["rate-limiting"]="https://github.com/express-rate-limit/express-rate-limit"
    ["redis"]="https://redis.io/docs/"
    ["secrets"]="https://docs.github.com/en/actions/security-guides/encrypted-secrets"
    ["security"]="https://owasp.org/www-project-web-security-testing-guide/"
    ["ssl"]="https://letsencrypt.org/docs/"
    ["test-suite"]="https://jestjs.io/docs/getting-started"
    ["testing"]="https://vitest.dev/guide/"
    ["typescript"]="https://www.typescriptlang.org/docs/"
    ["vscode"]="https://code.visualstudio.com/docs"
)

# Known conflicts mapping
declare -A CONFLICTS_MAP=(
    ["mysql"]="postgres"
    ["postgres"]="mysql"
    ["docker-dev"]="docker-prod"
    ["docker-prod"]="docker-dev"
)

echo "name|config_section|interactive|platforms|env_vars|conflicts|rollback|verify|docs"

for script in "$TEMPLATES_SCRIPTS"/bootstrap-*.sh; do
    name=$(basename "$script" .sh | sed 's/bootstrap-//')

    # @config_section - find config_get calls
    section=$(grep -o 'config_get "[^"]*' "$script" 2>/dev/null | \
              sed 's/config_get "//' | cut -d. -f1 | head -1 || true)
    [[ -z "$section" ]] && section="none"

    # @interactive - check for read/select statements
    if grep -qE '^\s*read\s|select\s.*in\s' "$script" 2>/dev/null; then
        interactive="yes"
    else
        interactive="no"
    fi

    # @platforms - check for uname/OS checks
    if grep -q 'uname\|Darwin\|Linux' "$script" 2>/dev/null; then
        platforms="needs-review"
    else
        platforms="all"
    fi

    # @env_vars - find ${VAR} patterns (excluding common bash vars)
    env_vars=$(grep -oE '\$\{?[A-Z_][A-Z0-9_]*\}?' "$script" 2>/dev/null | \
               sed 's/[${}]//g' | sort -u | \
               grep -vE '^(BASH_|SCRIPT_|BOOTSTRAP_|HOME|PATH|PWD|USER|SHELL|TEMPLATES_|PROJECT_|TEMPLATE_)' | \
               tr '\n' ',' | sed 's/,$//' || true)
    [[ -z "$env_vars" ]] && env_vars="none"

    # @conflicts - lookup from known conflicts map
    conflicts="${CONFLICTS_MAP[$name]:-none}"

    # @rollback - derive from @creates
    creates=$(grep "^# @creates" "$script" 2>/dev/null | sed 's/.*@creates\s*//' | tr '\n' ' ' | xargs || true)
    if [[ -n "$creates" ]]; then
        rollback="rm -rf $creates"
    else
        rollback="none"
    fi

    # @verify - derive from @creates (check first file exists)
    if [[ -n "$creates" ]]; then
        first_file=$(echo "$creates" | awk '{print $1}')
        verify="test -f $first_file"
    else
        verify="echo 'No artifacts to verify'"
    fi

    # @docs - lookup from URL mapping
    docs="${DOCS_URLS[$name]:-}"

    echo "$name|$section|$interactive|$platforms|$env_vars|$conflicts|$rollback|$verify|$docs"
done
