#!/bin/bash

# Health Check Script - Verifica saúde de todos os serviços

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "  Data Engineering - Health Check"
echo "========================================"
echo ""

# Função para verificar se container está rodando
check_container() {
    local container_name=$1
    local display_name=$2
    
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        # Container está rodando, verificar saúde
        health=$(docker inspect --format='{{.State.Health.Status}}' ${container_name} 2>/dev/null)
        
        if [ "$health" == "healthy" ]; then
            echo -e "${GREEN}✓${NC} ${display_name}: ${GREEN}Healthy${NC}"
            return 0
        elif [ "$health" == "unhealthy" ]; then
            echo -e "${RED}✗${NC} ${display_name}: ${RED}Unhealthy${NC}"
            return 1
        else
            # Container sem healthcheck, verificar se está rodando
            status=$(docker inspect --format='{{.State.Status}}' ${container_name} 2>/dev/null)
            if [ "$status" == "running" ]; then
                echo -e "${GREEN}✓${NC} ${display_name}: ${GREEN}Running${NC}"
                return 0
            else
                echo -e "${RED}✗${NC} ${display_name}: ${RED}Not Running${NC}"
                return 1
            fi
        fi
    else
        echo -e "${RED}✗${NC} ${display_name}: ${RED}Not Found${NC}"
        return 1
    fi
}

# Verificar todos os containers
echo "Container Status:"
echo "----------------"
check_container "de_postgres" "PostgreSQL"
check_container "de_redis" "Redis"
check_container "de_minio" "MinIO"
check_container "de_airflow_webserver" "Airflow Webserver"
check_container "de_airflow_scheduler" "Airflow Scheduler"
check_container "de_spark_master" "Spark Master"
check_container "de_spark_worker" "Spark Worker"
check_container "de_metabase" "Metabase"

echo ""
echo "Service Endpoints:"
echo "-----------------"

# Verificar endpoints HTTP
check_endpoint() {
    local url=$1
    local name=$2
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|302\|401"; then
        echo -e "${GREEN}✓${NC} ${name}: ${GREEN}Accessible${NC} (${url})"
    else
        echo -e "${RED}✗${NC} ${name}: ${RED}Not Accessible${NC} (${url})"
    fi
}

check_endpoint "http://localhost:8080/health" "Airflow"
check_endpoint "http://localhost:8081" "Spark Master"
check_endpoint "http://localhost:9001" "MinIO Console"
check_endpoint "http://localhost:3000" "Metabase"

echo ""
echo "Database Connectivity:"
echo "---------------------"

# Verificar conexão PostgreSQL
if docker exec de_postgres pg_isready -U postgres > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} PostgreSQL: ${GREEN}Accepting connections${NC}"
    
    # Verificar databases
    databases=$(docker exec de_postgres psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datname IN ('datawarehouse', 'airflow', 'metabase');" 2>/dev/null | tr -d ' ')
    echo "  Databases: $databases"
else
    echo -e "${RED}✗${NC} PostgreSQL: ${RED}Not accepting connections${NC}"
fi

# Verificar Redis
if docker exec de_redis redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Redis: ${GREEN}Responding${NC}"
else
    echo -e "${RED}✗${NC} Redis: ${RED}Not responding${NC}"
fi

echo ""
echo "Resource Usage:"
echo "--------------"

# Mostrar uso de recursos
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -n 9

echo ""
echo "Airflow DAGs:"
echo "------------"

# Verificar DAGs do Airflow
if docker exec de_airflow_webserver airflow dags list 2>/dev/null | tail -n +4; then
    echo -e "${GREEN}DAGs loaded successfully${NC}"
else
    echo -e "${YELLOW}Warning: Could not fetch DAGs${NC}"
fi

echo ""
echo "========================================"
echo "  Health Check Complete"
echo "========================================"
