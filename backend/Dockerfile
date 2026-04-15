# ── SynapseTrade Backend — Dockerfile ──
# Multi-stage build para imagen ligera en producción

# Stage 1: Builder
FROM python:3.11-slim as builder

WORKDIR /app

# Instalar dependencias del sistema para compilar paquetes nativos
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ curl \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements y crear entorno virtual
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt --target /app/deps

# Stage 2: Runtime
FROM python:3.11-slim as runtime

WORKDIR /app

# Copiar dependencias del stage anterior
COPY --from=builder /app/deps /usr/local/lib/python3.11/site-packages/

# Copiar código fuente
COPY . .

# Variables de entorno por defecto (sobreescribir en producción)
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8000 \
    HOST=0.0.0.0

# Puerto expuesto
EXPOSE 8000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Comando de inicio
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
