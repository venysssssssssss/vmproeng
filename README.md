# 🚀 Data Engineering Pipeline

Pipeline completo de engenharia de dados com Airflow, Spark, PostgreSQL, MinIO e Streamlit.

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Arquitetura](#-arquitetura)
- [Início Rápido](#-início-rápido)
- [Serviços](#-serviços-disponíveis)
- [Uso](#-uso)
- [Arquitetura de Dados](#-arquitetura-de-dados)
- [Testes de Capacidade](#-testes-de-capacidade)
- [Gerenciamento](#-gerenciamento)
- [Troubleshooting](#-troubleshooting)

---

## 🎯 Visão Geral

Pipeline de dados moderno com arquitetura de **4 camadas** (Raw → Staging → Processed → Analytics).

### Características

- ✅ Orquestração com Apache Airflow 2.8.0
- ✅ Processamento distribuído com Spark 3.4.1
- ✅ Data Warehouse PostgreSQL 15
- ✅ Object Storage MinIO (S3-compatible)
- ✅ Dashboard Streamlit para monitoramento
- ✅ Gerador de dados com Faker
- ✅ 100% containerizado com Docker

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│              STREAMLIT DASHBOARD                        │
│         Monitoramento + Gerador de Dados                │
└─────────────────────────────────────────────────────────┘
                       │
     ┌─────────────────┼──────────────────┐
     │                 │                  │
┌────▼────┐    ┌───────▼──────┐   ┌──────▼─────┐
│ AIRFLOW │    │    SPARK     │   │   MinIO    │
└────┬────┘    └──────────────┘   └────────────┘
     │
┌────▼────────────────────────────────────────────┐
│              POSTGRESQL 15                      │
│  RAW → STAGING → PROCESSED → ANALYTICS          │
└─────────────────────────────────────────────────┘
```

### Componentes

| Componente | Porta | Memória | Descrição |
|------------|-------|---------|-----------|
| Airflow Web | 8080 | 512 MB | Interface web |
| Airflow Scheduler | - | 300 MB | Agendador |
| Spark Master | 8081 | 128 MB | Coordenador |
| Spark Worker | - | 128 MB | Executor |
| PostgreSQL | 5432 | 128 MB | Data Warehouse |
| MinIO | 9001 | 96 MB | Object Storage |
| Dashboard | 8501 | 128 MB | Monitoramento |

**Total:** ~1.4 GB | **Otimizado:** 900 MB (sem Dashboard)

---

## 🚀 Início Rápido

```bash
# 1. Iniciar containers
docker-compose up -d

# 2. Aguardar inicialização
sleep 90

# 3. Verificar status
docker-compose ps

# 4. Acessar Dashboard
# http://localhost:8501
```

### Portas dos Serviços

- **Dashboard:** http://localhost:8501
- **Airflow:** http://localhost:8080 (admin/admin)
- **Spark UI:** http://localhost:8081
- **MinIO:** http://localhost:9001 (minioadmin/minioadmin)
- **PostgreSQL:** localhost:5432 (postgres/postgres)

---

## 🌐 Serviços Disponíveis

### 1. Dashboard Streamlit

**URL:** http://localhost:8501

- 📊 Métricas em tempo real
- 🎯 Controle de DAGs
- 📈 Exploração de dados (4 camadas)
- 🎲 Gerador de dados Faker

### 2. Apache Airflow

**URL:** http://localhost:8080 | **Login:** admin/admin

**DAGs:**
- `ecommerce_etl_pipeline` - ETL completo
- `api_ingestion_dag` - Ingestão de APIs
- `data_quality_dag` - Qualidade de dados
- `minio_datalake_dag` - Integração MinIO

### 3. PostgreSQL

**Host:** localhost:5432 | **User:** postgres/postgres

**Schemas:**
- `raw` - Dados brutos
- `staging` - Dados validados
- `processed` - Modelo dimensional
- `analytics` - Agregações

---

## 💼 Uso

### Gerar Dados de Teste

**Via Dashboard:**
1. Acesse http://localhost:8501
2. Aba "🎲 Gerador Faker"
3. Configure e clique em "Gerar Dados"

**Via Script:**
```bash
# python test_capacity.py <batch_size> <num_batches> <delay>
.venv/bin/python test_capacity.py 1000 50 1
```

### Executar DAG

**Via Airflow:**
1. http://localhost:8080
2. Ative a DAG
3. Clique em "Play" para executar

### Consultar Dados

```bash
PGPASSWORD=postgres psql -h localhost -U postgres -d datawarehouse

# Ver contagem
SELECT 'Raw' as layer, COUNT(*) FROM raw.transactions_raw
UNION ALL
SELECT 'Staging', COUNT(*) FROM staging.transactions_staging
UNION ALL
SELECT 'Processed', COUNT(*) FROM processed.fact_sales;
```

---

## 📂 Arquitetura de Dados

### 4 Camadas

**1. RAW** - Dados brutos (transactions_raw, customers_raw, products_raw)  
**2. STAGING** - Dados limpos e validados  
**3. PROCESSED** - Star Schema (dim_customer, dim_product, dim_date, fact_sales)  
**4. ANALYTICS** - Agregações (sales_summary, customer_metrics)

---

## 🧪 Testes de Capacidade

### Resultados (900 MB RAM)

| Registros | Tempo | Taxa | Memória PostgreSQL |
|-----------|-------|------|-------------------|
| 10,000 | 26s | 389/s | 27 MB |
| 50,000 | 58s | 867/s | 36 MB |
| 100,000 | ~2min | ~850/s | ~50 MB |

### Executar Testes

```bash
# 10K registros
.venv/bin/python test_capacity.py 1000 10 1

# 50K registros
.venv/bin/python test_capacity.py 2000 25 1

# Monitorar memória
./monitor_memory.sh
```

---

## 🔧 Gerenciamento

```bash
# Iniciar
docker-compose up -d

# Parar
docker-compose down

# Parar + limpar volumes
docker-compose down -v

# Reiniciar serviço
docker restart de_airflow_webserver

# Ver logs
docker logs de_airflow_webserver -f

# Ver uso de memória
docker stats --no-stream
```

---

## 🐛 Troubleshooting

### Porta 5432 em uso
```bash
docker ps -a | grep 5432
docker stop <container_name>
```

### Airflow não inicia
```bash
docker logs de_airflow_webserver --tail 50
docker exec -u root de_airflow_webserver chmod -R 777 /opt/airflow/logs
docker restart de_airflow_webserver de_airflow_scheduler
```

### Memória insuficiente
```bash
# Desabilitar Dashboard (economiza 128MB)
docker-compose stop data-dashboard
```

### Reset completo
```bash
docker-compose down -v
docker-compose up -d
```

---

## 📁 Estrutura

```
vmpro1/
├── airflow/dags/          # DAGs Airflow
├── spark/jobs/            # Jobs Spark
├── sql/init/              # Scripts SQL
├── monitoring/            # Dashboard Streamlit
├── docker-compose.yml     # Configuração
├── test_capacity.py       # Testes
└── README.md              # Documentação
```

---

## 🔒 Credenciais

| Serviço | Usuário | Senha |
|---------|---------|-------|
| Airflow | admin | admin |
| PostgreSQL | postgres | postgres |
| MinIO | minioadmin | minioadmin |

⚠️ **Altere em produção!**

---

**Desenvolvido com ❤️ usando Docker, Airflow, Spark, PostgreSQL, MinIO e Streamlit**
