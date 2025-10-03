# 🚀 Data Engineering Project - Complete Pipeline

[![Python](https://img.shields.io/badge/Python-3.11-blue.svg)](https://www.python.org/)
[![Airflow](https://img.shields.io/badge/Airflow-2.8.0-orange.svg)](https://airflow.apache.org/)
[![Spark](https://img.shields.io/badge/Spark-3.5-red.svg)](https://spark.apache.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> Projeto completo de Engenharia de Dados com pipeline moderno de ETL/ELT, otimizado para ambientes com recursos limitados (2 CPUs, 1GB RAM).

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Arquitetura](#-arquitetura)
- [Tecnologias](#-tecnologias)
- [Quick Start](#-quick-start)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Pipelines Disponíveis](#-pipelines-disponíveis)
- [Uso](#-uso)
- [Documentação](#-documentação)
- [Contribuindo](#-contribuindo)

## 🎯 Visão Geral

Este projeto implementa uma pipeline completa de engenharia de dados seguindo as melhores práticas da indústria:

- ✅ **Arquitetura em Camadas**: Raw → Staging → Processed → Analytics
- ✅ **Modelo Dimensional**: Star Schema para análise eficiente
- ✅ **Orquestração**: Apache Airflow para workflows automatizados
- ✅ **Processamento**: Apache Spark para transformações em larga escala
- ✅ **Armazenamento**: PostgreSQL + MinIO (S3-compatible)
- ✅ **Visualização**: Metabase para BI e dashboards
- ✅ **Qualidade de Dados**: Validações automatizadas
- ✅ **Containerização**: Docker para portabilidade

## 🏗️ Arquitetura

```
Sources → Ingestion → Raw → Staging → Processed → Analytics → Visualization
          (Airflow)        (Clean)   (Star Schema)  (KPIs)    (Metabase)
```

**Componentes principais:**
- **Apache Airflow**: Orquestração de workflows
- **Apache Spark**: Processamento distribuído
- **PostgreSQL**: Data warehouse
- **MinIO**: Object storage (data lake)
- **Redis**: Message broker
- **Metabase**: Business Intelligence

Veja [ARCHITECTURE.md](ARCHITECTURE.md) para detalhes completos.

## 🛠️ Tecnologias

| Categoria | Tecnologia | Versão |
|-----------|------------|--------|
| **Orquestração** | Apache Airflow | 2.8.0 |
| **Processamento** | Apache Spark | 3.5 |
| **Data Warehouse** | PostgreSQL | 15 |
| **Object Storage** | MinIO | Latest |
| **Message Broker** | Redis | 7 |
| **BI Tool** | Metabase | Latest |
| **Linguagem** | Python | 3.11 |
| **Container** | Docker | Latest |

## 🚀 Quick Start

### Pré-requisitos

- Docker Engine 20.10+
- Docker Compose 2.0+
- 1GB RAM disponível
- 2 CPU cores

### Instalação

```bash
# 1. Clone o repositório
git clone <repository-url>
cd vmpro1

# 2. Inicie os serviços
chmod +x start.sh
./start.sh

# 3. Aguarde ~60 segundos para os serviços iniciarem
```

### Acesso às Interfaces

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| **Airflow** | http://localhost:8080 | admin / admin |
| **Spark Master** | http://localhost:8081 | - |
| **MinIO Console** | http://localhost:9001 | minioadmin / minioadmin |
| **Metabase** | http://localhost:3000 | Configure no primeiro acesso |

### Executar Pipeline

```bash
# Via Makefile
make trigger-etl

# Ou diretamente
docker-compose exec airflow-webserver airflow dags trigger ecommerce_etl_pipeline
```

## 📁 Estrutura do Projeto

```
vmpro1/
├── airflow/                    # Airflow DAGs e configurações
│   ├── dags/                   # Pipeline definitions
│   │   ├── ecommerce_etl_pipeline.py
│   │   ├── api_ingestion_dag.py
│   │   ├── data_quality_dag.py
│   │   └── minio_datalake_dag.py
│   ├── logs/                   # Execution logs
│   └── plugins/                # Custom plugins
│
├── spark/                      # Spark jobs
│   ├── jobs/                   # PySpark scripts
│   │   ├── data_quality_check.py
│   │   └── sales_aggregation.py
│   └── notebooks/              # Jupyter notebooks
│
├── data/                       # Data storage
│   ├── raw/                    # Raw data
│   ├── staging/                # Cleaned data
│   └── processed/              # Processed data
│
├── sql/                        # SQL scripts
│   ├── init/                   # Database initialization
│   │   └── 01_init_db.sql
│   └── analytics_queries.sql   # Analytics queries
│
├── config/                     # Configuration files
│   └── airflow.cfg
│
├── docker-compose.yml          # Container orchestration
├── requirements.txt            # Python dependencies
├── Makefile                    # Automation commands
├── start.sh                    # Startup script
├── stop.sh                     # Shutdown script
├── .env                        # Environment variables
├── README.md                   # Este arquivo
├── ARCHITECTURE.md             # Documentação de arquitetura
├── USAGE_GUIDE.md              # Guia de uso detalhado
└── ROADMAP.md                  # Roadmap de melhorias
```

## 📊 Pipelines Disponíveis

### 1. E-commerce ETL Pipeline
- **Schedule**: Diário
- **Descrição**: Pipeline completo de vendas (extração → transformação → carregamento)
- **Etapas**: Gera dados → Raw → Staging → Dimensões → Fato → Analytics

### 2. API Data Ingestion
- **Schedule**: A cada 6 horas
- **Descrição**: Ingere dados de clientes de APIs externas
- **Etapas**: Fetch API → JSON → Database → Dimensões

### 3. Data Quality Check
- **Schedule**: Diário
- **Descrição**: Verifica qualidade usando Spark
- **Validações**: Nulls, duplicatas, valores negativos, consistência

### 4. MinIO Data Lake
- **Schedule**: Diário
- **Descrição**: Gerencia data lake no MinIO
- **Etapas**: Cria buckets → Upload → Catalogação

## 💻 Uso

### Comandos Makefile

```bash
make help              # Lista todos os comandos
make start             # Inicia serviços
make stop              # Para serviços
make logs              # Visualiza logs
make status            # Status dos containers
make trigger-etl       # Executa pipeline ETL
make backup-db         # Backup do banco
make shell-postgres    # Acessa PostgreSQL
make clean-data        # Limpa dados temporários
```

### Comandos Manuais

```bash
# Ver logs do Airflow
docker-compose logs -f airflow-webserver

# Executar DAG
docker-compose exec airflow-webserver airflow dags trigger <dag_id>

# Acessar PostgreSQL
docker-compose exec postgres psql -U postgres -d datawarehouse

# Parar tudo e limpar
./stop.sh --clean
```

## 📚 Documentação

- **[ARCHITECTURE.md](ARCHITECTURE.md)**: Arquitetura detalhada do sistema
- **[USAGE_GUIDE.md](USAGE_GUIDE.md)**: Guia completo de uso
- **[ROADMAP.md](ROADMAP.md)**: Melhorias futuras

## 🎓 Casos de Uso

1. **E-commerce Analytics**: Análise de vendas, produtos e clientes
2. **Data Quality Monitoring**: Validação automatizada de dados
3. **Data Lake Management**: Armazenamento em object storage
4. **BI Dashboards**: Visualizações no Metabase
5. **ETL Automation**: Pipelines orquestrados pelo Airflow

## 🔧 Configuração do Ambiente

### Recursos Otimizados para Low Memory

```yaml
PostgreSQL:
  shared_buffers: 64MB
  max_connections: 50
  
Airflow:
  executor: LocalExecutor
  parallelism: 4
  workers: 2

Spark:
  driver_memory: 256m
  executor_memory: 256m
  executor_cores: 1
```

## 🐛 Troubleshooting

### Problemas Comuns

**Serviços não iniciam:**
```bash
docker-compose logs
docker-compose restart
```

**Erro de memória:**
```bash
# Parar serviços opcionais
docker-compose stop metabase
```

**Airflow não conecta:**
```bash
docker-compose exec airflow-webserver airflow db reset
```

Veja [USAGE_GUIDE.md](USAGE_GUIDE.md) para mais detalhes.

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 👥 Autores

- **Data Engineering Team** - *Initial work*

## 🙏 Agradecimentos

- Apache Software Foundation (Airflow, Spark)
- PostgreSQL Global Development Group
- MinIO Project
- Metabase Team
- Docker Community

## 📞 Suporte

Para questões e suporte:
- Abra uma issue no GitHub
- Consulte a documentação em `/docs`
- Entre em contato: admin@example.com

---

**⭐ Se este projeto foi útil, considere dar uma estrela!**
