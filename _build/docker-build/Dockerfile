# _build/Dockerfile
# SparkQ Bootstrap - All-in-one Node.js + PostgreSQL + Supervisor
FROM node:20-bookworm

# System deps including supervisor and cron
RUN apt-get update && apt-get install -y \
    postgresql-15 postgresql-contrib-15 \
    supervisor cron \
    git curl jq sudo make \
    && rm -rf /var/lib/apt/lists/* \
    && corepack enable && corepack prepare pnpm@latest --activate \
    && npm install -g tsx

# PostgreSQL setup
USER postgres
RUN /usr/lib/postgresql/15/bin/initdb -D /var/lib/postgresql/data && \
    /usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/data -l /tmp/pg.log start && \
    psql -c "CREATE USER bootstrap WITH SUPERUSER PASSWORD 'bootstrap';" && \
    createdb -O bootstrap sparkq && \
    /usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/data stop

USER root

# Match host user for seamless file ops
ARG HOST_UID=1000
ARG HOST_GID=1000
RUN groupadd -g ${HOST_GID} dev 2>/dev/null || true && \
    useradd -m -u ${HOST_UID} -g ${HOST_GID} -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Supervisor and cron config
COPY _build/supervisord.conf /etc/supervisor/conf.d/sparkq.conf
COPY _build/crontab /etc/cron.d/sparkq
RUN chmod 0644 /etc/cron.d/sparkq && crontab /etc/cron.d/sparkq

# Log directory
RUN mkdir -p /var/log/sparkq && chown dev:dev /var/log/sparkq

WORKDIR /app
COPY _build/start.sh /start.sh
RUN chmod +x /start.sh

# Run as root so supervisor can manage all processes
ENTRYPOINT ["/start.sh"]
