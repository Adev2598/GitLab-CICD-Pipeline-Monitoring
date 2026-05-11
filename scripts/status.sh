#!/bin/bash
# Status script - Check service health and display dashboard URLs

echo "╔═══════════════════════════════════════════════════════╗"
echo "║      GitLab Monitoring Stack - Status Check           ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Function to check service
check_service() {
    local name=$1
    local port=$2
    local endpoint=$3
    
    echo -n "Checking $name ($port)... "
    if curl -s http://localhost:$port$endpoint &>/dev/null; then
        echo "✓ UP"
        return 0
    else
        echo "✗ DOWN"
        return 1
    fi
}

# Check services
check_service "GitLab" "80" "/-/health" || true
check_service "Grafana" "3000" "/api/health" || true
check_service "Prometheus" "9091" "/-/healthy" || true
check_service "Node Exporter" "9100" "/metrics" || true

echo ""
echo "Container Status:"
docker-compose ps

echo ""
echo "Access URLs:"
echo "  GitLab:      http://localhost"
echo "  Grafana:     http://localhost:3000 (admin/admin)"
echo "  Prometheus:  http://localhost:9091"
echo "  Node Exp:    http://localhost:9100/metrics"
echo ""
echo "Logs:"
echo "  View all:     docker-compose logs -f"
echo "  GitLab only:  docker-compose logs -f gitlab"
echo "  Prometheus:   docker-compose logs -f prometheus"
echo "  Grafana:      docker-compose logs -f grafana"
