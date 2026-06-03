# Start Services Guide

This guide covers the current, working way to start the monitoring stack from Windows using WSL.

## Current Service URLs

| Service | URL | Notes |
|---|---|---|
| GitLab | http://localhost:8081 | GitLab can take several minutes to finish booting |
| Grafana | http://localhost:3001 | Default login: `admin / admin` |
| Prometheus | http://localhost:9092 | Health endpoint: `/-/healthy` |
| Node Exporter | http://localhost:9101/metrics | Raw metrics endpoint |

## Why Use WSL Root

In this environment, Docker is available inside WSL, but the Windows PowerShell session does not have direct access to the Docker daemon.

Use this pattern for service commands:

```bash
wsl -u root bash -lc "cd /mnt/c/Users/ammar/OneDrive/Documents/GitLab-CICD-Pipeline-Monitoring && <command>"
```

## Start All Services

Run:

```bash
wsl -u root bash -lc "cd /mnt/c/Users/ammar/OneDrive/Documents/GitLab-CICD-Pipeline-Monitoring && docker compose up -d"
```

Check status:

```bash
wsl -u root bash -lc "cd /mnt/c/Users/ammar/OneDrive/Documents/GitLab-CICD-Pipeline-Monitoring && docker compose ps"
```

## Start Only Selected Services

Start GitLab, Prometheus, and Grafana:

```bash
wsl -u root bash -lc "cd /mnt/c/Users/ammar/OneDrive/Documents/GitLab-CICD-Pipeline-Monitoring && docker compose up -d gitlab prometheus grafana"
```

Start only Prometheus:

```bash
wsl -u root bash -lc "cd /mnt/c/Users/ammar/OneDrive/Documents/GitLab-CICD-Pipeline-Monitoring && docker compose up -d prometheus"
```

Start only Grafana:

```bash
wsl -u root bash -lc "cd /mnt/c/Users/ammar/OneDrive/Documents/GitLab-CICD-Pipeline-Monitoring && docker compose up -d grafana"
```

Restart only Grafana:

```bash
wsl -u root bash -lc "cd /mnt/c/Users/ammar/OneDrive/Documents/GitLab-CICD-Pipeline-Monitoring && docker compose restart grafana"
```

## Verify Services

Check Prometheus health:

```bash
curl http://localhost:9092/-/healthy
```

Check Grafana health:

```bash
curl http://localhost:3001/api/health
```

Check GitLab health:

```bash
curl http://localhost:8081/-/health
```

If GitLab returns `502` immediately after startup, wait a few minutes and retry. That usually means the Rails app is still booting.

## View Logs

View all logs:

```bash
wsl -u root bash -lc "cd /mnt/c/Users/ammar/OneDrive/Documents/GitLab-CICD-Pipeline-Monitoring && docker compose logs -f"
```

View one service:

```bash
wsl -u root bash -lc "cd /mnt/c/Users/ammar/OneDrive/Documents/GitLab-CICD-Pipeline-Monitoring && docker compose logs -f prometheus"
```

Replace `prometheus` with `gitlab`, `grafana`, `postgres`, `redis`, or `node-exporter` as needed.

## Stop Services

Stop the whole stack:

```bash
wsl -u root bash -lc "cd /mnt/c/Users/ammar/OneDrive/Documents/GitLab-CICD-Pipeline-Monitoring && docker compose stop"
```

Stop one service:

```bash
wsl -u root bash -lc "cd /mnt/c/Users/ammar/OneDrive/Documents/GitLab-CICD-Pipeline-Monitoring && docker compose stop prometheus"
```

## Common Issues

### `docker: command not found`

Run the command through WSL, not plain Windows PowerShell.

### `permission denied while trying to connect to the Docker daemon socket`

Use the WSL root form shown in this guide, or configure your WSL user for Docker group access.

### GitLab is up but not ready

GitLab is the slowest service in the stack. `postgres` and `redis` usually become healthy first, followed by Grafana and Prometheus, and GitLab last.

### Prometheus page does not load

Confirm the container is up:

```bash
wsl -u root bash -lc "cd /mnt/c/Users/ammar/OneDrive/Documents/GitLab-CICD-Pipeline-Monitoring && docker compose ps prometheus"
```

Then check:

```bash
curl http://localhost:9092/-/healthy
```