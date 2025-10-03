# 🚀 Como Rodar o Projeto - Guia Completo

## Passo 1: Verificar Ambiente Python (Poetry)

```bash
# Verificar se o ambiente virtual está ativo
poetry env info

# Se não estiver, ativar o ambiente
poetry shell

# Verificar versão do Python (deve ser 3.11.9)
python --version

# Verificar dependências instaladas
poetry show
```

## Passo 2: Iniciar os Serviços Docker

### Opção A: Usando o script de inicialização (Recomendado)
```bash
# Tornar script executável
chmod +x start.sh

# Iniciar todos os serviços
./start.sh
```

### Opção B: Usando Docker Compose diretamente
```bash
# Iniciar todos os serviços
docker-compose up -d

# Verificar se os containers estão rodando
docker-compose ps
```

## Passo 3: Aguardar Inicialização

Aguarde **60-90 segundos** para todos os serviços iniciarem completamente.

## Passo 4: Verificar Saúde dos Serviços

### Verificação Rápida
```bash
# Ver status de todos os containers
docker-compose ps

# Ver uso de recursos
docker stats --no-stream
```

### Verificação Completa (Script de Health Check)
```bash
# Tornar executável
chmod +x health-check.sh

# Executar verificação
./health-check.sh
```

### Verificação Manual de Cada Serviço

#### PostgreSQL
```bash
# Testar conexão
docker exec de_postgres pg_isready -U postgres

# Conectar ao banco
docker exec -it de_postgres psql -U postgres -d datawarehouse

# Dentro do psql, verificar schemas:
\dn

# Listar tabelas
\dt raw.*
\dt staging.*
\dt processed.*
\dt analytics.*

# Sair do psql
\q
```

#### Redis
```bash
# Testar conexão
docker exec de_redis redis-cli ping
# Deve retornar: PONG
```

#### MinIO
```bash
# Verificar se está rodando
curl -I http://localhost:9001

# Acessar console web
# Abra: http://localhost:9001
# Login: minioadmin / minioadmin
```

#### Airflow
```bash
# Verificar se webserver está respondendo
curl -I http://localhost:8080/health

# Listar DAGs disponíveis
docker exec de_airflow_webserver airflow dags list

# Verificar logs do scheduler
docker-compose logs airflow-scheduler | tail -20
```

#### Spark
```bash
# Verificar Spark Master
curl -I http://localhost:8081

# Ver informação do cluster
docker exec de_spark_master /opt/bitnami/spark/bin/spark-submit --version
```

## Passo 5: Acessar Interfaces Web

Abra seu navegador e acesse:

### 1. Airflow UI
- **URL**: http://localhost:8080
- **Login**: `admin`
- **Senha**: `admin`

**O que fazer:**
- Verificar se as DAGs aparecem na lista
- Ativar as DAGs (toggle no canto esquerdo)
- Observar se não há erros

### 2. Spark Master UI
- **URL**: http://localhost:8081
- Verificar workers conectados
- Ver histórico de jobs

### 3. MinIO Console
- **URL**: http://localhost:9001
- **Login**: `minioadmin`
- **Senha**: `minioadmin`
- Verificar buckets criados

### 4. Metabase
- **URL**: http://localhost:3000
- Configurar no primeiro acesso
- Conectar ao PostgreSQL

## Passo 6: Executar Pipeline de Teste

### Opção A: Via Airflow UI
1. Acesse http://localhost:8080
2. Clique na DAG `ecommerce_etl_pipeline`
3. Clique no botão "Trigger DAG" (▶️)
4. Acompanhe a execução em Graph View

### Opção B: Via Linha de Comando
```bash
# Executar pipeline principal
docker exec de_airflow_webserver airflow dags trigger ecommerce_etl_pipeline

# Executar pipeline de ingestão de API
docker exec de_airflow_webserver airflow dags trigger api_data_ingestion

# Executar verificação de qualidade
docker exec de_airflow_webserver airflow dags trigger data_quality_check

# Ver status das execuções
docker exec de_airflow_webserver airflow dags list-runs -d ecommerce_etl_pipeline
```

### Opção C: Usando Makefile
```bash
# Ver todos os comandos disponíveis
make help

# Executar pipeline ETL
make trigger-etl

# Executar ingestão
make trigger-ingestion

# Executar qualidade
make trigger-quality

# Ver logs do Airflow
make logs-airflow

# Ver status dos containers
make status
```

## Passo 7: Verificar Resultados

### Verificar Dados no PostgreSQL
```bash
# Conectar ao banco
docker exec -it de_postgres psql -U postgres -d datawarehouse

# Verificar dados na camada RAW
SELECT COUNT(*) FROM raw.sales_transactions;
SELECT COUNT(*) FROM raw.customer_data;

# Verificar dados na camada STAGING
SELECT COUNT(*) FROM staging.sales_clean;

# Verificar dimensões
SELECT COUNT(*) FROM processed.dim_customers;
SELECT COUNT(*) FROM processed.dim_products;
SELECT COUNT(*) FROM processed.dim_date;

# Verificar tabela fato
SELECT COUNT(*) FROM processed.fact_sales;

# Ver primeiras linhas da tabela fato
SELECT * FROM processed.fact_sales LIMIT 5;

# Verificar agregações analíticas
SELECT * FROM analytics.daily_sales_summary ORDER BY summary_date DESC LIMIT 5;

# Sair
\q
```

### Verificar Logs de Execução
```bash
# Logs do Airflow Scheduler
docker-compose logs airflow-scheduler | tail -50

# Logs de uma DAG específica (dentro do container Airflow)
docker exec de_airflow_webserver airflow tasks test ecommerce_etl_pipeline generate_sales_data 2024-01-01

# Logs do Spark
docker-compose logs spark-master | tail -30
```

## Passo 8: Executar Queries Analíticas

```bash
# Conectar ao banco
docker exec -it de_postgres psql -U postgres -d datawarehouse

# Query 1: Top 10 produtos mais vendidos
SELECT 
    p.product_name,
    p.category,
    SUM(f.quantity) as total_quantity,
    SUM(f.total_amount) as total_revenue
FROM processed.fact_sales f
JOIN processed.dim_products p ON f.product_key = p.product_key
GROUP BY p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 10;

# Query 2: Vendas por dia da semana
SELECT 
    d.day_name,
    COUNT(*) as transactions,
    SUM(f.total_amount) as revenue
FROM processed.fact_sales f
JOIN processed.dim_date d ON f.date_key = d.date_key
GROUP BY d.day_name, d.day_of_week
ORDER BY d.day_of_week;

# Query 3: Top 5 clientes
SELECT 
    c.customer_name,
    c.city,
    COUNT(*) as purchases,
    SUM(f.total_amount) as total_spent
FROM processed.fact_sales f
JOIN processed.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.customer_name, c.city
ORDER BY total_spent DESC
LIMIT 5;
```

## Passo 9: Monitoramento Contínuo

### Ver logs em tempo real
```bash
# Todos os serviços
docker-compose logs -f

# Apenas Airflow
docker-compose logs -f airflow-webserver airflow-scheduler

# Apenas Spark
docker-compose logs -f spark-master spark-worker

# Apenas PostgreSQL
docker-compose logs -f postgres
```

### Monitorar uso de recursos
```bash
# Ver uso de CPU e memória
docker stats

# Ver uso de disco
df -h

# Ver memória livre no sistema
free -h
```

## Passo 10: Parar o Projeto

### Parar serviços (mantém dados)
```bash
# Usando script
./stop.sh

# Ou usando docker-compose
docker-compose down
```

### Parar e limpar tudo (remove dados)
```bash
# Usando script com limpeza
./stop.sh --clean

# Ou usando docker-compose
docker-compose down -v

# Limpar dados manualmente
make clean-data
```

## 🐛 Troubleshooting

### Problema: Container não inicia
```bash
# Ver logs do container com problema
docker-compose logs [nome-do-container]

# Reiniciar container específico
docker-compose restart [nome-do-container]

# Recriar container
docker-compose up -d --force-recreate [nome-do-container]
```

### Problema: Airflow não mostra DAGs
```bash
# Verificar se DAGs estão no local correto
ls -la airflow/dags/

# Ver logs do scheduler
docker-compose logs airflow-scheduler | grep -i "dag"

# Forçar atualização das DAGs
docker exec de_airflow_webserver airflow dags list-import-errors
```

### Problema: Erro de memória
```bash
# Verificar uso de recursos
docker stats

# Reduzir workers do Airflow (editar docker-compose.yml)
# Ou desligar serviços não essenciais temporariamente
docker-compose stop metabase
docker-compose stop spark-worker
```

### Problema: Banco de dados não conecta
```bash
# Verificar se PostgreSQL está rodando
docker-compose ps postgres

# Verificar logs
docker-compose logs postgres

# Testar conexão
docker exec de_postgres pg_isready -U postgres

# Reiniciar banco
docker-compose restart postgres
```

## ✅ Checklist de Verificação

- [ ] Python 3.11.9 instalado via pyenv
- [ ] Poetry configurado e dependências instaladas
- [ ] Docker e Docker Compose funcionando
- [ ] Todos os containers iniciados (8 containers)
- [ ] PostgreSQL aceita conexões
- [ ] Redis responde PONG
- [ ] Airflow UI acessível em localhost:8080
- [ ] DAGs aparecem no Airflow
- [ ] Pipeline ETL executado com sucesso
- [ ] Dados carregados nas tabelas do DW
- [ ] Queries analíticas retornam resultados
- [ ] MinIO Console acessível
- [ ] Spark Master UI acessível
- [ ] Metabase configurado e conectado

## 📊 KPIs de Sucesso

Após executar o pipeline, você deve ter:

- ✅ Dados em `raw.sales_transactions` (50-200 registros)
- ✅ Dados em `staging.sales_clean` (mesma quantidade limpa)
- ✅ Dimensões populadas (`dim_customers`, `dim_products`, `dim_date`)
- ✅ Fatos carregados em `fact_sales`
- ✅ Agregações em `analytics.*`
- ✅ Jobs Spark executados sem erros
- ✅ DAGs verdes no Airflow

## 🎯 Próximos Passos

1. **Explorar Dashboards**: Criar visualizações no Metabase
2. **Personalizar DAGs**: Modificar pipelines para seus dados
3. **Adicionar Fontes**: Integrar novas fontes de dados
4. **Otimizar**: Ajustar recursos e performance
5. **Automatizar**: Configurar schedules e alertas

---

**Dica**: Use `make help` para ver todos os comandos disponíveis!
