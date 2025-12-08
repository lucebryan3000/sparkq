# Makefile
# SparkQ Bootstrap - Dev velocity commands

.PHONY: dev up stop logs reset db shell build clean health bootstrap

# Start with logs streaming (foreground)
dev:
	@docker compose up --build

# Start detached (background, auto-restarts)
up:
	@docker compose up -d --build
	@echo "SparkQ running. Use 'make logs' to tail output."

# Stop
stop:
	@docker compose down

# Tail logs
logs:
	@docker compose logs -f

# Reset database (drop and recreate schema)
reset:
	@docker compose exec sparkq psql -U bootstrap sparkq -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
	@docker compose exec sparkq psql -U bootstrap sparkq -f /app/src/db/schema.sql
	@echo "Database reset complete"

# Direct psql access
db:
	@psql -h localhost -U bootstrap sparkq

# Shell into container
shell:
	@docker compose exec sparkq bash

# Build without starting
build:
	@docker compose build

# Nuclear option - remove everything including volumes
clean:
	@docker compose down -v --rmi local
	@echo "Cleaned up containers, volumes, and images"

# Quick health check
health:
	@curl -s localhost:3000/health | jq .

# Bootstrap a project
# Usage: make bootstrap P=/home/user/myproject
bootstrap:
	@curl -s -X POST localhost:3000/bootstrap -H "Content-Type: application/json" -d '{"path":"$(P)"}' | jq .

# Install dependencies locally (for IDE support)
install:
	@pnpm install

# View supervisor status
status:
	@docker compose exec sparkq supervisorctl status
