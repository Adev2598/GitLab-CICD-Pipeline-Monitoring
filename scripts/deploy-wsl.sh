#!/bin/bash
set -e
cd /mnt/c/Users/ammar/OneDrive/Documents/GitLab-CICD-Pipeline-Monitoring

echo '=== Docker images already cached ==='
docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' 2>/dev/null || true

echo ''
echo '=== Pulling all images with retries ==='
for svc in redis postgres prometheus grafana node-exporter gitlab; do
  echo "--- Pulling $svc ---"
  attempt=1
  while [ $attempt -le 8 ]; do
    if docker compose pull "$svc"; then
      echo "$svc: pulled OK"
      break
    fi
    echo "Attempt $attempt failed for $svc, retrying in 5s..."
    attempt=$((attempt + 1))
    sleep 5
  done
done

echo ''
echo '=== Starting all services ==='
docker compose up -d

echo ''
echo '=== Container status ==='
docker compose ps

echo ''
echo '=== Access URLs ==='
echo 'GitLab:     http://localhost'
echo 'Grafana:    http://localhost:3000  (admin / admin)'
echo 'Prometheus: http://localhost:9091'
