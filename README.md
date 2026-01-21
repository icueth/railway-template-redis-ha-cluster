# Deploy and Host Redis HA Cluster on Railway

**Redis HA Cluster** is a production-ready, high-availability Redis deployment featuring Master-Replica replication with Redis Sentinel for automatic failover. This template provides enterprise-grade caching, session storage, and real-time messaging with zero-downtime failover capabilities.

## About Hosting Redis HA Cluster

Deploying this Redis cluster on Railway provides an instant production environment with automatic failover. The template includes three nodes: a **Master** for read/write operations, a **Replica** for read scaling and data redundancy, and a **Sentinel** that monitors the cluster and automatically promotes the replica if the master fails. All nodes feature auto-tuning based on Railway resources, ensuring optimal memory usage without manual configuration. Simply set your password and deploy—the cluster handles all internal communication automatically.

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Railway Project                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐         ┌─────────────────┐               │
│  │  redis-master   │         │  redis-replica  │               │
│  │                 │ ──────► │                 │               │
│  │  (Read/Write)   │ Async   │  (Read-Only)    │               │
│  │  Port: 6379     │ Sync    │  Port: 6379     │               │
│  └────────┬────────┘         └────────┬────────┘               │
│           │                           │                         │
│           └───────────┬───────────────┘                         │
│                       │                                         │
│              ┌────────▼────────┐                               │
│              │  redis-sentinel │                               │
│              │                 │                               │
│              │  • Monitoring   │                               │
│              │  • Auto-failover│                               │
│              │  Port: 26379    │                               │
│              └─────────────────┘                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Common Use Cases

- **Session Storage**: Store user sessions with automatic expiration and high availability.
- **Application Cache**: Speed up database queries with sub-millisecond response times.
- **Real-time Messaging**: Build pub/sub systems, chat applications, and live notifications.
- **Rate Limiting**: Implement API rate limits and request throttling.
- **Queue Management**: Use Redis Lists for job queues and task processing.
- **Leaderboards**: Build real-time gaming leaderboards with sorted sets.

## Dependencies for Redis HA Cluster Hosting

- **Redis 7.4**: Latest stable Redis with enhanced performance and security.
- **Redis Sentinel**: Automatic failover and cluster monitoring.
- **Alpine Linux**: Lightweight container base for minimal resource usage.

### Deployment Dependencies

- [Railway App](https://railway.app)
- [Redis Official Documentation](https://redis.io/docs/)

### Implementation Details

To get started, configure the `REDIS_PASSWORD` environment variable. Once deployed, connect through the master node for write operations or replica for read scaling.

#### Environment Variables

**redis-master:**

```env
REDIS_PASSWORD=your_secure_password
```

**redis-replica:**

```env
REDIS_PASSWORD=${redis-master.REDIS_PASSWORD}
MASTER_HOST=${redis-master.RAILWAY_PRIVATE_DOMAIN}
```

**redis-sentinel:**

```env
REDIS_PASSWORD=${redis-master.REDIS_PASSWORD}
MASTER_HOST=${redis-master.RAILWAY_PRIVATE_DOMAIN}
```

#### 🛰️ Internal / Private Connection (Recommended)

Use this for applications running within the same Railway project.

**Master (Read/Write):**

- **Host**: `redis-master.railway.internal`
- **Port**: `6379`
- **Password**: Your `${REDIS_PASSWORD}`

**Replica (Read-Only):**

- **Host**: `redis-replica.railway.internal`
- **Port**: `6379`
- **Password**: Your `${REDIS_PASSWORD}`

**Sentinel:**

- **Host**: `redis-sentinel.railway.internal`
- **Port**: `26379`

**Connection URL:**

```
redis://:${REDIS_PASSWORD}@redis-master.railway.internal:6379
```

#### 🌍 External / Public Connection

For local development or Redis management tools (RedisInsight, Another Redis Desktop Manager).

1. Navigate to the **redis-master** service in Railway.
2. Go to **Settings** > **Public Networking** > **TCP Proxy**.
3. Use the generated Public Domain and Port.

### Features

| Feature              | Description                                |
| -------------------- | ------------------------------------------ |
| **Auto-Failover**    | Sentinel promotes replica if master fails  |
| **Auto-Tune Memory** | Automatically uses 50% of available RAM    |
| **Persistence**      | RDB snapshots + AOF for data durability    |
| **Replication**      | Async replication with configurable lag    |
| **Security**         | Password authentication enabled by default |

## 💻 Connection Examples

### Node.js (ioredis)

**Direct Connection:**

```javascript
const Redis = require("ioredis");

// Connect to Master (Read/Write)
const master = new Redis({
  host: "redis-master.railway.internal",
  port: 6379,
  password: process.env.REDIS_PASSWORD,
});

// Connect to Replica (Read-Only)
const replica = new Redis({
  host: "redis-replica.railway.internal",
  port: 6379,
  password: process.env.REDIS_PASSWORD,
});
```

**Sentinel Connection (Recommended for HA):**

```javascript
const Redis = require("ioredis");

const redis = new Redis({
  sentinels: [{ host: "redis-sentinel.railway.internal", port: 26379 }],
  name: "mymaster",
  password: process.env.REDIS_PASSWORD,
  sentinelPassword: process.env.REDIS_PASSWORD,
  // Auto-reconnect on failover
  retryDelayOnFailover: 100,
  enableReadyCheck: true,
});

redis.on("connect", () => console.log("Connected to Redis via Sentinel"));
redis.on("error", (err) => console.error("Redis error:", err));
```

### Python (redis-py)

**Direct Connection:**

```python
import redis
import os

# Connect to Master (Read/Write)
master = redis.Redis(
    host='redis-master.railway.internal',
    port=6379,
    password=os.getenv('REDIS_PASSWORD'),
    decode_responses=True
)

# Connect to Replica (Read-Only)
replica = redis.Redis(
    host='redis-replica.railway.internal',
    port=6379,
    password=os.getenv('REDIS_PASSWORD'),
    decode_responses=True
)
```

**Sentinel Connection (Recommended for HA):**

```python
from redis.sentinel import Sentinel
import os

sentinel = Sentinel(
    [('redis-sentinel.railway.internal', 26379)],
    socket_timeout=0.5,
    password=os.getenv('REDIS_PASSWORD'),
    sentinel_kwargs={'password': os.getenv('REDIS_PASSWORD')}
)

# Get Master connection (Read/Write)
master = sentinel.master_for(
    'mymaster',
    socket_timeout=0.5,
    password=os.getenv('REDIS_PASSWORD'),
    decode_responses=True
)

# Get Replica connection (Read-Only)
replica = sentinel.slave_for(
    'mymaster',
    socket_timeout=0.5,
    password=os.getenv('REDIS_PASSWORD'),
    decode_responses=True
)

# Usage
master.set('key', 'value')
print(replica.get('key'))
```

### Go (go-redis)

**Direct Connection:**

```go
package main

import (
    "context"
    "os"
    "github.com/redis/go-redis/v9"
)

func main() {
    ctx := context.Background()

    // Connect to Master (Read/Write)
    master := redis.NewClient(&redis.Options{
        Addr:     "redis-master.railway.internal:6379",
        Password: os.Getenv("REDIS_PASSWORD"),
        DB:       0,
    })

    // Connect to Replica (Read-Only)
    replica := redis.NewClient(&redis.Options{
        Addr:     "redis-replica.railway.internal:6379",
        Password: os.Getenv("REDIS_PASSWORD"),
        DB:       0,
    })

    // Test connection
    _, err := master.Ping(ctx).Result()
    if err != nil {
        panic(err)
    }
}
```

**Sentinel Connection (Recommended for HA):**

```go
package main

import (
    "context"
    "fmt"
    "os"
    "github.com/redis/go-redis/v9"
)

func main() {
    ctx := context.Background()

    // Sentinel client with automatic failover
    rdb := redis.NewFailoverClient(&redis.FailoverOptions{
        MasterName:       "mymaster",
        SentinelAddrs:    []string{"redis-sentinel.railway.internal:26379"},
        Password:         os.Getenv("REDIS_PASSWORD"),
        SentinelPassword: os.Getenv("REDIS_PASSWORD"),
        DB:               0,
    })
    defer rdb.Close()

    // Test connection
    pong, err := rdb.Ping(ctx).Result()
    if err != nil {
        panic(err)
    }
    fmt.Println("Connected:", pong)

    // Usage
    err = rdb.Set(ctx, "key", "value", 0).Err()
    if err != nil {
        panic(err)
    }

    val, err := rdb.Get(ctx, "key").Result()
    if err != nil {
        panic(err)
    }
    fmt.Println("key:", val)
}
```

### 🔑 Why Use Sentinel Connection?

| Feature               | Direct Connection          | Sentinel Connection |
| --------------------- | -------------------------- | ------------------- |
| **Auto-Failover**     | ❌ Manual reconnect needed | ✅ Automatic        |
| **Service Discovery** | ❌ Hardcoded host          | ✅ Dynamic          |
| **High Availability** | ⚠️ Single point of failure | ✅ Full HA          |
| **Complexity**        | Simple                     | Slightly more setup |

> **Recommendation**: Use **Sentinel Connection** for production workloads to ensure your application automatically handles failover scenarios.

## Why Deploy Redis HA Cluster on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Redis HA Cluster on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.

---

by iCue
