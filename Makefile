# Makefile para Data Engineering Project

.PHONY: help start stop restart logs clean install test backup restore

# Variáveis
DOCKER_COMPOSE = docker-compose
AIRFLOW_CONTAINER = airflow-webserver
POSTGRES_CONTAINER = postgres

help: ## Mostra esta mensagem de ajuda
	@echo "Data Engineering Project - Comandos Disponíveis:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

start: ## Inicia todos os serviços
	@echo "🚀 Iniciando serviços..."
	@chmod +x start.sh
	@./start.sh

stop: ## Para todos os serviços
	@echo "🛑 Parando serviços..."
	@$(DOCKER_COMPOSE) down

stop-clean: ## Para todos os serviços e remove volumes
	@echo "🧹 Parando serviços e limpando dados..."
	@chmod +x stop.sh
	@./stop.sh --clean

restart: ## Reinicia todos os serviços
	@echo "🔄 Reiniciando serviços..."
	@$(DOCKER_COMPOSE) restart

logs: ## Mostra logs de todos os serviços
	@$(DOCKER_COMPOSE) logs -f

logs-airflow: ## Mostra logs do Airflow
	@$(DOCKER_COMPOSE) logs -f airflow-webserver airflow-scheduler

logs-spark: ## Mostra logs do Spark
	@$(DOCKER_COMPOSE) logs -f spark-master spark-worker

logs-postgres: ## Mostra logs do PostgreSQL
	@$(DOCKER_COMPOSE) logs -f postgres

status: ## Mostra status dos containers
	@$(DOCKER_COMPOSE) ps

stats: ## Mostra uso de recursos
	@docker stats --no-stream

shell-airflow: ## Abre shell no container Airflow
	@$(DOCKER_COMPOSE) exec $(AIRFLOW_CONTAINER) bash

shell-postgres: ## Abre shell no PostgreSQL
	@$(DOCKER_COMPOSE) exec $(POSTGRES_CONTAINER) psql -U postgres -d datawarehouse

shell-spark: ## Abre shell no Spark Master
	@$(DOCKER_COMPOSE) exec spark-master bash

trigger-etl: ## Executa pipeline ETL principal
	@echo "▶️  Executando pipeline ETL..."
	@$(DOCKER_COMPOSE) exec $(AIRFLOW_CONTAINER) airflow dags trigger ecommerce_etl_pipeline

trigger-ingestion: ## Executa pipeline de ingestão de API
	@echo "▶️  Executando ingestão de dados..."
	@$(DOCKER_COMPOSE) exec $(AIRFLOW_CONTAINER) airflow dags trigger api_ingestion

trigger-quality: ## Executa verificação de qualidade
	@echo "▶️  Executando verificação de qualidade..."
	@$(DOCKER_COMPOSE) exec $(AIRFLOW_CONTAINER) airflow dags trigger data_quality_check

list-dags: ## Lista todas as DAGs
	@$(DOCKER_COMPOSE) exec $(AIRFLOW_CONTAINER) airflow dags list

backup-db: ## Faz backup do banco de dados
	@echo "💾 Criando backup do banco de dados..."
	@mkdir -p backups
	@$(DOCKER_COMPOSE) exec -T $(POSTGRES_CONTAINER) pg_dump -U postgres datawarehouse > backups/datawarehouse_$$(date +%Y%m%d_%H%M%S).sql
	@echo "✅ Backup criado em backups/"

restore-db: ## Restaura backup do banco de dados (uso: make restore-db FILE=backup.sql)
	@echo "📥 Restaurando backup do banco de dados..."
	@$(DOCKER_COMPOSE) exec -T $(POSTGRES_CONTAINER) psql -U postgres datawarehouse < $(FILE)
	@echo "✅ Backup restaurado"

clean-data: ## Limpa dados temporários
	@echo "🧹 Limpando dados temporários..."
	@rm -rf data/raw/*
	@rm -rf data/staging/*
	@rm -rf data/processed/*
	@rm -rf airflow/logs/*
	@echo "✅ Dados temporários limpos"

install: ## Instala dependências Python localmente
	@echo "📦 Instalando dependências..."
	@pip install -r requirements.txt

test-connection: ## Testa conexão com banco de dados
	@echo "🔍 Testando conexão com PostgreSQL..."
	@$(DOCKER_COMPOSE) exec $(POSTGRES_CONTAINER) psql -U postgres -d datawarehouse -c "SELECT version();"

create-user: ## Cria usuário admin no Airflow
	@echo "👤 Criando usuário admin..."
	@$(DOCKER_COMPOSE) exec $(AIRFLOW_CONTAINER) airflow users create \
		--username admin \
		--password admin \
		--firstname Admin \
		--lastname User \
		--role Admin \
		--email admin@example.com

query: ## Executa query SQL (uso: make query SQL="SELECT * FROM table")
	@$(DOCKER_COMPOSE) exec $(POSTGRES_CONTAINER) psql -U postgres -d datawarehouse -c "$(SQL)"

monitor: ## Abre dashboard de monitoramento
	@echo "📊 Abrindo URLs de monitoramento..."
	@echo "Airflow:    http://localhost:8080"
	@echo "Spark:      http://localhost:8081"
	@echo "MinIO:      http://localhost:9001"
	@echo "Metabase:   http://localhost:3000"

build: ## Constrói as imagens Docker
	@$(DOCKER_COMPOSE) build

pull: ## Baixa as imagens Docker
	@$(DOCKER_COMPOSE) pull

update: ## Atualiza o projeto (pull + restart)
	@echo "🔄 Atualizando projeto..."
	@git pull
	@$(DOCKER_COMPOSE) pull
	@$(DOCKER_COMPOSE) up -d
	@echo "✅ Projeto atualizado"

validate-dags: ## Valida sintaxe das DAGs
	@echo "✅ Validando DAGs..."
	@$(DOCKER_COMPOSE) exec $(AIRFLOW_CONTAINER) python -m py_compile /opt/airflow/dags/*.py
	@echo "✅ DAGs validadas com sucesso"
