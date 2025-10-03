#!/bin/bash
# Script de Teste Completo do Projeto
# Executa todos os testes e validações necessárias

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "  Data Engineering - Test Suite"
echo "=========================================="
echo ""

# Função para print com status
print_test() {
    local status=$1
    local message=$2
    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}✓${NC} $message"
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}✗${NC} $message"
    else
        echo -e "${YELLOW}➜${NC} $message"
    fi
}

# Teste 1: Verificar Python e Poetry
echo -e "${BLUE}[1/10] Verificando ambiente Python...${NC}"
if python --version | grep -q "3.11"; then
    print_test "OK" "Python 3.11 instalado"
else
    print_test "FAIL" "Python 3.11 não encontrado"
    exit 1
fi

if command -v poetry &> /dev/null; then
    print_test "OK" "Poetry instalado"
else
    print_test "FAIL" "Poetry não encontrado"
fi

# Teste 2: Verificar Docker
echo ""
echo -e "${BLUE}[2/10] Verificando Docker...${NC}"
if command -v docker &> /dev/null; then
    print_test "OK" "Docker instalado"
else
    print_test "FAIL" "Docker não encontrado"
    exit 1
fi

if docker ps &> /dev/null; then
    print_test "OK" "Docker daemon está rodando"
else
    print_test "FAIL" "Docker daemon não está rodando"
    exit 1
fi

# Teste 3: Verificar containers
echo ""
echo -e "${BLUE}[3/10] Verificando containers...${NC}"

containers=("de_postgres" "de_redis" "de_minio" "de_airflow_webserver" "de_airflow_scheduler" "de_spark_master" "de_spark_worker" "de_metabase")

for container in "${containers[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        print_test "OK" "$container está rodando"
    else
        print_test "FAIL" "$container não está rodando"
        echo -e "${YELLOW}Dica: Execute './start.sh' para iniciar os serviços${NC}"
        exit 1
    fi
done

# Teste 4: Verificar conectividade PostgreSQL
echo ""
echo -e "${BLUE}[4/10] Testando PostgreSQL...${NC}"
if docker exec de_postgres pg_isready -U postgres &> /dev/null; then
    print_test "OK" "PostgreSQL está aceitando conexões"
    
    # Verificar databases
    if docker exec de_postgres psql -U postgres -lqt | cut -d \| -f 1 | grep -qw datawarehouse; then
        print_test "OK" "Database 'datawarehouse' existe"
    else
        print_test "FAIL" "Database 'datawarehouse' não encontrado"
    fi
else
    print_test "FAIL" "PostgreSQL não está respondendo"
fi

# Teste 5: Verificar Redis
echo ""
echo -e "${BLUE}[5/10] Testando Redis...${NC}"
if docker exec de_redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
    print_test "OK" "Redis está respondendo"
else
    print_test "FAIL" "Redis não está respondendo"
fi

# Teste 6: Verificar endpoints HTTP
echo ""
echo -e "${BLUE}[6/10] Testando endpoints HTTP...${NC}"

test_endpoint() {
    local url=$1
    local name=$2
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|302\|401"; then
        print_test "OK" "$name está acessível ($url)"
        return 0
    else
        print_test "FAIL" "$name não está acessível ($url)"
        return 1
    fi
}

test_endpoint "http://localhost:8080/health" "Airflow"
test_endpoint "http://localhost:8081" "Spark Master"
test_endpoint "http://localhost:9001" "MinIO Console"
test_endpoint "http://localhost:3000" "Metabase"

# Teste 7: Verificar DAGs do Airflow
echo ""
echo -e "${BLUE}[7/10] Verificando DAGs do Airflow...${NC}"
dags=$(docker exec de_airflow_webserver airflow dags list 2>/dev/null | tail -n +4 | wc -l)
if [ "$dags" -gt 0 ]; then
    print_test "OK" "$dags DAGs carregadas no Airflow"
    
    # Listar DAGs
    echo -e "${YELLOW}DAGs disponíveis:${NC}"
    docker exec de_airflow_webserver airflow dags list 2>/dev/null | tail -n +4 | head -10
else
    print_test "FAIL" "Nenhuma DAG encontrada"
fi

# Teste 8: Verificar schemas do banco
echo ""
echo -e "${BLUE}[8/10] Verificando schemas do banco de dados...${NC}"

schemas=("raw" "staging" "processed" "analytics")
for schema in "${schemas[@]}"; do
    if docker exec de_postgres psql -U postgres -d datawarehouse -c "\dn" 2>/dev/null | grep -q "$schema"; then
        print_test "OK" "Schema '$schema' existe"
    else
        print_test "FAIL" "Schema '$schema' não encontrado"
    fi
done

# Teste 9: Verificar tabelas
echo ""
echo -e "${BLUE}[9/10] Verificando tabelas principais...${NC}"

check_table() {
    local table=$1
    if docker exec de_postgres psql -U postgres -d datawarehouse -c "\dt $table" 2>/dev/null | grep -q "$table"; then
        print_test "OK" "Tabela '$table' existe"
        return 0
    else
        print_test "FAIL" "Tabela '$table' não encontrada"
        return 1
    fi
}

check_table "raw.sales_transactions"
check_table "staging.sales_clean"
check_table "processed.dim_customers"
check_table "processed.dim_products"
check_table "processed.dim_date"
check_table "processed.fact_sales"
check_table "analytics.daily_sales_summary"

# Teste 10: Executar pipeline de teste
echo ""
echo -e "${BLUE}[10/10] Executando pipeline de teste...${NC}"
echo -e "${YELLOW}Triggering DAG: ecommerce_etl_pipeline${NC}"

if docker exec de_airflow_webserver airflow dags trigger ecommerce_etl_pipeline &> /dev/null; then
    print_test "OK" "Pipeline ETL iniciado com sucesso"
    echo -e "${YELLOW}Aguarde ~30 segundos para conclusão...${NC}"
    sleep 30
    
    # Verificar se há dados
    count=$(docker exec de_postgres psql -U postgres -d datawarehouse -t -c "SELECT COUNT(*) FROM raw.sales_transactions;" 2>/dev/null | tr -d ' ')
    if [ "$count" -gt 0 ]; then
        print_test "OK" "Dados carregados: $count registros em raw.sales_transactions"
    else
        print_test "FAIL" "Nenhum dado encontrado em raw.sales_transactions"
    fi
else
    print_test "FAIL" "Erro ao iniciar pipeline ETL"
fi

# Relatório de Recursos
echo ""
echo -e "${BLUE}Uso de Recursos:${NC}"
echo "----------------"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -n 9

# Resumo Final
echo ""
echo "=========================================="
echo -e "${GREEN}Testes Concluídos!${NC}"
echo "=========================================="
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. Acesse Airflow: http://localhost:8080 (admin/admin)"
echo "2. Monitore execução das DAGs"
echo "3. Verifique dados no PostgreSQL"
echo "4. Configure Metabase: http://localhost:3000"
echo ""
echo -e "${YELLOW}Comandos úteis:${NC}"
echo "- Ver logs:       docker-compose logs -f [service]"
echo "- Parar projeto:  ./stop.sh"
echo "- Limpar dados:   ./stop.sh --clean"
echo "- Ver ajuda:      make help"
echo ""
