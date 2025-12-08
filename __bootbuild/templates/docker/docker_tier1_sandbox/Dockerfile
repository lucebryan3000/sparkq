# TIER 1: SANDBOX - Fast builds, full access
# ⚠️ NOT FOR PRODUCTION

FROM node:20-bookworm

# Install useful dev tools and local Postgres/Redis servers
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    vim \
    htop \
    postgresql \
    postgresql-client \
    redis-server \
    redis-tools \
    && rm -rf /var/lib/apt/lists/*

# Install global dev tools
RUN npm install -g \
    pnpm \
    typescript \
    ts-node \
    nodemon \
    prisma

WORKDIR /app
# Entrypoint starts Postgres/Redis before your app command
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
# No USER - running as root for full access

# Default command - override in compose
CMD ["bash"]
