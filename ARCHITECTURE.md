# Data Engineering Project - Architecture Documentation

## 📐 Arquitetura Geral

```
┌─────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                              │
│                  (APIs, Files, Databases)                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    INGESTION LAYER                               │
│                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   Airflow    │    │    Python    │    │    Custom    │      │
│  │    DAGs      │───▶│   Scripts    │───▶│  Connectors  │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     STORAGE LAYER                                │
│                                                                   │
│  ┌──────────────────────┐         ┌──────────────────────┐     │
│  │   MinIO (S3)         │         │   PostgreSQL         │     │
│  │   - Raw Data         │         │   - Raw Schema       │     │
│  │   - Staging          │         │   - Staging Schema   │     │
│  │   - Processed        │         │   - Processed Schema │     │
│  │   - Backups          │         │   - Analytics Schema │     │
│  └──────────────────────┘         └──────────────────────┘     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   PROCESSING LAYER                               │
│                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │ Apache Spark │    │    Python    │    │     SQL      │      │
│  │  - Master    │───▶│   PySpark    │───▶│ Transforms   │      │
│  │  - Worker    │    │   Scripts    │    │              │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                 ORCHESTRATION LAYER                              │
│                                                                   │
│  ┌──────────────────────────────────────────────────────┐       │
│  │              Apache Airflow                           │       │
│  │                                                        │       │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐           │       │
│  │  │ Scheduler│  │ Webserver│  │ Executor │           │       │
│  │  └──────────┘  └──────────┘  └──────────┘           │       │
│  │                                                        │       │
│  │  ┌──────────────────────────────────────────┐        │       │
│  │  │           DAG Workflows                  │        │       │
│  │  │  - ETL Pipelines                         │        │       │
│  │  │  - Data Quality Checks                   │        │       │
│  │  │  - Data Ingestion                        │        │       │
│  │  │  - Analytics Aggregations                │        │       │
│  │  └──────────────────────────────────────────┘        │       │
│  └──────────────────────────────────────────────────────┘       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                              │
│                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   Metabase   │    │   Custom     │    │     API      │      │
│  │  Dashboards  │    │   Reports    │    │  (Future)    │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

## 🗂️ Data Flow Architecture

### 1. Raw Layer (Bronze)
- **Propósito**: Armazenar dados brutos sem transformação
- **Formato**: CSV, JSON, Parquet
- **Retenção**: 90 dias
- **Localização**: 
  - PostgreSQL: `raw.*` schema
  - MinIO: `raw-data` bucket

### 2. Staging Layer (Silver)
- **Propósito**: Dados limpos e validados
- **Transformações**: Deduplicação, limpeza, validação
- **Formato**: Parquet, tabelas PostgreSQL
- **Localização**:
  - PostgreSQL: `staging.*` schema
  - MinIO: `processed-data` bucket

### 3. Processed Layer (Gold)
- **Propósito**: Modelo dimensional (Star Schema)
- **Componentes**:
  - Dimension tables (SCD Type 2)
  - Fact tables
  - Date dimension
- **Localização**: PostgreSQL `processed.*` schema

### 4. Analytics Layer
- **Propósito**: Agregações e métricas de negócio
- **Componentes**:
  - Daily summaries
  - KPIs
  - Pre-computed metrics
- **Localização**: PostgreSQL `analytics.*` schema

## 🔄 Pipeline Workflow

### ETL Pipeline Flow

```
┌─────────────┐
│   Extract   │  1. Gerar/coletar dados de fontes
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Raw Load   │  2. Carregar para camada raw (sem transformação)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Transform   │  3. Limpar, validar e transformar
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Staging    │  4. Carregar para staging
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Dimensions  │  5. Atualizar tabelas dimensão (SCD)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Facts    │  6. Carregar tabela fato
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Analytics   │  7. Criar agregações analíticas
└─────────────┘
```

## 🏗️ Dimensional Model (Star Schema)

```
                    ┌─────────────────┐
                    │   dim_date      │
                    ├─────────────────┤
                    │ date_key (PK)   │
                    │ full_date       │
                    │ year            │
                    │ quarter         │
                    │ month           │
                    │ week            │
                    │ day_of_week     │
                    │ is_weekend      │
                    └────────┬────────┘
                             │
                             │
┌─────────────────┐          │          ┌─────────────────┐
│ dim_customers   │          │          │  dim_products   │
├─────────────────┤          │          ├─────────────────┤
│ customer_key(PK)│          │          │ product_key(PK) │
│ customer_id     │          │          │ product_id      │
│ customer_name   │          │          │ product_name    │
│ email           │          │          │ category        │
│ city            │          │          │ created_at      │
│ state           │          │          │ updated_at      │
│ country         │          │          └────────┬────────┘
│ is_active       │          │                   │
└────────┬────────┘          │                   │
         │                   │                   │
         │                   │                   │
         │         ┌─────────▼──────────┐        │
         │         │    fact_sales      │        │
         │         ├────────────────────┤        │
         └────────▶│ sale_key (PK)      │◀───────┘
                   │ transaction_id     │
                   │ date_key (FK)      │
                   │ customer_key (FK)  │
                   │ product_key (FK)   │
                   │ quantity           │
                   │ unit_price         │
                   │ total_amount       │
                   │ payment_method     │
                   │ status             │
                   └────────────────────┘
```

## 🔧 Component Specifications

### Apache Airflow
- **Executor**: LocalExecutor (otimizado para baixa memória)
- **Database**: PostgreSQL
- **Message Broker**: Redis
- **Workers**: 2
- **Parallelism**: 4 DAGs simultâneas
- **Memory**: ~500MB

### Apache Spark
- **Mode**: Standalone
- **Master**: 1 node
- **Workers**: 1 node
- **Driver Memory**: 256MB
- **Executor Memory**: 256MB
- **Cores**: 1 per executor
- **Shuffle Partitions**: 2

### PostgreSQL
- **Version**: 15 Alpine
- **Schemas**: raw, staging, processed, analytics
- **Shared Buffers**: 64MB
- **Max Connections**: 50
- **Work Memory**: 4MB

### MinIO
- **Buckets**: raw-data, processed-data, analytics, backups
- **Access**: S3-compatible API
- **Memory**: ~256MB

### Metabase
- **Database**: PostgreSQL
- **Memory**: ~512MB
- **Features**: Dashboards, queries, visualizações

## 📊 Data Quality Framework

### Quality Checks
1. **Schema Validation**
   - Tipos de dados corretos
   - Campos obrigatórios presentes
   - Constraints respeitados

2. **Data Validation**
   - Valores nulos
   - Duplicatas
   - Valores negativos
   - Ranges válidos

3. **Business Rules**
   - Consistência de cálculos
   - Regras de negócio
   - Relacionamentos válidos

4. **Freshness**
   - Data de última atualização
   - Latência de dados
   - SLAs de pipeline

## 🔐 Security & Governance

### Access Control
- Credenciais isoladas por serviço
- Network isolation via Docker network
- Secrets management via environment variables

### Data Privacy
- PII data masking (futura implementação)
- LGPD/GDPR compliance ready
- Audit logs

### Backup Strategy
- PostgreSQL: Daily dumps
- MinIO: Versioning enabled
- Retention: 30 days

## 📈 Scalability Considerations

### Horizontal Scaling
- Adicionar Spark workers conforme necessário
- Airflow CeleryExecutor para paralelização
- PostgreSQL read replicas

### Vertical Scaling
- Aumentar recursos de containers
- Otimizar queries SQL
- Particionamento de tabelas

### Future Enhancements
- Kubernetes deployment
- Multi-region support
- Data streaming com Kafka
- ML pipelines integration

## 🎯 Performance Optimization

### Current Optimizations
- ✅ Reduced memory footprint
- ✅ Minimal parallelism for low resources
- ✅ Indexed queries
- ✅ Partitioned processing

### Future Optimizations
- [ ] Columnar storage (Parquet)
- [ ] Table partitioning
- [ ] Query result caching
- [ ] Incremental processing
- [ ] Data compaction
