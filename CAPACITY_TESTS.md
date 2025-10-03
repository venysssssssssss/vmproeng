# 📊 Testes de Capacidade - Data Engineering Pipeline

## Objetivo
Descobrir a capacidade máxima de ingestão de dados com 900MB de RAM

---

## 🔧 Como Usar

### 1. Monitorar Memória em Tempo Real
```bash
chmod +x monitor_memory.sh
./monitor_memory.sh
```

### 2. Executar Teste de Capacidade
```bash
# Sintaxe: python test_capacity.py <batch_size> <num_batches> <delay>
/home/synev1/dev/vmpro1/.venv/bin/python test_capacity.py 1000 50 1

# Exemplos:
# Teste pequeno: 5,000 registros
/home/synev1/dev/vmpro1/.venv/bin/python test_capacity.py 500 10 1

# Teste médio: 50,000 registros
/home/synev1/dev/vmpro1/.venv/bin/python test_capacity.py 1000 50 1

# Teste grande: 100,000 registros
/home/synev1/dev/vmpro1/.venv/bin/python test_capacity.py 2000 50 1
```

### 3. Ver Uso de Memória Atual
```bash
docker stats --no-stream $(docker-compose ps -q) --format "table {{.Name}}\t{{.MemUsage}}"
```

---

## 📈 Resultados dos Testes

### Teste 1: 10,000 registros (Baseline)
**Data:** 03/10/2025  
**Configuração:**
- Batch Size: 1,000 registros
- Número de Batches: 10
- Delay: 2s
- Total: 10,000 registros

**Resultados:**
- ✅ **Tempo Total:** 25.7s (0.4 minutos)
- ✅ **Taxa:** 389 registros/segundo
- ✅ **Tempo médio/batch:** 0.77s
- ✅ **Batch mais rápido:** 0.69s
- ✅ **Batch mais lento:** 0.85s

**Dados Inseridos:**
- Raw Transactions: 10,000
- Raw Customers: 6,054
- Raw Products: 900

**Uso de Memória (após teste):**
| Container | Memória Usada | Limite | Percentual |
|-----------|---------------|---------|------------|
| Airflow Scheduler | 185.6 MB | 300 MB | 61.9% |
| Airflow Webserver | ~390 MB | 512 MB | ~76% |
| Dashboard | 125.3 MB | 128 MB | 97.9% |
| PostgreSQL | **27.0 MB** | 128 MB | 21.1% |
| Spark Master | 125.1 MB | 128 MB | 97.7% |
| Spark Worker | 0.8 MB | 128 MB | 0.6% |
| MinIO | 92.2 MB | 96 MB | 96.0% |
| **TOTAL** | **~946 MB** | 1,420 MB | **66.6%** |

**Análise:**
- PostgreSQL aumentou de 22MB para 27MB (+5MB para 10K registros)
- Projeção: ~0.5MB por 1,000 registros
- Sistema estável, sem picos de memória

---

### Teste 2: 50,000 registros (Carga Média)
**Status:** 🔄 Pendente

**Projeção:**
- Tempo estimado: ~2 minutos
- Memória PostgreSQL estimada: ~47 MB
- Total estimado: ~966 MB

---

### Teste 3: 100,000 registros (Carga Alta)
**Status:** 🔄 Pendente

**Projeção:**
- Tempo estimado: ~4 minutos
- Memória PostgreSQL estimada: ~72 MB
- Total estimado: ~991 MB

---

### Teste 4: 500,000 registros (Carga Máxima)
**Status:** 🔄 Pendente

**Projeção:**
- Tempo estimado: ~20 minutos
- Memória PostgreSQL estimada: ~272 MB (pode exceder limite de 128MB)
- Total estimado: ~1,191 MB ⚠️ **ACIMA DO LIMITE**

---

## 💡 Insights

### Capacidade Estimada
Com base no teste de 10K registros:

**Cenário Conservador (900MB total):**
- Memória disponível para dados: ~50 MB
- Capacidade estimada: **~100,000 registros**
- Taxa de ingestão: ~390 registros/segundo

**Cenário Otimizado (reduzindo outros serviços):**
- Se reduzir Dashboard para 96MB: +29MB disponível
- Se reduzir Spark Master para 96MB: +29MB disponível
- Total adicional: ~58MB
- Capacidade otimizada: **~200,000 registros**

### Gargalos Identificados
1. **Dashboard (125MB)** - Quase no limite
2. **Spark Master (125MB)** - Quase no limite
3. **MinIO (92MB)** - Quase no limite
4. **Airflow Webserver (390MB)** - Maior consumidor

### Recomendações

**Para maximizar capacidade com 900MB:**
1. ✅ Desabilitar Dashboard durante ingestão pesada (economiza 125MB)
2. ✅ Reduzir Airflow Webserver para 400MB (economiza 112MB)
3. ✅ Usar SequentialExecutor ao invés de LocalExecutor (economiza ~100MB)
4. ✅ Reduzir Spark Master/Worker para 96MB cada (economiza 64MB)

**Ganho potencial:** +400MB = **~1,300MB total disponível**
**Capacidade estimada:** **~400,000 registros**

---

## 🎯 Próximos Passos

1. [ ] Executar teste de 50,000 registros
2. [ ] Executar teste de 100,000 registros
3. [ ] Testar configuração otimizada (sem Dashboard)
4. [ ] Medir tempo de processamento Spark após ingestão
5. [ ] Testar DAGs do Airflow com dados em massa
6. [ ] Benchmark de queries analíticas

---

## 📝 Notas

- Os testes foram executados com sistema em repouso (sem outras cargas)
- PostgreSQL com configuração padrão (shared_buffers=32MB)
- Airflow com LocalExecutor (mais memória, melhor performance)
- Dados gerados aleatoriamente com Faker

---

## 🔍 Comandos Úteis

```bash
# Ver dados inseridos
PGPASSWORD=postgres psql -h localhost -U postgres -d datawarehouse -c "
SELECT 
    'Raw Transactions' as layer, COUNT(*) as count FROM raw.transactions_raw
    UNION ALL
SELECT 'Raw Customers', COUNT(*) FROM raw.customers_raw
    UNION ALL
SELECT 'Raw Products', COUNT(*) FROM raw.products_raw;
"

# Limpar dados de teste
PGPASSWORD=postgres psql -h localhost -U postgres -d datawarehouse -c "
TRUNCATE TABLE raw.transactions_raw CASCADE;
TRUNCATE TABLE raw.customers_raw CASCADE;
TRUNCATE TABLE raw.products_raw CASCADE;
"

# Ver tamanho do banco
PGPASSWORD=postgres psql -h localhost -U postgres -d datawarehouse -c "
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname IN ('raw', 'staging', 'processed', 'analytics')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"
```

---

**Última atualização:** 03/10/2025  
**Status:** ✅ Testes iniciais concluídos, sistema operacional
