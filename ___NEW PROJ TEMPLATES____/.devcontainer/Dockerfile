FROM mcr.microsoft.com/devcontainers/typescript-node:1-20-bookworm

RUN apt-get update && apt-get install -y \
    git \
    zsh \
    curl \
    wget \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@9.6.0 --activate

RUN npm install -g \
    typescript \
    tsx \
    prisma

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

USER node

ENV SHELL=/bin/zsh
ENV PNPM_HOME=/home/node/.local/share/pnpm
ENV PATH="${PNPM_HOME}:${PATH}"

WORKDIR /app
