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

## Why Deploy Redis HA Cluster on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Redis HA Cluster on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.

---

by iCue
