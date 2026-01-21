#!/bin/bash
set -e

echo "========================================"
echo "  Redis Replica - Starting..."
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

# Calculate maxmemory based on available memory (50% of available)
if [ -z "$REDIS_MAXMEMORY" ]; then
    if [ -f /proc/meminfo ]; then
        TOTAL_MEM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        REDIS_MAXMEMORY="$((TOTAL_MEM / 2))kb"
    else
        REDIS_MAXMEMORY="256mb"
    fi
    echo "[INFO] Auto-calculated maxmemory: $REDIS_MAXMEMORY"
fi

export REDIS_MAXMEMORY
export RAILWAY_PRIVATE_DOMAIN=${RAILWAY_PRIVATE_DOMAIN:-localhost}

echo "[INFO] Node Role: REPLICA"
echo "[INFO] Master Host: $MASTER_HOST"
echo "[INFO] Private Domain: $RAILWAY_PRIVATE_DOMAIN"
echo "[INFO] Max Memory: $REDIS_MAXMEMORY"

# Wait for master to be ready
echo "[INFO] Waiting for Master to be ready..."
MAX_RETRIES=60
RETRY_COUNT=0

export REDISCLI_AUTH="$REDIS_PASSWORD"

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if redis-cli -h "$MASTER_HOST" -p 6379 ping 2>/dev/null | grep -q "PONG"; then
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
envsubst < /etc/redis/redis.conf.template > /etc/redis/redis.conf

echo "[INFO] Starting Redis Replica..."
exec redis-server /etc/redis/redis.conf
