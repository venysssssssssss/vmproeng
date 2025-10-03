#!/bin/bash
# Utilitários do Data Engineering Pipeline
# Uso: ./utils.sh <comando>

set -e

PROJECT_DIR="/home/synev1/dev/vmpro1"
COMPOSE_CMD="docker-compose"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Comandos

cmd_start() {
    print_header "Iniciando Data Engineering Pipeline"
    $COMPOSE_CMD up -d
    print_success "Containers iniciados"
    echo ""
    print_warning "Aguardando inicialização (90 segundos)..."
    sleep 90
    cmd_status
}

cmd_stop() {
    print_header "Parando Data Engineering Pipeline"
    $COMPOSE_CMD down
    print_success "Containers parados"
}

cmd_restart() {
    print_header "Reiniciando Data Engineering Pipeline"
    $COMPOSE_CMD restart
    print_success "Containers reiniciados"
}

cmd_status() {
    print_header "Status dos Serviços"
    $COMPOSE_CMD ps
    echo ""
    print_header "Endpoints Disponíveis"
    echo "Dashboard:   http://localhost:8501"
    echo "Airflow:     http://localhost:8080 (admin/admin)"
    echo "Spark UI:    http://localhost:8081"
    echo "MinIO:       http://localhost:9001 (minioadmin/minioadmin)"
    echo "PostgreSQL:  localhost:5432 (postgres/postgres)"
}

cmd_logs() {
    SERVICE=${1:-}
    if [ -z "$SERVICE" ]; then
        print_header "Logs de Todos os Serviços"
        $COMPOSE_CMD logs --tail=50 -f
    else
        print_header "Logs do Serviço: $SERVICE"
        docker logs "de_$SERVICE" -f
    fi
}

cmd_memory() {
    print_header "Uso de Memória"
    docker stats --no-stream $($COMPOSE_CMD ps -q) --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}"
    echo ""
    echo "Memória Total:"
    docker stats --no-stream $($COMPOSE_CMD ps -q) --format "{{.MemUsage}}" | \
    awk -F'/' '{gsub(/MiB/, "", $1); gsub(/KiB/, "", $1); if($1 ~ /K/) sum+=$1/1024; else sum+=$1} END {printf "  %.0f MB\n", sum}'
}

cmd_clean_data() {
    print_header "Limpando Dados de Teste"
    PGPASSWORD=postgres psql -h localhost -U postgres -d datawarehouse -c "
    TRUNCATE TABLE raw.transactions_raw CASCADE;
    TRUNCATE TABLE raw.customers_raw CASCADE;
    TRUNCATE TABLE raw.products_raw CASCADE;
    " 2>/dev/null && print_success "Dados limpos" || print_error "Erro ao limpar dados"
}

cmd_reset() {
    print_header "Reset Completo (Remove Volumes)"
    read -p "Tem certeza? Todos os dados serão perdidos (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        $COMPOSE_CMD down -v
        print_success "Reset completo realizado"
    else
        print_warning "Reset cancelado"
    fi
}

cmd_test() {
    BATCH_SIZE=${1:-1000}
    NUM_BATCHES=${2:-10}
    DELAY=${3:-1}
    
    print_header "Teste de Capacidade"
    echo "Batch Size: $BATCH_SIZE"
    echo "Num Batches: $NUM_BATCHES"
    echo "Total: $((BATCH_SIZE * NUM_BATCHES)) registros"
    echo ""
    
    .venv/bin/python test_capacity.py $BATCH_SIZE $NUM_BATCHES $DELAY
}

cmd_monitor() {
    print_header "Monitor de Memória (Ctrl+C para parar)"
    ./monitor_memory.sh
}

cmd_health() {
    print_header "Health Check dos Serviços"
    
    echo -n "Dashboard (8501):      "
    curl -s -o /dev/null -w "%{http_code}" http://localhost:8501 | grep -q "200" && print_success "OK" || print_error "FALHOU"
    
    echo -n "Airflow (8080):        "
    curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "302\|200" && print_success "OK" || print_error "FALHOU"
    
    echo -n "Spark (8081):          "
    curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 | grep -q "200" && print_success "OK" || print_error "FALHOU"
    
    echo -n "MinIO (9001):          "
    curl -s -o /dev/null -w "%{http_code}" http://localhost:9001 | grep -q "200" && print_success "OK" || print_error "FALHOU"
    
    echo -n "PostgreSQL (5432):     "
    PGPASSWORD=postgres psql -h localhost -U postgres -d datawarehouse -c "SELECT 1" > /dev/null 2>&1 && print_success "OK" || print_error "FALHOU"
}

cmd_data_count() {
    print_header "Contagem de Dados"
    PGPASSWORD=postgres psql -h localhost -U postgres -d datawarehouse -c "
    SELECT 
        'Raw Transactions' as layer, 
        COUNT(*)::text as count,
        pg_size_pretty(pg_total_relation_size('raw.transactions_raw')) as size
    FROM raw.transactions_raw
    UNION ALL
    SELECT 'Raw Customers', COUNT(*)::text, pg_size_pretty(pg_total_relation_size('raw.customers_raw'))
    FROM raw.customers_raw
    UNION ALL
    SELECT 'Raw Products', COUNT(*)::text, pg_size_pretty(pg_total_relation_size('raw.products_raw'))
    FROM raw.products_raw
    UNION ALL
    SELECT 'Staging', COUNT(*)::text, pg_size_pretty(pg_total_relation_size('staging.transactions_staging'))
    FROM staging.transactions_staging
    UNION ALL
    SELECT 'Fact Sales', COUNT(*)::text, pg_size_pretty(pg_total_relation_size('processed.fact_sales'))
    FROM processed.fact_sales;
    " 2>/dev/null
}

cmd_help() {
    cat << EOF
📊 Data Engineering Pipeline - Utilitários

COMANDOS DISPONÍVEIS:

  Gerenciamento:
    start                   Iniciar todos os serviços
    stop                    Parar todos os serviços
    restart                 Reiniciar todos os serviços
    reset                   Reset completo (remove volumes)

  Monitoramento:
    status                  Ver status dos containers
    logs [service]          Ver logs (todos ou específico)
    memory                  Ver uso de memória
    monitor                 Monitor de memória em tempo real
    health                  Health check de todos os serviços
    
  Dados:
    data-count              Contagem de registros
    clean-data              Limpar dados de teste
    test [batch] [num] [delay]  Teste de capacidade

EXEMPLOS:

  ./utils.sh start
  ./utils.sh logs airflow_webserver
  ./utils.sh memory
  ./utils.sh test 1000 50 1
  ./utils.sh health

EOF
}

# Main
case "${1:-}" in
    start)       cmd_start ;;
    stop)        cmd_stop ;;
    restart)     cmd_restart ;;
    status)      cmd_status ;;
    logs)        cmd_logs "${2:-}" ;;
    memory)      cmd_memory ;;
    monitor)     cmd_monitor ;;
    health)      cmd_health ;;
    data-count)  cmd_data_count ;;
    clean-data)  cmd_clean_data ;;
    reset)       cmd_reset ;;
    test)        cmd_test "${2:-1000}" "${3:-10}" "${4:-1}" ;;
    help|--help|-h) cmd_help ;;
    *)
        print_error "Comando inválido: ${1:-}"
        echo ""
        cmd_help
        exit 1
        ;;
esac
