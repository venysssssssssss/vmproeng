# ⚡ Guia Rápido

## Iniciar o Projeto

```bash
# 1. Iniciar containers
./utils.sh start

# 2. Verificar status
./utils.sh status

# 3. Acessar Dashboard
# http://localhost:8501
```

## Parar o Projeto

```bash
./utils.sh stop
```

## Gerar Dados de Teste

```bash
# Via Dashboard
# http://localhost:8501 → Aba "Gerador Faker"

# Via Script (10,000 registros)
./utils.sh test 1000 10 1
```

## Executar DAG

```bash
# http://localhost:8080
# Login: admin/admin
# Clique em "Play" na DAG desejada
```

## Monitorar

```bash
# Ver uso de memória
./utils.sh memory

# Health check
./utils.sh health

# Contagem de dados
./utils.sh data-count

# Monitor em tempo real
./utils.sh monitor
```

## Limpar Dados

```bash
# Limpar apenas dados de teste
./utils.sh clean-data

# Reset completo (remove volumes)
./utils.sh reset
```

## Troubleshooting

```bash
# Ver logs
./utils.sh logs

# Ver logs de serviço específico
./utils.sh logs airflow_webserver

# Reiniciar tudo
./utils.sh restart
```

## Portas

- Dashboard: http://localhost:8501
- Airflow: http://localhost:8080 (admin/admin)
- Spark: http://localhost:8081
- MinIO: http://localhost:9001 (minioadmin/minioadmin)
- PostgreSQL: localhost:5432 (postgres/postgres)

## Comandos Úteis

```bash
# Ajuda completa
./utils.sh help

# Status detalhado
./utils.sh status

# Teste de capacidade (50,000 registros)
./utils.sh test 2000 25 1
```
