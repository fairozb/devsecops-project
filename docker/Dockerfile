# Stage 1: Build
FROM python:3.11-slim AS builder

LABEL maintainer="devsecops-team"
LABEL org.opencontainers.image.source="https://github.com/fairozb/devsecops-project"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        python3-dev && \
    rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /tmp/requirements.txt

# Stage 2: Production
FROM python:3.11-slim AS production

LABEL maintainer="devsecops-team"
LABEL org.opencontainers.image.description="DevSecOps sample application"

# Security: Don't run as root
RUN groupadd -r appuser && \
    useradd -r -g appuser -d /app -s /sbin/nologin appuser

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        tini && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get purge -y --auto-remove

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app
COPY src/ ./src/

RUN chown -R appuser:appuser /app && \
    chmod -R 550 /app

# Security: Remove setuid/setgid bits
RUN find / -perm /6000 -type f -exec chmod a-s {} + 2>/dev/null || true

USER appuser

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

ENTRYPOINT ["tini", "--"]
CMD ["python", "-m", "src.main"]
