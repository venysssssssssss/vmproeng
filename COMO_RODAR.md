# Como Rodar o Projeto - Guia Rápido

## 🚀 Início Rápido

### 1. Preparar o Ambiente

```bash
# Dar permissão aos scripts
chmod +x start.sh stop.sh health-check.sh

# Verificar se Docker está rodando
docker --version
docker compose version
```

### 2. Iniciar o Projeto

```bash
# Opção 1: Usando o script de inicialização (RECOMENDADO)
./start.sh

# Opção 2: Manualmente com Docker Compose
docker compose up -d
```

O script `start.sh` irá:
- ✅ Criar diretórios necessários
- ✅ Configurar permissões
- ✅ Baixar imagens Docker
- ✅ Iniciar todos os serviços

### 3. Verificar Status dos Serviços

```bash
# Ver containers rodando
docker compose ps

# Ver logs em tempo real
docker compose logs -f

# Ver logs de um serviço específico
docker compose logs -f airflow-webserver
docker compose logs -f postgres
docker compose logs -f spark-master

# Verificar saúde dos serviços
./health-check.sh
```

### 4. Acessar as Interfaces Web

Aguarde 1-2 minutos para os serviços iniciarem completamente, depois acesse:

#### 🌐 **Apache Airflow** (Orquestração)
- URL: http://localhost:8080
- Usuário: `admin`
- Senha: `admin`
- Aqui você verá e executará as DAGs (pipelines)

#### 📊 **Metabase** (BI & Analytics)
- URL: http://localhost:3000
- Configure na primeira vez:
  - Database: PostgreSQL
  - Host: `postgres`
  - Port: `5432`
  - Database name: `datawarehouse`
  - Username: `postgres`
  - Password: `postgres`

#### 🔥 **Spark Master UI**
- URL: http://localhost:8081
- Monitore jobs Spark

#### 📦 **MinIO Console** (Object Storage)
- URL: http://localhost:9001
- Usuário: `minioadmin`
- Senha: `minioadmin`

### 5. Executar Pipelines de Dados

#### Método 1: Via Interface do Airflow (Web UI)
1. Acesse http://localhost:8080
2. Login: `admin` / `admin`
3. Veja as DAGs disponíveis:
   - `api_data_ingestion` - Ingestão de dados de API
   - `ecommerce_etl_pipeline` - Pipeline ETL completo
   - `data_quality_check` - Verificação de qualidade
   - `minio_datalake_pipeline` - Pipeline Data Lake

4. Clique em uma DAG e depois no botão ▶️ (play) para executar

#### Método 2: Via Linha de Comando
```bash
# Executar uma DAG específica
docker exec de_airflow_webserver airflow dags trigger api_data_ingestion

# Listar todas as DAGs
docker exec de_airflow_webserver airflow dags list

# Ver status de execuções
docker exec de_airflow_webserver airflow dags list-runs
```

### 6. Conectar ao Banco de Dados

```bash
# Via Docker (linha de comando)
docker exec -it de_postgres psql -U postgres -d datawarehouse

# Ou use um client SQL como DBeaver/pgAdmin:
# Host: localhost
# Port: 5432
# Database: datawarehouse
# Username: postgres
# Password: postgres
```

#### Queries úteis:
```sql
-- Ver dados brutos
SELECT * FROM raw.sales_data LIMIT 10;
SELECT * FROM raw.customer_data LIMIT 10;

-- Ver dados processados
SELECT * FROM processed.dim_customers LIMIT 10;
SELECT * FROM processed.dim_products LIMIT 10;
SELECT * FROM processed.fact_sales LIMIT 10;

-- Analytics
SELECT * FROM analytics.sales_summary;
SELECT * FROM analytics.customer_metrics;
```

### 7. Monitoramento

```bash
# Ver uso de recursos
docker stats

# Health check completo
./health-check.sh

# Ver logs específicos com filtro
docker compose logs airflow-scheduler | grep ERROR
docker compose logs postgres | grep FATAL
```

### 8. Parar o Projeto

```bash
# Opção 1: Usando o script (RECOMENDADO)
./stop.sh

# Opção 2: Parar mas manter dados
docker compose stop

# Opção 3: Parar e remover containers
docker compose down

# Opção 4: Remover TUDO (containers + volumes)
docker compose down -v
```

## 🔍 Troubleshooting

### Problema: Container não inicia
```bash
# Ver logs do container
docker compose logs <nome-do-servico>

# Reiniciar um serviço específico
docker compose restart <nome-do-servico>
```

### Problema: Porta já em uso
```bash
# Verificar o que está usando a porta
sudo lsof -i :8080  # Airflow
sudo lsof -i :5432  # PostgreSQL
sudo lsof -i :3000  # Metabase

# Matar processo
sudo kill -9 <PID>
```

### Problema: Memória insuficiente
```bash
# Liberar memória
docker system prune -a

# Limpar volumes não usados
docker volume prune
```

### Problema: Airflow DB não inicializa
```bash
# Resetar Airflow
docker compose down
docker volume rm vmpro1_postgres_data
docker compose up -d
```

## 📊 Arquitetura dos Serviços

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Airflow   │────▶│  PostgreSQL  │◀────│  Metabase   │
│ (8080)      │     │  (5432)      │     │  (3000)     │
└─────────────┘     └──────────────┘     └─────────────┘
       │                    │
       │                    │
       ▼                    ▼
┌─────────────┐     ┌──────────────┐
│    Spark    │     │    MinIO     │
│ Master/Work │     │  (9000/9001) │
│   (8081)    │     └──────────────┘
└─────────────┘
```

## 🎯 Próximos Passos

1. ✅ Acesse o Airflow e execute sua primeira DAG
2. ✅ Configure o Metabase para visualizar dados
3. ✅ Explore os dados no PostgreSQL
4. ✅ Customize as DAGs conforme necessário
5. ✅ Monitore a performance com `docker stats`

## 📝 Comandos Úteis

```bash
# Ver todos os containers
docker compose ps -a

# Seguir logs de todos os serviços
docker compose logs -f

# Executar comando no container
docker exec -it de_postgres bash

# Backup do banco de dados
docker exec de_postgres pg_dump -U postgres datawarehouse > backup.sql

# Restore do banco
cat backup.sql | docker exec -i de_postgres psql -U postgres datawarehouse

# Ver uso de disco dos volumes
docker system df -v
```

## 🆘 Suporte

Se encontrar problemas:
1. Verifique os logs: `docker compose logs`
2. Execute health check: `./health-check.sh`
3. Verifique recursos: `docker stats`
4. Reinicie o serviço: `docker compose restart <service>`
