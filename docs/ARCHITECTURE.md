# System Architecture

## Overview
This system monitoring stack consists of five main components that work together to provide comprehensive CI/CD pipeline and system metrics monitoring.

```
┌──────────────────────────────────────────────────────────────────┐
│                      WSL2 Ubuntu 22.04                           │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │            Docker Compose Network                       │    │
│  │  gitlab-monitoring                                      │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │                                                          │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │         GitLab Community Edition                 │  │    │
│  │  │  Port: 80, 443, 22, 9090, 8082, 8084            │  │    │
│  │  │  Services:                                       │  │    │
│  │  │  ├─ Puma (web server)                           │  │    │
│  │  │  ├─ Sidekiq (job queue)                         │  │    │
│  │  │  ├─ Workhorse (file uploads)                    │  │    │
│  │  │  ├─ Prometheus exporter (:9090)                 │  │    │
│  │  │  ├─ Sidekiq exporter (:8082)                    │  │    │
│  │  │  └─ Workhorse exporter (:8084)                  │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │               │              │             │            │    │
│  │               ▼              ▼             ▼            │    │
│  │  ┌─────────────┐  ┌────────────┐  ┌──────────────┐     │    │
│  │  │ PostgreSQL  │  │   Redis    │  │ Node Exp     │     │    │
│  │  │ (:5432)     │  │  (:6379)   │  │  (:9100)     │     │    │
│  │  │             │  │            │  │              │     │    │
│  │  │ Database    │  │ Cache &    │  │ System       │     │    │
│  │  │ & Job Queue │  │ Job Queue  │  │ Metrics      │     │    │
│  │  └─────────────┘  └────────────┘  └──────────────┘     │    │
│  │               │                                         │    │
│  │               │ Metrics (pull)                          │    │
│  │               ▼                                         │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │          Prometheus                             │  │    │
│  │  │          Port: 9091                             │  │    │
│  │  │                                                  │  │    │
│  │  │  ├─ Job: gitlab                                 │  │    │
│  │  │  ├─ Job: gitlab-sidekiq                         │  │    │
│  │  │  ├─ Job: gitlab-workhorse                       │  │    │
│  │  │  ├─ Job: node                                   │  │    │
│  │  │  └─ Alert Rules (evaluation)                    │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │                    │                                   │    │
│  │                    │ Metrics (API)                     │    │
│  │                    ▼                                   │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │          Grafana                                │  │    │
│  │  │          Port: 3000                             │  │    │
│  │  │                                                  │  │    │
│  │  │  ├─ Dashboard: GitLab Pipelines (Basic)         │  │    │
│  │  │  ├─ Dashboard: System Metrics (Comprehensive)   │  │    │
│  │  │  ├─ Dashboard: Advanced Monitoring              │  │    │
│  │  │  └─ Alerting (configured)                       │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │                                                          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. GitLab Community Edition
**Role**: Primary CI/CD platform
**Port**: 80 (HTTP), 443 (HTTPS), 22 (SSH), 9090 (metrics), 8082 (sidekiq), 8084 (workhorse)
**Key Features**:
- Omnibus package with pre-configured services
- Built-in Prometheus metrics exporters
- PostgreSQL backend for data persistence
- Redis for caching and job queue
- Automatically exports metrics in Prometheus format

**Exported Metrics**:
- `ci_created_builds` - Created CI builds
- `ci_pending_builds` - Pending CI builds
- `ci_stale_builds` - Stale CI builds
- `ci_unarchived_traces` - Unarchived CI job traces
- `sidekiq_jobs_processed_total` - Background jobs processed
- `sidekiq_jobs_failed_total` - Background jobs failed

### 2. PostgreSQL Database
**Role**: Persistent data store for GitLab
**Port**: 5432 (internal to container network)
**Version**: 16.13
**Configuration**:
- Database: `gitlabhq_production`
- User: `gitlab`
- Auto-backup: Can be configured with volumes

### 3. Redis Cache
**Role**: Session storage, caching, and job queue backend
**Port**: 6379 (internal to container network)
**Version**: 7.0.15
**Configuration**:
- AOF (append-only file) persistence enabled
- Used by GitLab for:
  - Session management
  - Cache store
  - Sidekiq job queue

### 4. Node Exporter
**Role**: System-level metrics collection
**Port**: 9100
**Metrics**:
- CPU usage (per-core and average)
- Memory usage (free, used, cached, buffers)
- Disk I/O statistics
- Network interface metrics
- Process count and uptime
- Filesystem usage
- System load averages

### 5. Prometheus
**Role**: Time-series database and metrics scraper
**Port**: 9091
**Key Responsibilities**:
- Scrapes metrics from GitLab and Node Exporter every 15 seconds
- Stores metrics for 30 days
- Evaluates alert rules every 30 seconds
- Provides query API for Grafana

**Scrape Targets**:
- GitLab: `localhost:9090/metrics` (15s interval)
- GitLab Sidekiq: `localhost:8082/metrics` (30s interval)
- GitLab Workhorse: `localhost:8084/metrics` (30s interval)
- Node Exporter: `localhost:9100/metrics` (15s interval)

### 6. Grafana
**Role**: Metrics visualization and alerting
**Port**: 3000
**Features**:
- Auto-configured with Prometheus data source
- Pre-built dashboards (can be customized)
- Alert rule definitions
- User-friendly visualization

## Data Flow

### Metrics Collection Pipeline
```
GitLab Services → Prometheus Exporters
         ↓
    Port 9090 (GitLab)
    Port 8082 (Sidekiq)
    Port 8084 (Workhorse)
    Port 9100 (Node Exporter)
         ↓
    Prometheus Scraper
         ↓
    Time-Series Database
    (30-day retention)
         ↓
    Grafana API Queries
         ↓
    Dashboard Visualization
```

### Alert Evaluation Flow
```
Prometheus Alert Rules
         ↓
    Evaluate every 30s
         ↓
    Check conditions (firing/resolved)
         ↓
    Grafana Alerting
         ↓
    Notifications (if configured)
```

## Performance Characteristics

### Resource Usage (Per Service)
| Service      | CPU   | Memory | Disk      |
|-------------|-------|--------|-----------|
| GitLab      | 40-60%| 800MB  | 20GB+     |
| PostgreSQL  | 5-10% | 200MB  | 5GB       |
| Redis       | 1-2%  | 50MB   | 1GB       |
| Prometheus  | 5-10% | 300MB  | 5-10GB*   |
| Grafana     | 2-5%  | 150MB  | 500MB     |
| Node Exp    | <1%   | 20MB   | -         |

*Depends on retention policy and metric volume

### Recommended Hardware
- **Development**: 8GB RAM, 50GB SSD
- **Testing**: 16GB RAM, 100GB SSD
- **Production**: 32GB+ RAM, 500GB+ SSD

## Network Architecture

### Port Mapping
```
Host (Windows)          WSL2 Container Network
localhost:80      ←→    gitlab:80
localhost:443     ←→    gitlab:443
localhost:22      ←→    gitlab:22
localhost:3000    ←→    grafana:3000
localhost:9091    ←→    prometheus:9090
localhost:9100    ←→    node-exporter:9100
```

### Internal Container Communication
- GitLab → PostgreSQL: `postgres:5432`
- GitLab → Redis: `redis:6379`
- Prometheus → GitLab: `gitlab:9090`
- Prometheus → Node Exp: `node-exporter:9100`
- Grafana → Prometheus: `prometheus:9090`

## Persistence & Storage

### Volume Mounts
| Container    | Volume          | Mount Path                     |
|-------------|-----------------|--------------------------------|
| PostgreSQL  | postgres_data   | /var/lib/postgresql/data       |
| Redis       | redis_data      | /data                          |
| GitLab      | gitlab_data     | /var/opt/gitlab               |
|             | gitlab_config   | /etc/gitlab                   |
|             | gitlab_logs     | /var/log/gitlab               |
| Prometheus  | prometheus_data | /prometheus                   |
| Grafana     | grafana_data    | /var/lib/grafana              |

### Data Backup Strategy
- **PostgreSQL**: Daily backups using `gitlab-rake`
- **Prometheus**: TSDB snapshots every 24 hours
- **Grafana**: Dashboard configs in `provisioning/` folder
- **Configuration**: All configs in `config/` folder (version controlled)

## Extensibility

### Adding New Metrics Exporters
1. Create new service in `docker-compose.yml`
2. Add scrape job in `prometheus.yml`
3. Configure in Grafana dashboard

### Custom Alert Rules
- Edit `config/prometheus/alert_rules.yml`
- Reload Prometheus: `docker-compose restart prometheus`

### Custom Dashboards
- Create dashboard in Grafana UI
- Export JSON to `config/grafana/provisioning/dashboards/`
- Auto-loaded on restart

## Scalability Considerations

### Vertical Scaling
- Increase Prometheus retention: Modify `--storage.tsdb.retention.time`
- Increase Grafana memory: Adjust `grafana` service in docker-compose

### Horizontal Scaling (Future)
- Multiple GitLab runners (configure in separate setup)
- Remote storage for Prometheus (S3, GCS)
- High-availability Grafana setup

## Security Considerations

### Current Configuration
- Default Grafana credentials: admin/admin (SHOULD CHANGE)
- PostgreSQL password hardcoded in docker-compose (SHOULD CHANGE)
- No SSL/TLS configured (suitable for development only)

### Production Hardening
1. Change all default credentials
2. Configure SSL certificates
3. Set up network firewall rules
4. Enable GitLab 2FA
5. Configure RBAC in Grafana
6. Encrypt data at rest

## Monitoring the Monitor
- Prometheus self-monitoring: `http://localhost:9091/targets`
- Grafana system dashboard: Shows Grafana performance metrics
- Container logs: `docker-compose logs -f`
