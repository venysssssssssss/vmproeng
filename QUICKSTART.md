# 🚀 Quick Start - Projeto de Engenharia de Dados

## 📝 Ordem de Execução

### 1️⃣ Primeiro Acesso (Configuração Inicial)

```bash
# Já temos Python 3.11.9 via pyenv ✓
# Já temos Poetry configurado ✓

# Verificar ambiente
poetry env info
poetry shell  # Ativar ambiente virtual
```

### 2️⃣ Iniciar Serviços Docker

```bash
# Opção A: Usar script automatizado (RECOMENDADO)
./start.sh

# Opção B: Docker Compose manual
docker-compose up -d
```

**Aguarde 60-90 segundos** para todos os serviços iniciarem.

### 3️⃣ Verificar Saúde do Sistema

```bash
# Executar teste completo
./test-project.sh

# OU verificação rápida
./health-check.sh

# OU manual
docker-compose ps
docker stats --no-stream
```

### 4️⃣ Acessar Interfaces Web

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| **Airflow** | http://localhost:8080 | admin / admin |
| **Spark** | http://localhost:8081 | - |
| **MinIO** | http://localhost:9001 | minioadmin / minioadmin |
| **Metabase** | http://localhost:3000 | Configurar no 1º acesso |

### 5️⃣ Executar Pipeline de Dados

#### Via Airflow UI (Recomendado):
1. Acesse http://localhost:8080
2. Login: `admin` / `admin`
3. Ative a DAG `ecommerce_etl_pipeline` (toggle à esquerda)
4. Clique no botão ▶️ "Trigger DAG"
5. Acompanhe em "Graph View"

#### Via Linha de Comando:
```bash
# Pipeline completo de ETL
docker exec de_airflow_webserver airflow dags trigger ecommerce_etl_pipeline

# Pipeline de ingestão de API
docker exec de_airflow_webserver airflow dags trigger api_data_ingestion

# Verificação de qualidade
docker exec de_airflow_webserver airflow dags trigger data_quality_check

# Ou use o Makefile
make trigger-etl
make trigger-ingestion
make trigger-quality
```

### 6️⃣ Verificar Resultados

```bash
# Conectar ao PostgreSQL
docker exec -it de_postgres psql -U postgres -d datawarehouse

# Verificar dados carregados
SELECT COUNT(*) FROM raw.sales_transactions;
SELECT COUNT(*) FROM processed.fact_sales;
SELECT * FROM analytics.daily_sales_summary ORDER BY summary_date DESC LIMIT 5;

# Sair
\q
```

### 7️⃣ Parar o Projeto

```bash
# Parar serviços (mantém dados)
./stop.sh

# Parar e limpar tudo
./stop.sh --clean
```

## 📊 Comandos Úteis

### Make Commands (Atalhos)
```bash
make help              # Ver todos os comandos
make start             # Iniciar serviços
make stop              # Parar serviços
make logs              # Ver logs de todos
make logs-airflow      # Ver logs do Airflow
make status            # Status dos containers
make stats             # Uso de recursos
make trigger-etl       # Executar pipeline ETL
make backup-db         # Backup do banco
```

### Docker Commands
```bash
# Ver logs em tempo real
docker-compose logs -f

# Logs de serviço específico
docker-compose logs -f airflow-scheduler

# Status dos containers
docker-compose ps

# Uso de recursos
docker stats

# Reiniciar serviço
docker-compose restart airflow-webserver
```

### Airflow Commands
```bash
# Listar DAGs
docker exec de_airflow_webserver airflow dags list

# Ver status de uma DAG
docker exec de_airflow_webserver airflow dags list-runs -d ecommerce_etl_pipeline

# Executar task específica (para debug)
docker exec de_airflow_webserver airflow tasks test ecommerce_etl_pipeline generate_sales_data 2024-01-01
```

### PostgreSQL Commands
```bash
# Conectar ao banco
docker exec -it de_postgres psql -U postgres -d datawarehouse

# Query rápida
docker exec de_postgres psql -U postgres -d datawarehouse -c "SELECT COUNT(*) FROM raw.sales_transactions;"

# Backup manual
docker exec de_postgres pg_dump -U postgres datawarehouse > backup.sql
```

## 🐛 Troubleshooting Rápido

### Container não inicia
```bash
docker-compose logs [nome-do-container]
docker-compose restart [nome-do-container]
docker-compose up -d --force-recreate [nome-do-container]
```

### DAGs não aparecem no Airflow
```bash
# Verificar erros de import
docker exec de_airflow_webserver airflow dags list-import-errors

# Verificar logs do scheduler
docker-compose logs airflow-scheduler | grep -i error

# Reiniciar scheduler
docker-compose restart airflow-scheduler
```

### Erro de memória
```bash
# Ver uso atual
docker stats

# Parar serviços não essenciais
docker-compose stop metabase
docker-compose stop spark-worker
```

### Banco não conecta
```bash
# Testar conexão
docker exec de_postgres pg_isready -U postgres

# Ver logs
docker-compose logs postgres

# Reiniciar
docker-compose restart postgres
```

## ✅ Checklist de Verificação

- [ ] Python 3.11.9 instalado (pyenv)
- [ ] Poetry configurado
- [ ] Ambiente virtual ativo (`poetry shell`)
- [ ] Docker rodando
- [ ] 8 containers ativos
- [ ] Airflow acessível (localhost:8080)
- [ ] PostgreSQL aceitando conexões
- [ ] DAGs carregadas no Airflow
- [ ] Pipeline executado com sucesso
- [ ] Dados nas tabelas

## 📚 Documentação Completa

- **Guia Detalhado**: [RUN_PROJECT.md](RUN_PROJECT.md)
- **Arquitetura**: [ARCHITECTURE.md](ARCHITECTURE.md)
- **Uso**: [USAGE_GUIDE.md](USAGE_GUIDE.md)
- **Setup Python**: [SETUP_PYTHON.md](SETUP_PYTHON.md)
- **Roadmap**: [ROADMAP.md](ROADMAP.md)

## 🎯 Fluxo de Dados

```
API/Files → RAW → STAGING → PROCESSED (Star Schema) → ANALYTICS → BI
              ↓      ↓           ↓                        ↓
            MinIO  Clean    Dimensions/Facts        Aggregations
```

## 📈 Próximos Passos

1. ✅ Rodar o projeto com `./start.sh`
2. ✅ Executar pipeline com `make trigger-etl`
3. ✅ Verificar dados no PostgreSQL
4. 📊 Configurar dashboards no Metabase
5. 🔧 Personalizar DAGs para seus dados
6. 🚀 Adicionar novas fontes de dados

---

**Dica**: Sempre use `./test-project.sh` para validação completa!
