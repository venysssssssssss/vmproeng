# 🎉 Status do Projeto - Data Engineering Pipeline

## ✅ TODOS OS SERVIÇOS FUNCIONANDO!

Data: 03/10/2025  
Status: **OPERACIONAL** ✅

---

## 📊 Serviços Disponíveis

### 1. **Dashboard Streamlit** 
- **URL:** http://localhost:8501
- **Funcionalidades:**
  - 📈 Visão geral do pipeline com métricas em tempo real
  - 🎯 Controle de DAGs do Airflow
  - 📊 Visualização das 4 camadas de dados (Raw, Staging, Processed, Analytics)
  - 🎲 Gerador de dados com Faker
- **Status:** ✅ Funcionando (HTTP 200)

### 2. **Apache Airflow**
- **URL:** http://localhost:8080
- **Credenciais:** 
  - User: `admin`
  - Password: `admin`
- **Funcionalidades:**
  - Orquestração de workflows
  - 4 DAGs disponíveis:
    - `ecommerce_etl_pipeline` - Pipeline ETL principal
    - `api_ingestion_dag` - Ingestão de APIs
    - `data_quality_dag` - Verificação de qualidade
    - `minio_datalake_dag` - Integração com MinIO
- **Status:** ✅ Funcionando (HTTP 302 redirect, Metadatabase: healthy, Scheduler: healthy)

### 3. **Apache Spark**
- **Master UI:** http://localhost:8081
- **Master URL:** spark://spark-master:7077
- **Configuração:**
  - 1 Master node
  - 1 Worker node
  - Worker Memory: 96MB
  - Worker Cores: 1
- **Status:** ✅ Funcionando (HTTP 200)

### 4. **MinIO (Object Storage)**
- **Console:** http://localhost:9001
- **API:** http://localhost:9000
- **Credenciais:**
  - Access Key: `minioadmin`
  - Secret Key: `minioadmin`
- **Funcionalidades:**
  - S3-compatible object storage
  - Datalake storage
- **Status:** ✅ Funcionando (HTTP 200, Healthy)

### 5. **PostgreSQL**
- **Host:** localhost
- **Port:** 5432
- **Databases:**
  - `datawarehouse` - Data Warehouse principal
  - `airflow` - Metadados do Airflow
  - `metabase` - Metadados do Metabase (opcional)
- **Credenciais:**
  - User: `postgres`
  - Password: `postgres`
- **Schemas:**
  - `raw` - Dados brutos
  - `staging` - Dados em staging
  - `processed` - Dados processados
  - `analytics` - Dados analíticos
- **Status:** ✅ Funcionando

---

## 💾 Uso de Memória

| Container | Uso Atual | Limite | Percentual |
|-----------|-----------|--------|------------|
| Airflow Webserver | ~390 MB | 512 MB | 76% |
| Airflow Scheduler | ~174 MB | 300 MB | 58% |
| Spark Master | ~123 MB | 128 MB | 96% |
| Dashboard | ~87 MB | 128 MB | 68% |
| MinIO | ~92 MB | 96 MB | 96% |
| PostgreSQL | ~22 MB | 128 MB | 17% |
| Spark Worker | ~1 MB | 128 MB | 1% |
| **TOTAL** | **~890 MB** | **1420 MB** | **63%** |

> ⚠️ **Nota:** Para funcionar corretamente, o projeto usa aproximadamente **890 MB de RAM**. 
> Embora seja possível reduzir para 900 MB, isso pode causar instabilidade no Airflow.

---

## 🏗️ Arquitetura de Dados (4 Camadas)

```
┌─────────────────────────────────────────────────────────────┐
│                    LAYER 4: ANALYTICS                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ • sales_summary (agregações de vendas)               │  │
│  │ • Métricas de negócio                                │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │
┌─────────────────────────────────────────────────────────────┐
│                   LAYER 3: PROCESSED                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ • dim_customer (dimensão clientes)                   │  │
│  │ • dim_product (dimensão produtos)                    │  │
│  │ • dim_date (dimensão tempo)                          │  │
│  │ • fact_sales (fato vendas)                           │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │
┌─────────────────────────────────────────────────────────────┐
│                    LAYER 2: STAGING                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ • customers_staging (validado)                       │  │
│  │ • products_staging (validado)                        │  │
│  │ • transactions_staging (validado)                    │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │
┌─────────────────────────────────────────────────────────────┐
│                     LAYER 1: RAW                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ • customers_raw (dados brutos)                       │  │
│  │ • products_raw (dados brutos)                        │  │
│  │ • transactions_raw (dados brutos)                    │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Como Usar

### 1. Iniciar o Projeto
```bash
cd /home/synev1/dev/vmpro1
docker-compose up -d
```

### 2. Verificar Status
```bash
docker-compose ps
```

### 3. Acessar Dashboard
Abra o navegador em: http://localhost:8501

### 4. Gerar Dados de Teste
1. Acesse o Dashboard (http://localhost:8501)
2. Vá na aba "🎲 Gerador Faker"
3. Configure os parâmetros desejados
4. Clique em "🚀 Gerar Dados"

### 5. Executar DAG no Airflow
1. Acesse http://localhost:8080
2. Login: `admin` / `admin`
3. Ative a DAG desejada
4. Clique em "Trigger DAG"

### 6. Monitorar Execução
- **Dashboard:** Aba "📊 DAGs em Andamento"
- **Airflow UI:** http://localhost:8080
- **Spark UI:** http://localhost:8081

### 7. Parar o Projeto
```bash
docker-compose down
```

---

## 🔧 Resolução de Problemas

### Porta 5432 já em uso
```bash
docker stop verihfy-postgres
docker-compose up -d
```

### Airflow não inicia
```bash
# Verificar logs
docker logs de_airflow_webserver --tail 50
docker logs de_airflow_scheduler --tail 50

# Reiniciar
docker restart de_airflow_webserver de_airflow_scheduler
```

### Dashboard com erro
```bash
# Verificar logs
docker logs de_data_dashboard --tail 50

# Reiniciar
docker restart de_data_dashboard
```

### Limpar e reiniciar tudo
```bash
docker-compose down -v  # Remove volumes também
docker-compose up -d
```

---

## 📝 DAGs Disponíveis

### 1. `ecommerce_etl_pipeline`
- **Descrição:** Pipeline ETL completo para e-commerce
- **Schedule:** Diário
- **Tarefas:**
  1. Gerar dados de exemplo
  2. Carregar na camada RAW
  3. Transformar e limpar
  4. Carregar dimensões (customer, product, date)
  5. Carregar fato (sales)
  6. Criar agregações analíticas

### 2. `api_ingestion_dag`
- **Descrição:** Ingestão de dados de APIs externas
- **Schedule:** A cada 6 horas

### 3. `data_quality_dag`
- **Descrição:** Verificação de qualidade dos dados
- **Schedule:** Diário

### 4. `minio_datalake_dag`
- **Descrição:** Integração com MinIO para datalake
- **Schedule:** Manual

---

## 📦 Pacotes Python Instalados

- `faker` - Geração de dados fake
- `minio` - Cliente MinIO/S3
- `psycopg2-binary` - Driver PostgreSQL
- `streamlit` - Framework web dashboard
- `pandas` - Manipulação de dados
- `plotly` - Visualizações interativas
- `requests` - Cliente HTTP

---

## ✨ Funcionalidades do Dashboard

### Aba 1: Visão Geral
- Total de registros por camada
- Receita total
- Gráfico de vendas por categoria
- Gráfico de métodos de pagamento

### Aba 2: DAGs em Andamento
- Status de todas as DAGs
- Última execução
- Próxima execução agendada
- Botões para trigger manual

### Aba 3: Camadas de Dados
- Visualização de dados de cada camada
- Filtros e busca
- Export para CSV

### Aba 4: Gerador Faker
- Configuração de quantidade de registros
- Seleção de categorias e métodos de pagamento
- Período de datas
- Geração automática com progresso

---

## 🎯 Próximos Passos

1. ✅ **Projeto funcionando** - Todos os serviços operacionais
2. ✅ **Dashboard integrado** - Interface web completa
3. ✅ **Gerador Faker** - Criação de dados de teste
4. 🔄 **Otimização de memória** - Reduzir para 900MB (opcional)
5. 📊 **Adicionar Metabase** - BI Tool para visualizações
6. 🔐 **Segurança** - Adicionar autenticação robusta
7. 📈 **Monitoramento** - Prometheus + Grafana

---

**Desenvolvido com ❤️ usando Docker, Airflow, Spark, PostgreSQL, MinIO e Streamlit**
