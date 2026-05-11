#!/bin/bash
# Quick Start Script - Deploy GitLab monitoring stack with Docker Compose
# Usage: bash ./scripts/quick-start.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔═══════════════════════════════════════════════════════╗"
echo "║  GitLab CI/CD Pipeline Monitoring - Quick Start       ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "⚠️  Docker installed. Please log out and log in again, or run: newgrp docker"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose not found. Installing..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

echo "✓ Docker and Docker Compose ready"
echo ""

# Create data directories with proper permissions
echo "Creating data directories..."
mkdir -p {postgres_data,redis_data,gitlab_data,gitlab_config,gitlab_logs,prometheus_data,grafana_data}
echo "✓ Directories created"
echo ""

# Start the stack
echo "Starting GitLab monitoring stack..."
cd "$PROJECT_DIR"
docker-compose up -d

# Wait for services to be ready
echo ""
echo "Waiting for services to be ready (this may take 2-3 minutes)..."
echo ""

# Check PostgreSQL
echo -n "PostgreSQL: "
for i in {1..30}; do
    if docker-compose exec -T postgres pg_isready -U gitlab &>/dev/null; then
        echo "✓ Ready"
        break
    fi
    echo -n "."
    sleep 2
done

# Check Redis
echo -n "Redis: "
for i in {1..10}; do
    if docker-compose exec -T redis redis-cli ping &>/dev/null; then
        echo "✓ Ready"
        break
    fi
    echo -n "."
    sleep 2
done

# Check GitLab
echo -n "GitLab: "
for i in {1..60}; do
    if docker-compose logs gitlab 2>/dev/null | grep -q "Ready" 2>/dev/null; then
        echo "✓ Ready"
        break
    fi
    echo -n "."
    sleep 3
done

# Check Prometheus
echo -n "Prometheus: "
if curl -s http://localhost:9091/-/healthy &>/dev/null; then
    echo "✓ Ready"
else
    echo "⚠️  Starting (may take a moment)"
fi

# Check Grafana
echo -n "Grafana: "
if curl -s http://localhost:3000/api/health &>/dev/null; then
    echo "✓ Ready"
else
    echo "⚠️  Starting (may take a moment)"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║          Services Ready! Access at:                  ║"
echo "╠═══════════════════════════════════════════════════════╣"
echo "║  GitLab         http://localhost                     ║"
echo "║  Grafana        http://localhost:3000                ║"
echo "║                 (admin / admin)                      ║"
echo "║  Prometheus     http://localhost:9091                ║"
echo "║  Node Exporter  http://localhost:9100/metrics        ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "1. Access GitLab at http://localhost"
echo "2. Set admin password (you'll be prompted)"
echo "3. Log in to Grafana at http://localhost:3000"
echo "4. Create a project and add .gitlab-ci.yml from samples/"
echo "5. View metrics in Grafana dashboards"
echo ""
echo "For more details, see docs/SETUP_GUIDE.md"
