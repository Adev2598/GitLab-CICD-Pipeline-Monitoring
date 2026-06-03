# GitLab CI/CD Pipeline Monitoring

**Complete monitoring stack for GitLab CI/CD pipelines using Prometheus and Grafana, deployed in WSL2.**

![Version](https://img.shields.io/badge/version-1.0-blue) ![License](https://img.shields.io/badge/license-MIT-green)

## 🎯 Features

- ✅ **GitLab Community Edition** - Full CI/CD platform
- ✅ **Prometheus** - Metrics collection and alerting
- ✅ **Grafana** - Beautiful dashboards and visualization
- ✅ **System Monitoring** - CPU, memory, disk, network metrics
- ✅ **Pipeline Analytics** - Duration, success rates, execution frequency
- ✅ **Alert Rules** - Automated detection of issues
- ✅ **Docker Compose** - One-command deployment
- ✅ **Pre-configured Dashboards** - 3 production-ready dashboards
- ✅ **Sample Pipelines** - Example CI/CD workflows

## 📋 Quick Start (5 minutes)

### Prerequisites
- WSL2 with Ubuntu 22.04 LTS
- Docker & Docker Compose installed
- 8GB RAM minimum, 50GB disk space

### Deploy

```bash
# Clone or download this repository
cd GitLab-CICD-Pipeline-Monitoring

# Make scripts executable
chmod +x scripts/*.sh

# Start the stack
bash scripts/quick-start.sh
```

### Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| **GitLab** | http://localhost | Set on first login |
| **Grafana** | http://localhost:3001 | admin / admin |
| **Prometheus** | http://localhost:9092 | (read-only) |

## 📁 Project Structure

```
GitLab-CICD-Pipeline-Monitoring/
├── README.md                          # This file
├── docker-compose.yml                 # Complete stack definition
├── config/                            # Configuration files
│   ├── gitlab/                        # GitLab config templates
│   ├── prometheus/                    # Prometheus config & alert rules
│   │   ├── prometheus.yml             # Scrape jobs & settings
│   │   └── alert_rules.yml            # Alert definitions
│   └── grafana/                       # Grafana configs
│       ├── provisioning/              # Auto-provisioned configs
│       │   ├── datasources/           # Prometheus data source
│       │   └── dashboards/            # Pre-built dashboards
│       └── dashboards/                # Dashboard JSONs
├── docs/                              # Documentation
│   ├── SETUP_GUIDE.md                 # Detailed installation guide
│   ├── ARCHITECTURE.md                # System architecture
│   └── TROUBLESHOOTING.md             # Common issues & solutions
├── scripts/                           # Helper scripts
│   ├── quick-start.sh                 # Deploy everything
│   ├── status.sh                      # Check service health
│   └── cleanup.sh                     # Remove all data
└── samples/                           # Sample CI/CD pipelines
	 ├── simple-pipeline/               # Successful pipeline example
	 ├── failed-pipeline/               # Failed pipeline example
	 └── long-running-pipeline/         # Long-running pipeline example
```

## 🚀 What Gets Installed

### Core Stack
- **GitLab CE** - Full-featured CI/CD platform with built-in metrics
- **PostgreSQL 16** - Persistent database for GitLab
- **Redis 7** - Session store and job queue
- **Prometheus 2.48** - Time-series metrics database
- **Grafana 10** - Visualization and dashboarding
- **Node Exporter** - System-level metrics collection

### Metrics Collected

**GitLab Metrics**:
- Pipeline execution times and counts
- Success/failure rates by project
- Sidekiq job queue depth
- HTTP request latency
- Database query performance

**System Metrics**:
- CPU usage (per-core and average)
- Memory usage (free, cached, buffers)
- Disk I/O (read/write rates)
- Network throughput
- Filesystem usage
- Process information

### Pre-built Dashboards

1. **GitLab Pipelines (Basic)**
	- Pipeline duration trends
	- Success/failure distribution
	- Execution rate over time
	- Failed pipeline rate

2. **System Metrics (Comprehensive)**
	- CPU usage gauge
	- Memory usage trend
	- Disk space availability
	- Network I/O bandwidth

3. **Advanced Monitoring**
	- Custom alert status
	- Resource bottleneck detection
	- GitLab service health
	- Detailed performance metrics

## 📊 Usage Guide

### Create Your First Pipeline

```bash
# 1. Open GitLab
# http://localhost → Set root password

# 2. Create a group
# Menu → Groups → New Group → "my-projects"

# 3. Create a project
# Groups → my-projects → New Project

# 4. Add CI/CD configuration
# Add file: .gitlab-ci.yml
# Copy from: samples/simple-pipeline/.gitlab-ci.yml

# 5. Trigger pipeline
# Push to repository or manually trigger

# 6. View metrics in Grafana
# http://localhost:3001 → Dashboards → GitLab CI/CD Pipelines
```

### Monitor in Real-Time

```bash
# View all service logs
docker-compose logs -f

# Check Prometheus metrics
curl http://localhost:9092/api/v1/query?query=ci_created_builds

# Access Prometheus UI
http://localhost:9092 → Graph tab
```

## ⚙️ Configuration

### Change Grafana Password
```bash
docker-compose exec grafana grafana-cli admin reset-admin-password newpassword
```

### Modify Scrape Interval
Edit `config/prometheus/prometheus.yml`:
```yaml
global:
  scrape_interval: 30s    # Change from 15s
```

### Add Custom Alert Rules
Edit `config/prometheus/alert_rules.yml` and restart:
```bash
docker-compose restart prometheus
```

## 🛠️ Management Commands

```bash
# Check status
bash scripts/status.sh

# View logs
docker-compose logs -f [service]
# Services: gitlab, postgres, redis, prometheus, grafana, node-exporter

# Stop the stack
docker-compose stop

# Start the stack
docker-compose start

# Restart a service
docker-compose restart gitlab

# Full cleanup (⚠️ deletes all data)
bash scripts/cleanup.sh
```

## 📚 Documentation

- **[SETUP_GUIDE.md](docs/SETUP_GUIDE.md)** - Detailed installation and configuration
- **[START_SERVICES_GUIDE.md](docs/START_SERVICES_GUIDE.md)** - Current commands for starting and verifying services in WSL
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System architecture and component details
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## 🔒 Security Notes

### Current Configuration (Development)
- ⚠️ Default Grafana credentials: `admin/admin`
- ⚠️ PostgreSQL password hardcoded
- ⚠️ No SSL/TLS configured
- ℹ️ Suitable for **local development only**

### Production Hardening
1. Change all default passwords
2. Configure SSL certificates
3. Set up firewall rules
4. Enable GitLab 2FA
5. Use strong database passwords
6. Regular backups

## 📈 Performance & Scaling

### System Requirements
- **Development**: 8GB RAM, 50GB SSD
- **Testing**: 16GB RAM, 100GB SSD  
- **Production**: 32GB+ RAM, 500GB+ SSD

### Resource Usage (Typical)
| Service | CPU | Memory |
|---------|-----|--------|
| GitLab | 40-60% | 800MB |
| Prometheus | 5-10% | 300MB |
| Grafana | 2-5% | 150MB |

### Optimization Tips
- Reduce Prometheus scrape interval for less CPU
- Increase Prometheus retention carefully (disk impact)
- Use Grafana panel caching
- Optimize alert rules frequency

## 🐛 Troubleshooting

- **Services won't start**: Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- **No metrics in Grafana**: Verify Prometheus targets are "UP"
- **Port already in use**: Change ports in `docker-compose.yml`
- **Out of disk space**: Clean up logs: `docker container prune`

## 📝 Sample Pipelines

Three example CI/CD pipelines are included:

### 1. Simple Pipeline
```yaml
# samples/simple-pipeline/.gitlab-ci.yml
# Stages: build → test → deploy
# Total time: ~12 seconds
# Result: SUCCESS
```

### 2. Failed Pipeline
```yaml
# samples/failed-pipeline/.gitlab-ci.yml
# Stages: build → test → deploy (stops at test)
# Test failure demonstrates monitoring capabilities
# Result: FAILED
```

### 3. Long-Running Pipeline
```yaml
# samples/long-running-pipeline/.gitlab-ci.yml
# Stages: build → test → integration_test → deploy
# Total time: ~75 seconds
# Result: SUCCESS
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or PRs.

## 📄 License

MIT License - See LICENSE file for details

## 🔗 Resources

- [GitLab Documentation](https://docs.gitlab.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [WSL2 Setup Guide](https://docs.microsoft.com/en-us/windows/wsl/)
- [Docker Documentation](https://docs.docker.com/)

## 💡 Tips & Tricks

### Access GitLab Shell
```bash
docker-compose exec gitlab gitlab-rails console
```

### Backup All Data
```bash
docker-compose exec gitlab gitlab-rake gitlab:backup:create
```

### View Prometheus Metrics
```bash
curl http://localhost:9092/metrics
```

### Reset Grafana to Defaults
```bash
docker-compose down -v
docker volume rm gitlab-monitoring_grafana_data
docker-compose up -d
```

---

**Questions or Issues?** Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) or [SETUP_GUIDE.md](docs/SETUP_GUIDE.md)

**Last Updated**: May 2026
**Version**: 1.0
