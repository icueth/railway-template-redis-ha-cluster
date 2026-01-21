#!/bin/bash
set -e

echo "========================================"
echo "  Redis Sentinel - Starting..."
echo "========================================"

# Create data directory
mkdir -p /data

# Check required environment variables
if [ -z "$REDIS_PASSWORD" ]; then
    echo "[ERROR] REDIS_PASSWORD is required!"
    exit 1
fi

if [ -z "$MASTER_HOST" ]; then
    echo "[ERROR] MASTER_HOST is required!"
    exit 1
fi

export RAILWAY_PRIVATE_DOMAIN=${RAILWAY_PRIVATE_DOMAIN:-localhost}

echo "[INFO] Node Role: SENTINEL"
echo "[INFO] Master Host: $MASTER_HOST"
echo "[INFO] Private Domain: $RAILWAY_PRIVATE_DOMAIN"

# Wait for master to be ready
echo "[INFO] Waiting for Master to be ready..."
MAX_RETRIES=60
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if redis-cli -h "$MASTER_HOST" -p 6379 -a "$REDIS_PASSWORD" ping 2>/dev/null | grep -q "PONG"; then
        echo "[OK] Master is ready!"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "[INFO] Waiting for master... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "[WARN] Master not responding, starting anyway..."
fi

# Generate configuration from template
envsubst < /etc/redis/sentinel.conf.template > /etc/redis/sentinel.conf

# Sentinel needs writable config file
chmod 644 /etc/redis/sentinel.conf

echo "[INFO] Starting Redis Sentinel..."
exec redis-sentinel /etc/redis/sentinel.conf
