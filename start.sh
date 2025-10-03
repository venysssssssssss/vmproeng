#!/bin/bash

# Data Engineering Project - Startup Script
# This script initializes and starts the complete data pipeline

set -e

echo "============================================"
echo "Data Engineering Project - Initialization"
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Create necessary directories
echo -e "${YELLOW}Creating project directories...${NC}"
mkdir -p airflow/dags airflow/logs airflow/plugins
mkdir -p spark/jobs spark/notebooks
mkdir -p data/raw data/staging data/processed
mkdir -p sql/init
mkdir -p config monitoring

# Set proper permissions
echo -e "${YELLOW}Setting permissions...${NC}"
chmod -R 755 airflow spark data sql config monitoring

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    cat > .env << EOF
# Airflow
AIRFLOW_UID=50000
AIRFLOW_GID=0

# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=datawarehouse

# MinIO
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
EOF
fi

# Pull Docker images
echo -e "${YELLOW}Pulling Docker images...${NC}"
docker-compose pull

# Start services
echo -e "${YELLOW}Starting services...${NC}"
docker-compose up -d

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 20

# Check service health
echo -e "${YELLOW}Checking service health...${NC}"

check_service() {
    if docker ps | grep -q $1; then
        echo -e "${GREEN}✓ $1 is running${NC}"
    else
        echo -e "${RED}✗ $1 is not running${NC}"
    fi
}

check_service "de_postgres"
check_service "de_redis"
check_service "de_minio"
check_service "de_airflow_webserver"
check_service "de_airflow_scheduler"
check_service "de_spark_master"
check_service "de_spark_worker"
check_service "de_metabase"

# Display access information
echo ""
echo "============================================"
echo -e "${GREEN}Services are ready!${NC}"
echo "============================================"
echo ""
echo -e "${YELLOW}Access URLs:${NC}"
echo -e "  Airflow UI:    http://localhost:8080 (admin/admin)"
echo -e "  Spark Master:  http://localhost:8081"
echo -e "  MinIO Console: http://localhost:9001 (minioadmin/minioadmin)"
echo -e "  Metabase:      http://localhost:3000"
echo ""
echo -e "${YELLOW}Database Connection:${NC}"
echo -e "  Host:     localhost"
echo -e "  Port:     5432"
echo -e "  Database: datawarehouse"
echo -e "  User:     postgres"
echo -e "  Password: postgres"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo -e "  View logs:           docker-compose logs -f [service_name]"
echo -e "  Stop all services:   docker-compose down"
echo -e "  Restart services:    docker-compose restart"
echo -e "  Execute DAG:         docker-compose exec airflow-webserver airflow dags trigger ecommerce_etl_pipeline"
echo ""
echo -e "${GREEN}Setup complete! Happy data engineering! 🚀${NC}"
echo ""
