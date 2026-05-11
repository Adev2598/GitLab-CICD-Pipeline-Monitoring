# Troubleshooting Guide

## Common Issues and Solutions

### 1. GitLab Service Won't Start

**Symptom**: GitLab container exits immediately or stays in "unhealthy" state

**Diagnostic Steps**:
```bash
# Check container logs
docker-compose logs gitlab | tail -50

# Verify database connection
docker-compose exec gitlab gitlab-rake db:migrate

# Check configuration
docker-compose exec gitlab cat /etc/gitlab/gitlab.rb | grep -E "(external_url|db_|redis_)"
```

**Solutions**:
- **Database error**: Ensure PostgreSQL is running: `docker-compose logs postgres`
- **Port already in use**: Check if port 80/443 are free: `netstat -an | grep LISTEN`
- **Memory issue**: Increase Docker memory allocation in Docker Desktop settings
- **Configuration error**: Verify `docker-compose.yml` environment variables

### 2. Prometheus Not Scraping Metrics

**Symptom**: "DOWN" status on Prometheus targets page

**Diagnostic Steps**:
```bash
# Check Prometheus logs
docker-compose logs prometheus | grep -i "error\|scrape"

# Test connectivity to target
docker-compose exec prometheus curl http://gitlab:9090/metrics

# Verify prometheus.yml syntax
docker-compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

**Solutions**:
- **GitLab metrics disabled**: Check `prometheus_monitoring['enable'] = true` in gitlab.rb
- **Port mismatch**: Verify port numbers in `prometheus.yml` match docker-compose ports
- **Service not ready**: Wait 2-3 minutes for GitLab to fully initialize
- **Network issue**: Containers must be on same network: `docker network inspect gitlab-monitoring`

### 3. Grafana Dashboard Shows "No Data"

**Symptom**: Grafana panels display "No data" or show 0 series

**Diagnostic Steps**:
```bash
# Check data source
1. Go to http://localhost:3000/datasources
2. Click "Prometheus"
3. Click "Save & Test"

# Test Prometheus query directly
curl 'http://localhost:9091/api/v1/query?query=up'

# Check for metrics in Prometheus
1. Go to http://localhost:9091
2. Search for 'gitlab_' or 'node_'
```

**Solutions**:
- **Data source URL wrong**: Should be `http://prometheus:9090` for Docker, `http://localhost:9091` for external
- **Metrics not being scraped**: Check Prometheus targets (all should show "UP")
- **Query syntax error**: Test PromQL query directly in Prometheus UI
- **No metrics data yet**: Allow 2-3 minutes for first data to be collected
- **Data retention expired**: Check Prometheus `--storage.tsdb.retention.time` setting

### 4. High CPU or Memory Usage

**Symptom**: System running slowly, services taking long to respond

**Diagnostic Steps**:
```bash
# Check resource usage
docker stats

# Check which process is using resources
docker-compose exec gitlab top
docker-compose exec prometheus top

# Check for memory leaks
docker-compose logs prometheus | grep "memory"
```

**Solutions**:
- **Prometheus retention too long**: Reduce retention: `--storage.tsdb.retention.time=7d`
- **Too many metrics**: Reduce scrape frequency or metrics volume
- **GitLab needs more resources**: Increase worker processes in docker-compose
- **Disk full**: Clean up old data: `docker exec prometheus rm -rf /prometheus/wal`

### 5. PostgreSQL Connection Issues

**Symptom**: GitLab can't connect to database

**Diagnostic Steps**:
```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Test connection
docker-compose exec postgres psql -U gitlab -d gitlabhq_production -c "SELECT version();"

# Check logs
docker-compose logs postgres
```

**Solutions**:
- **Wrong credentials**: Verify `POSTGRES_USER` and `POSTGRES_PASSWORD` in docker-compose.yml
- **Database not initialized**: Run: `docker-compose exec gitlab gitlab-rake db:create db:migrate`
- **Permissions issue**: Check PostgreSQL user has correct permissions
- **Disk space**: Ensure /var/lib/postgresql/data has space

### 6. Redis Connection Issues

**Symptom**: GitLab timeout errors, background jobs not processing

**Diagnostic Steps**:
```bash
# Check Redis is running
docker-compose ps redis

# Test connection
docker-compose exec redis redis-cli ping

# Check Redis memory
docker-compose exec redis redis-cli info memory
```

**Solutions**:
- **Redis OOM**: Too many jobs queued: `docker-compose exec redis redis-cli dbsize`
- **Connection refused**: Verify Redis is running and port is correct
- **Persistence issues**: Clear Redis: `docker-compose exec redis redis-cli FLUSHDB`

### 7. Port Already in Use

**Symptom**: `Error starting userland proxy: listen tcp 0.0.0.0:80: bind: An attempt was made to use a port in a non-permissive state`

**Diagnostic Steps**:
```bash
# On Windows PowerShell, find what's using the port
netstat -ano | findstr :80
taskkill /PID <PID> /F
```

**Solutions**:
- **Stop other services**: IIS, Apache, or Nginx might be using port 80
- **Use different port**: Modify docker-compose.yml: `"8080:80"`
- **Disable Windows service**: `net stop http` (careful with Windows services)

### 8. GitLab SSL Certificate Issues

**Symptom**: HTTPS connections fail, certificate warnings

**Solutions** (Development):
```bash
# Generate self-signed certificate
openssl req -x509 -newkey rsa:2048 -nodes -out cert.pem -keyout key.pem -days 365

# Copy to GitLab config directory
docker cp cert.pem gitlab:/etc/gitlab/ssl/
docker cp key.pem gitlab:/etc/gitlab/ssl/

# Reconfigure GitLab
docker-compose exec gitlab gitlab-ctl reconfigure
```

### 9. Grafana Login Issues

**Symptom**: Can't access Grafana, reset credentials

**Solutions**:
```bash
# Reset admin password
docker-compose exec grafana grafana-cli admin reset-admin-password <new-password>

# Or reset database
docker volume rm gitlab-monitoring_grafana_data
docker-compose restart grafana
# Login with: admin/admin
```

### 10. Backup and Recovery

**Backup all data**:
```bash
# Backup GitLab
docker-compose exec gitlab gitlab-rake gitlab:backup:create

# Backup databases
docker-compose exec postgres pg_dump -U gitlab gitlabhq_production > backup.sql

# Copy volumes
docker run --rm -v gitlab-monitoring_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz /data
```

**Restore from backup**:
```bash
# Restore GitLab backup
docker-compose exec gitlab gitlab-rake gitlab:backup:restore BACKUP=<timestamp>

# Restore database
docker-compose exec postgres psql -U gitlab gitlabhq_production < backup.sql
```

## Performance Tuning

### Optimize Prometheus
```yaml
# config/prometheus/prometheus.yml
global:
  scrape_interval: 30s        # Reduce from 15s for less CPU
  evaluation_interval: 60s    # Reduce from 30s for less CPU

scrape_configs:
  - job_name: 'gitlab'
    scrape_interval: 60s      # Less frequent scraping
```

### Optimize Grafana
```bash
docker-compose exec grafana grafana-cli admin set-user-password admin newpassword
# Reduce dashboard refresh: Set to 30-60 seconds
# Disable animations: Settings → UI → Animation enabled = false
```

### Optimize PostgreSQL
```bash
# Increase shared_buffers
docker-compose exec postgres bash -c "echo 'shared_buffers = 256MB' >> /var/lib/postgresql/data/postgresql.conf"
docker-compose restart postgres
```

## Debug Logging

### Enable Verbose Logging
```bash
# GitLab
docker-compose exec gitlab gitlab-ctl set-log-level debug

# Prometheus
docker-compose down
# Edit docker-compose.yml: add '--log.level=debug' to prometheus command
docker-compose up -d

# Grafana
docker-compose exec grafana grafana-cli plugins install grafana-debug-plugin
```

### Monitor Logs in Real-Time
```bash
docker-compose logs -f                 # All services
docker-compose logs -f gitlab          # GitLab only
docker-compose logs -f prometheus      # Prometheus only
docker-compose logs -f --tail=100      # Last 100 lines
```

## Getting Help

1. **Check logs first**: Most issues are visible in container logs
2. **Search documentation**: 
   - GitLab: https://docs.gitlab.com/
   - Prometheus: https://prometheus.io/docs/
   - Grafana: https://grafana.com/docs/
3. **Community resources**:
   - GitLab forum: https://forum.gitlab.com/
   - Prometheus community: https://prometheus.io/community/
4. **Create an issue**: Include logs and configuration (sanitized)

## Quick Reference

### Container Management
```bash
docker-compose ps              # Show status
docker-compose logs            # View logs
docker-compose exec <svc> bash # Access container shell
docker-compose restart <svc>   # Restart service
docker-compose stop            # Stop all services
docker-compose down -v         # Remove with volumes (data loss)
```

### Useful Commands
```bash
# Check metrics
curl http://localhost:9090/metrics | head -20

# Query Prometheus
curl 'http://localhost:9091/api/v1/query?query=up'

# Check services
docker ps
docker stats
```

---

**Last Updated**: May 2026
**Version**: 1.0
