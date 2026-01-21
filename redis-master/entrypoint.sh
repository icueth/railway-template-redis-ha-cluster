#!/bin/bash
set -e

echo "========================================"
echo "  Redis Master - Starting..."
echo "========================================"

# Create data directory
mkdir -p /data

# Check required environment variables
if [ -z "$REDIS_PASSWORD" ]; then
    echo "[ERROR] REDIS_PASSWORD is required!"
    exit 1
fi

# Calculate maxmemory based on container limits (cgroup) or available memory
if [ -z "$REDIS_MAXMEMORY" ]; then
    # Try cgroup v2 limit first, then cgroup v1, then meminfo
    if [ -f /sys/fs/cgroup/memory.max ] && [ "$(cat /sys/fs/cgroup/memory.max)" != "max" ]; then
        MEM_LIMIT=$(cat /sys/fs/cgroup/memory.max)
        REDIS_MAXMEMORY="$((MEM_LIMIT / 2 / 1024))kb"
    elif [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
        MEM_LIMIT=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
        REDIS_MAXMEMORY="$((MEM_LIMIT / 2 / 1024))kb"
    elif [ -f /proc/meminfo ]; then
        TOTAL_MEM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        REDIS_MAXMEMORY="$((TOTAL_MEM / 2))kb"
    else
        REDIS_MAXMEMORY="256mb"
    fi
    echo "[INFO] Auto-calculated maxmemory: $REDIS_MAXMEMORY"
fi

export REDIS_MAXMEMORY
export RAILWAY_PRIVATE_DOMAIN=${RAILWAY_PRIVATE_DOMAIN:-localhost}
export REDISCLI_AUTH="$REDIS_PASSWORD"

# Graceful shutdown handler
trap 'redis-cli shutdown save' SIGTERM SIGINT

echo "[INFO] Node Role: MASTER"
echo "[INFO] Private Domain: $RAILWAY_PRIVATE_DOMAIN"
echo "[INFO] Max Memory: $REDIS_MAXMEMORY"

# Generate configuration from template
envsubst < /etc/redis/redis.conf.template > /etc/redis/redis.conf

echo "[INFO] Starting Redis Master..."
exec redis-server /etc/redis/redis.conf
