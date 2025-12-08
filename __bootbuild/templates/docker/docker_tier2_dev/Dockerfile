# TIER 2: DEVELOPMENT - Single container (app + Postgres + Redis), more secure than sandbox
ARG NODE_VERSION=20
ARG USER_ID=1000
ARG GROUP_ID=1000

FROM node:${NODE_VERSION}-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Essential tools plus local Postgres/Redis and gosu for dropping privileges
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    gosu \
    postgresql \
    postgresql-client \
    redis-server \
    redis-tools \
    && rm -rf /var/lib/apt/lists/*

# pnpm via corepack (matches team dev baseline)
RUN corepack enable && corepack prepare pnpm@latest --activate

# Align container user with host UID/GID for better file permissions
RUN groupmod -g ${GROUP_ID} node && usermod -u ${USER_ID} -g ${GROUP_ID} node && \
    mkdir -p /home/node && chown -R ${USER_ID}:${GROUP_ID} /home/node

WORKDIR /app
RUN chown -R ${USER_ID}:${GROUP_ID} /app

# Entrypoint starts Postgres/Redis then drops to non-root app user
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Default command - override in compose
CMD ["bash"]
