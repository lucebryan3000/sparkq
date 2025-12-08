# TIER 3: PRODUCTION - Single container (app + Postgres + Redis), hardened
ARG NODE_VERSION=20
ARG USER_ID=1001
ARG GROUP_ID=1001

FROM node:${NODE_VERSION}-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Essential runtime + Postgres/Redis servers + gosu for privilege drop
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gosu \
    postgresql \
    postgresql-client \
    redis-server \
    redis-tools \
    curl \
    && rm -rf /var/lib/apt/lists/*

# pnpm via corepack
RUN corepack enable && corepack prepare pnpm@latest --activate

# Align container user with provided UID/GID
RUN groupadd -g ${GROUP_ID} appgroup && useradd -m -u ${USER_ID} -g ${GROUP_ID} appuser

WORKDIR /app
RUN chown -R ${USER_ID}:${GROUP_ID} /app

# Entrypoint handles Postgres/Redis start, then gosu to non-root app user
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Healthcheck script for app readiness
COPY healthcheck.js /usr/local/bin/healthcheck.js

# Default command (override in compose)
CMD ["node", "server.js"]
