# GitLab CI/CD Pipeline Monitoring Setup Guide

## Overview
This guide sets up a complete monitoring stack for GitLab CI/CD pipelines:
- **GitLab CE** - CI/CD platform
- **Prometheus** - Metrics collection
- **Grafana** - Visualization and dashboards  
- **Node Exporter** - System metrics
- **Alert Rules** - Automated alerting

## System Requirements
- **WSL2** with Ubuntu 22.04 LTS
- **Minimum 8GB RAM** for the full stack
- **50GB disk space** for GitLab and data
- **Docker & Docker Compose** (recommended for simplified setup)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    WSL2 Ubuntu 22.04                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  GitLab CE              Monitoring Stack                      │
│  ├─ Port 80/443         ├─ Prometheus (9092 host)           │
│  ├─ Sidekiq             ├─ Grafana (3001 host)              │
│  ├─ Workhorse           ├─ Node Exporter (9100)             │
│  └─ PostgreSQL          └─ Alert Manager                     │
│     Redis                                                     │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start (Recommended - Using Docker Compose)

### Step 1: Install Docker in WSL2
```bash
wsl -u root -e bash -c "
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker \$USER
"
```

### Step 2: Clone Configuration Files
Copy the configuration files from this repository to `/opt/gitlab-monitoring/`:

```bash
mkdir -p /opt/gitlab-monitoring
cd /opt/gitlab-monitoring
cp -r config/* .
```

### Step 3: Start Stack with Docker Compose
```bash
docker compose up -d
```

This will start:
- GitLab CE on http://localhost
- Grafana on http://localhost:3001 (admin/admin)
- Prometheus on http://localhost:9092

Note: The Docker Compose stack in this repository uses non-default host ports to avoid common WSL port conflicts.

---

## Manual Installation (Native WSL2)

### Phase 1: Prerequisites (Already Completed ✓)
- Ruby 3.2.3 ✓
- Node.js 18.19.1 ✓
- PostgreSQL 16.13 ✓
- Redis 7.0.15 ✓

### Phase 2: Install Prometheus

```bash
# Download Prometheus
PROMETHEUS_VERSION="2.48.0"
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar xzf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
sudo mv prometheus-${PROMETHEUS_VERSION}.linux-amd64 /opt/prometheus

# Copy configuration
sudo cp config/prometheus/prometheus.yml /opt/prometheus/
sudo cp config/prometheus/alert_rules.yml /opt/prometheus/

# Create systemd service
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=prometheus
ExecStart=/opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml --storage.tsdb.path=/opt/prometheus/data
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus
```

### Phase 3: Install Node Exporter

```bash
# Download Node Exporter
NODE_EXPORTER_VERSION="1.7.0"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64 /opt/node_exporter

# Create systemd service
sudo tee /etc/systemd/system/node-exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
ExecStart=/opt/node_exporter/node_exporter
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable node-exporter
sudo systemctl start node-exporter
```

### Phase 4: Install Grafana

```bash
# Add Grafana repository
sudo apt-get install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
sudo apt-get update
sudo apt-get install -y grafana-server

# Start Grafana
sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

Access Grafana at [http://localhost:3000](http://localhost:3000) for native install (Docker Compose deployment uses [http://localhost:3001](http://localhost:3001)).

### Phase 5: Configure Grafana Data Source

1. Login to Grafana (native: http://localhost:3000, Docker Compose: http://localhost:3001)
2. Go to **Configuration** → **Data Sources**
3. Click **Add data source**
4. Select **Prometheus**
5. URL: [http://localhost:9090](http://localhost:9090) (native install) or [http://localhost:9092](http://localhost:9092) (Docker Compose)
6. Click **Save & test**

### Phase 6: Import Dashboards

1. In Grafana, go to **Dashboards** → **Import**
2. Import the JSON files from `config/grafana/provisioning/dashboards/`:
   - `gitlab_pipelines.json` - GitLab pipeline metrics
   - `system_metrics.json` - System resource metrics
   - `advanced_monitoring.json` - Advanced monitoring with alerts

---

## Accessing the Services

| Service      | URL                 | Default Credentials |
|-------------|---------------------|-------------------|
| GitLab      | http://localhost    | (Configure on first login)  |
| Grafana     | http://localhost:3001 | admin / admin      |
| Prometheus  | http://localhost:9092 | N/A (read-only)    |

---

## Verifying Metrics Collection

### Check Prometheus Targets

1. Open http://localhost:9092/targets
2. Verify all targets show "UP":
   - gitlab (metrics)
   - gitlab-sidekiq
   - gitlab-workhorse
   - node (system)

### Check GitLab Metrics

```bash
# In WSL2:
curl http://localhost:9090/metrics | head -20
```

### Check Node Exporter Metrics

```bash
curl http://localhost:9100/metrics | head -20
```

---

## Creating Your First GitLab Project

1. Access GitLab at http://localhost
2. Create a new group: "monitoring-demo"
3. Create projects from the sample pipelines:
   - `simple-pipeline` - successful execution
   - `failed-pipeline` - demonstrates failure monitoring
   - `long-running-pipeline` - tests timeout detection
4. Add `.gitlab-ci.yml` from `samples/` directories
5. Trigger pipelines to see metrics in Grafana

---

## Add GitLab Runner (Distributed CI/CD)

### Step 1: Start Runner Service

```bash
docker compose up -d gitlab-runner
docker compose ps
```

### Step 2: Get Runner Registration Token

In GitLab UI:
1. Open http://localhost
2. Go to **Admin Area** -> **CI/CD** -> **Runners**
3. Copy the instance registration token

### Step 3: Register Docker Runner

Replace `<RUNNER_TOKEN>` with your token:

```bash
docker exec -it gitlab-runner gitlab-runner register \
   --non-interactive \
   --url "http://gitlab" \
   --registration-token "<RUNNER_TOKEN>" \
   --executor "docker" \
   --docker-image "alpine:latest" \
   --description "wsl-docker-runner" \
   --tag-list "wsl,docker" \
   --run-untagged="true" \
   --locked="false" \
   --docker-privileged="true" \
   --docker-volumes "/cache"
```

### Step 4: Verify Runner

```bash
docker exec -it gitlab-runner gitlab-runner verify
```

The runner should appear as **online** in GitLab Runners page.

---

## Monitoring Dashboards

### Dashboard 1: GitLab Pipelines (Basic)
- Pipeline execution times (p50, p95, p99)
- Success/failure rates
- Pipeline frequency
- Average duration by project

### Dashboard 2: System Metrics (Comprehensive)
- CPU usage (system-wide and per-core)
- Memory usage (free, used, cached)
- Disk I/O (read/write rates)
- Network throughput
- Process count

### Dashboard 3: Advanced Monitoring
- Custom alerts for pipeline failures
- Resource bottleneck detection
- GitLab service health status
- Sidekiq job queue depth
- Error rate trends

---

## Alert Rules

### Critical Alerts
- GitLab service down
- Disk space < 10%
- Memory usage > 90%

### Warning Alerts
- Pipeline failure rate > 20%
- High CPU usage > 80%
- Disk I/O wait time high
- Sidekiq queue depth > 1000

---

## Troubleshooting

### GitLab Not Starting
```bash
# Check logs
journalctl -u gitlab -n 100 -f

# Verify database
gitlab-rake db:migrate
```

### Prometheus Not Scraping Metrics
```bash
# Check Prometheus targets
curl http://localhost:9092/api/v1/targets

# Check GitLab metrics endpoint
curl http://localhost:9090/metrics
```

### Grafana Dashboards Not Showing Data
1. Verify Prometheus data source is configured
2. Check target status in Prometheus UI
3. Run queries in Prometheus: `up{job="gitlab"}` should return 1

---

## Performance Tuning

### For 8GB RAM System
```yaml
# /etc/gitlab/gitlab.rb
puma['worker_processes'] = 2
puma['worker_timeout'] = 60
```

### For Limited Disk Space
- Configure log rotation
- Reduce Prometheus retention: `--storage.tsdb.retention.time=7d`
- Archive old pipeline data

---

## Next Steps

1. **Use the GitLab Runner section above** to register one or more runners for distributed CI/CD execution
2. **Configure SSL/TLS** with self-signed certificates
3. **Set up backup strategy** for databases
4. **Integrate with external notification systems** (Slack, email)
5. **Add custom metrics** from your applications

---

## Support & Resources

- GitLab Docs: https://docs.gitlab.com/
- Prometheus Docs: https://prometheus.io/docs/
- Grafana Docs: https://grafana.com/docs/
- Issue tracking: Create an issue in this repository
