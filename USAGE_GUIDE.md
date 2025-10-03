# Projeto de Engenharia de Dados - Guia de Uso

## 🚀 Quick Start

### 1. Iniciar o Projeto

```bash
# Dar permissão de execução aos scripts
chmod +x start.sh stop.sh

# Iniciar todos os serviços
./start.sh
```

Aguarde aproximadamente 30-60 segundos para todos os serviços iniciarem.

### 2. Acessar as Interfaces

- **Airflow**: http://localhost:8080
  - Usuário: `admin`
  - Senha: `admin`

- **Spark Master**: http://localhost:8081
  - Monitorar jobs Spark

- **MinIO Console**: http://localhost:9001
  - Usuário: `minioadmin`
  - Senha: `minioadmin`

- **Metabase**: http://localhost:3000
  - Configurar no primeiro acesso

### 3. Executar Pipeline de Dados

#### Pelo Airflow UI:
1. Acesse http://localhost:8080
2. Faça login (admin/admin)
3. Ative a DAG `ecommerce_etl_pipeline`
4. Clique no botão "Trigger DAG" (ícone de play)

#### Por linha de comando:
```bash
docker-compose exec airflow-webserver airflow dags trigger ecommerce_etl_pipeline
```

## 📊 Pipelines Disponíveis

### 1. ecommerce_etl_pipeline
**Frequência**: Diária  
**Descrição**: Pipeline completo de ETL para dados de e-commerce

**Etapas**:
1. Gera dados de transações de vendas
2. Carrega para camada raw
3. Limpa e transforma dados
4. Carrega dimensões
5. Carrega tabela fato
6. Cria agregações analíticas

### 2. api_ingestion
**Frequência**: A cada 6 horas  
**Descrição**: Ingere dados de clientes de API externa

**Etapas**:
1. Busca dados de clientes
2. Salva em formato JSON
3. Carrega para banco de dados
4. Atualiza tabela de dimensões

### 3. data_quality_check
**Frequência**: Diária  
**Descrição**: Verifica qualidade dos dados usando Spark

**Verificações**:
- Valores nulos
- Duplicatas
- Valores negativos
- Consistência de dados
- Distribuição de categorias

### 4. minio_datalake
**Frequência**: Diária  
**Descrição**: Gerencia data lake no MinIO

**Etapas**:
1. Cria buckets necessários
2. Upload de dados para S3
3. Lista objetos armazenados

## 🗄️ Estrutura do Data Warehouse

### Camadas de Dados

```
raw/               # Dados brutos da origem
├── sales_transactions
└── customer_data

staging/           # Dados limpos e validados
└── sales_clean

processed/         # Modelo dimensional (Star Schema)
├── dim_customers
├── dim_products
├── dim_date
└── fact_sales

analytics/         # Agregações e métricas
├── daily_sales_summary
├── product_performance
└── customer_metrics
```

## 📈 Conectar Metabase ao PostgreSQL

1. Acesse http://localhost:3000
2. Configure usuário e senha
3. Adicione banco de dados:
   - **Tipo**: PostgreSQL
   - **Host**: postgres
   - **Porta**: 5432
   - **Database**: datawarehouse
   - **Usuário**: postgres
   - **Senha**: postgres

4. Use as queries em `sql/analytics_queries.sql` para criar dashboards

## 🔍 Monitoramento

### Ver logs dos serviços

```bash
# Todos os serviços
docker-compose logs -f

# Serviço específico
docker-compose logs -f airflow-webserver
docker-compose logs -f postgres
docker-compose logs -f spark-master
```

### Status dos containers

```bash
docker-compose ps
```

### Uso de recursos

```bash
docker stats
```

## 🛠️ Comandos Úteis

### Airflow

```bash
# Listar DAGs
docker-compose exec airflow-webserver airflow dags list

# Executar DAG específica
docker-compose exec airflow-webserver airflow dags trigger <dag_id>

# Ver tarefas de uma DAG
docker-compose exec airflow-webserver airflow tasks list <dag_id>

# Criar usuário admin
docker-compose exec airflow-webserver airflow users create \
    --username admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@example.com
```

### PostgreSQL

```bash
# Conectar ao banco
docker-compose exec postgres psql -U postgres -d datawarehouse

# Executar query
docker-compose exec postgres psql -U postgres -d datawarehouse -c "SELECT COUNT(*) FROM processed.fact_sales;"

# Backup do banco
docker-compose exec postgres pg_dump -U postgres datawarehouse > backup.sql

# Restore do banco
docker-compose exec -T postgres psql -U postgres datawarehouse < backup.sql
```

### Spark

```bash
# Submeter job Spark
docker-compose exec spark-master spark-submit \
    --master spark://spark-master:7077 \
    --driver-memory 256m \
    --executor-memory 256m \
    /opt/spark-jobs/data_quality_check.py
```

### MinIO

```bash
# Listar buckets
docker-compose exec minio mc ls minio

# Criar bucket
docker-compose exec minio mc mb minio/my-bucket
```

## 🔧 Troubleshooting

### Serviços não iniciam

```bash
# Verificar logs
docker-compose logs

# Reiniciar serviços
docker-compose restart

# Parar e remover tudo
docker-compose down -v
./start.sh
```

### Pouca memória disponível

```bash
# Parar serviços opcionais
docker-compose stop metabase
docker-compose stop spark-worker

# Verificar uso de memória
free -h
docker stats
```

### Airflow não conecta ao banco

```bash
# Reinicializar banco do Airflow
docker-compose exec airflow-webserver airflow db reset
docker-compose exec airflow-webserver airflow db init
```

### Limpar dados antigos

```bash
# Limpar logs do Airflow
rm -rf airflow/logs/*

# Limpar dados raw
rm -rf data/raw/*
rm -rf data/staging/*
rm -rf data/processed/*

# Resetar banco (CUIDADO: apaga todos os dados)
docker-compose down -v
./start.sh
```

## 📦 Adicionar Novas DAGs

1. Criar arquivo Python em `airflow/dags/`
2. Seguir estrutura padrão do Airflow
3. DAG será detectada automaticamente (pode levar ~1 minuto)
4. Verificar no Airflow UI

## 🛑 Parar o Projeto

```bash
# Parar serviços (mantém dados)
./stop.sh

# Parar e limpar dados
./stop.sh --clean

# Ou manualmente
docker-compose down        # Para serviços
docker-compose down -v     # Para serviços e remove volumes
```

## 📊 Exemplos de Análises

### Query 1: Vendas dos últimos 7 dias
```sql
SELECT 
    d.full_date,
    COUNT(*) as transactions,
    SUM(f.total_amount) as revenue
FROM processed.fact_sales f
JOIN processed.dim_date d ON f.date_key = d.date_key
WHERE d.full_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY d.full_date
ORDER BY d.full_date;
```

### Query 2: Top 5 produtos
```sql
SELECT 
    p.product_name,
    p.category,
    SUM(f.total_amount) as revenue
FROM processed.fact_sales f
JOIN processed.dim_products p ON f.product_key = p.product_key
GROUP BY p.product_name, p.category
ORDER BY revenue DESC
LIMIT 5;
```

## 🎯 Próximos Passos

1. ✅ Configurar alertas no Airflow
2. ✅ Implementar testes de dados (Great Expectations)
3. ✅ Adicionar mais fontes de dados
4. ✅ Criar dashboards no Metabase
5. ✅ Implementar CDC (Change Data Capture)
6. ✅ Adicionar data lineage tracking

## 📚 Recursos Adicionais

- [Airflow Documentation](https://airflow.apache.org/docs/)
- [Spark Documentation](https://spark.apache.org/docs/latest/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MinIO Documentation](https://min.io/docs/)
- [Metabase Documentation](https://www.metabase.com/docs/)
