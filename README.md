# Pipeline de Engenharia de Dados - High Level

## 📊 Arquitetura do Projeto

Este é um projeto completo de engenharia de dados que implementa uma pipeline moderna de ETL/ELT utilizando:

- **Ingestão de Dados**: Apache Kafka (lightweight) ou API REST
- **Processamento**: Apache Spark (PySpark) em modo standalone
- **Armazenamento**: PostgreSQL + MinIO (S3-compatible)
- **Orquestração**: Apache Airflow (lightweight mode)
- **Monitoramento**: Prometheus + Grafana (opcional, pode ser desabilitado)
- **Visualização**: Metabase

## 🚀 Especificações da VM

- **CPU**: 2 cores AMD EPYC 7551
- **RAM**: ~1GB (otimizado para uso mínimo de memória)
- **Arquitetura**: x86_64
- **OS**: Ubuntu

## 📁 Estrutura do Projeto

```
vmpro1/
├── docker-compose.yml          # Orquestração dos containers
├── airflow/                    # DAGs e configurações Airflow
│   ├── dags/
│   ├── plugins/
│   └── logs/
├── spark/                      # Jobs Spark
│   ├── jobs/
│   └── notebooks/
├── data/                       # Dados brutos e processados
│   ├── raw/
│   ├── staging/
│   └── processed/
├── sql/                        # Scripts SQL
│   └── init/
├── config/                     # Configurações
└── monitoring/                 # Dashboards e configs
```

## 🛠️ Tecnologias Utilizadas

- **Python 3.11**: Linguagem principal
- **Apache Airflow 2.8**: Orquestração de workflows
- **Apache Spark 3.5**: Processamento distribuído
- **PostgreSQL 15**: Data warehouse
- **MinIO**: Object storage (S3-compatible)
- **Redis**: Message broker para Airflow
- **Metabase**: BI e visualização

## 🎯 Casos de Uso

1. **ETL de E-commerce**: Ingestão e processamento de dados de vendas
2. **Análise de Logs**: Processamento e análise de logs de aplicações
3. **Data Quality**: Validação e qualidade de dados
4. **Agregações**: Criação de métricas e KPIs

## 📦 Como Executar

```bash
# 1. Construir e iniciar os containers
docker-compose up -d

# 2. Acessar interfaces:
# - Airflow: http://localhost:8080 (admin/admin)
# - Metabase: http://localhost:3000
# - MinIO: http://localhost:9001 (minioadmin/minioadmin)

# 3. Executar pipeline de exemplo
docker-compose exec airflow airflow dags trigger example_etl_pipeline
```

## 🔧 Otimizações para Low Memory

- Airflow em modo Sequential Executor (sem paralelização)
- Spark com memória limitada (512MB executor)
- PostgreSQL com shared_buffers reduzidos
- Desabilitar componentes opcionais quando necessário

## 📊 Pipeline de Dados

1. **Ingestão**: Dados brutos são coletados de APIs/arquivos
2. **Staging**: Dados são armazenados temporariamente no MinIO
3. **Transformação**: Spark processa e transforma os dados
4. **Load**: Dados processados vão para PostgreSQL
5. **Visualização**: Metabase consome dados do PostgreSQL

## 🔐 Credenciais Padrão

- **Airflow**: admin / admin
- **PostgreSQL**: postgres / postgres
- **MinIO**: minioadmin / minioadmin
- **Metabase**: Configure no primeiro acesso
# vmproeng
