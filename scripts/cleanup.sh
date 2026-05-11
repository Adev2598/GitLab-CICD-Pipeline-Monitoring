#!/bin/bash
# Cleanup script - Remove all containers, volumes, and data
# WARNING: This will delete all data!

set -e

echo "⚠️  WARNING: This will delete all GitLab data, databases, and configurations!"
read -p "Are you sure? Type 'yes' to confirm: " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo "Stopping services..."
docker-compose down -v

echo "Removing data directories..."
rm -rf postgres_data redis_data gitlab_data gitlab_config gitlab_logs prometheus_data grafana_data

echo "✓ Cleanup complete"
echo ""
echo "To restart, run: bash scripts/quick-start.sh"
