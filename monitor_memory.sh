#!/bin/bash
# Monitor de Memória em Tempo Real
# Monitora o uso de RAM dos containers durante testes de carga

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║         📊 MONITOR DE MEMÓRIA - TEMPO REAL                       ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Pressione Ctrl+C para parar"
echo ""

# Arquivo de log
LOG_FILE="memory_monitor_$(date +%Y%m%d_%H%M%S).log"
echo "📝 Log salvo em: $LOG_FILE"
echo ""

# Cabeçalho
echo "Timestamp,Total(MB),Airflow_Web,Airflow_Sched,Dashboard,Postgres,Spark_Master,Spark_Worker,MinIO" | tee -a "$LOG_FILE"

# Loop de monitoramento
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Coletar uso de memória
    STATS=$(docker stats --no-stream --format "{{.Name}} {{.MemUsage}}" $(docker-compose ps -q 2>/dev/null) 2>/dev/null)
    
    # Extrair valores (em MB)
    AIRFLOW_WEB=$(echo "$STATS" | grep "de_airflow_webserver" | awk '{print $2}' | sed 's/MiB//')
    AIRFLOW_SCHED=$(echo "$STATS" | grep "de_airflow_scheduler" | awk '{print $2}' | sed 's/MiB//')
    DASHBOARD=$(echo "$STATS" | grep "de_data_dashboard" | awk '{print $2}' | sed 's/MiB//')
    POSTGRES=$(echo "$STATS" | grep "de_postgres" | awk '{print $2}' | sed 's/MiB//')
    SPARK_MASTER=$(echo "$STATS" | grep "de_spark_master" | awk '{print $2}' | sed 's/MiB//')
    SPARK_WORKER=$(echo "$STATS" | grep "de_spark_worker" | awk '{print $2}' | sed 's/KiB//' | awk '{print $1/1024}')
    MINIO=$(echo "$STATS" | grep "de_minio" | awk '{print $2}' | sed 's/MiB//')
    
    # Calcular total
    TOTAL=$(echo "$AIRFLOW_WEB + $AIRFLOW_SCHED + $DASHBOARD + $POSTGRES + $SPARK_MASTER + $SPARK_WORKER + $MINIO" | bc 2>/dev/null)
    
    # Exibir
    if [ ! -z "$TOTAL" ]; then
        printf "%s | TOTAL: %6.0f MB | Airflow: %6.0f MB | Postgres: %5.0f MB | Spark: %5.0f MB | Dashboard: %5.0f MB | MinIO: %5.0f MB\n" \
            "$TIMESTAMP" "$TOTAL" \
            "$(echo "$AIRFLOW_WEB + $AIRFLOW_SCHED" | bc)" \
            "$POSTGRES" \
            "$(echo "$SPARK_MASTER + $SPARK_WORKER" | bc)" \
            "$DASHBOARD" \
            "$MINIO"
        
        # Salvar no log
        echo "$TIMESTAMP,$TOTAL,$AIRFLOW_WEB,$AIRFLOW_SCHED,$DASHBOARD,$POSTGRES,$SPARK_MASTER,$SPARK_WORKER,$MINIO" >> "$LOG_FILE"
        
        # Alerta se ultrapassar 900MB
        if (( $(echo "$TOTAL > 900" | bc -l) )); then
            echo "⚠️  ALERTA: Uso de memória acima de 900 MB!"
        fi
    fi
    
    sleep 5
done
