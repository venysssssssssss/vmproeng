# 📦 Data Engineering Pipeline - Projeto Otimizado

## ✨ O Que Foi Feito

### 1. Consolidação de Documentação
- ✅ **Removidos 10 arquivos** de documentação redundante
- ✅ **Criado README.md** completo e conciso
- ✅ **Criado QUICKSTART.md** para início rápido
- ✅ **Criado .env.example** com variáveis de ambiente

### 2. Consolidação de Scripts
- ✅ **Removidos 5 scripts** dispersos (start.sh, stop.sh, etc)
- ✅ **Criado utils.sh** único com 12 comandos úteis
- ✅ Comandos organizados por categoria (gerenciamento, monitoramento, dados)

### 3. Limpeza de Arquivos
- ✅ Removidos Makefile, poetry.lock, pyproject.toml (não utilizados)
- ✅ Estrutura limpa e organizada
- ✅ Apenas arquivos essenciais mantidos

---

## 📁 Estrutura Final

```
vmpro1/
├── README.md              # Documentação completa (única fonte de verdade)
├── QUICKSTART.md          # Guia rápido de comandos
├── .env.example           # Template de variáveis
├── utils.sh               # CLI única com todos os comandos
├── docker-compose.yml     # Configuração dos serviços
├── test_capacity.py       # Testes de capacidade
├── monitor_memory.sh      # Monitor de memória em tempo real
├── airflow/
│   ├── dags/              # 4 DAGs prontas
│   ├── logs/              # Logs do Airflow
│   └── plugins/           # Plugins customizados
├── spark/
│   ├── jobs/              # Jobs Spark (data_quality_check, sales_aggregation)
│   └── notebooks/         # Notebooks Jupyter
├── sql/
│   ├── init/              # Scripts de inicialização do banco
│   └── analytics_queries.sql
├── monitoring/
│   └── dashboard.py       # Dashboard Streamlit completo
└── data/                  # Dados (raw/staging/processed)
```

---

## 🎯 Comandos Principais

### Início Rápido
```bash
./utils.sh start    # Inicia tudo
./utils.sh status   # Verifica status
./utils.sh health   # Health check completo
```

### Gerenciamento
```bash
./utils.sh stop     # Para tudo
./utils.sh restart  # Reinicia
./utils.sh reset    # Reset completo (limpa volumes)
```

### Monitoramento
```bash
./utils.sh memory      # Uso de RAM
./utils.sh monitor     # Monitor em tempo real
./utils.sh data-count  # Contagem de registros
./utils.sh logs        # Ver todos os logs
```

### Dados e Testes
```bash
./utils.sh test 1000 50 1  # Teste: 50K registros
./utils.sh clean-data      # Limpar dados de teste
```

---

## 🌐 Endpoints

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| **Dashboard** | http://localhost:8501 | - |
| **Airflow** | http://localhost:8080 | admin/admin |
| **Spark UI** | http://localhost:8081 | - |
| **MinIO** | http://localhost:9001 | minioadmin/minioadmin |
| **PostgreSQL** | localhost:5432 | postgres/postgres |

---

## 📊 Status Atual

### ✅ Serviços Funcionando
- [x] PostgreSQL 15 (128 MB)
- [x] MinIO (96 MB)
- [x] Spark Master (128 MB)
- [x] Spark Worker (128 MB)
- [x] Airflow Webserver (512 MB)
- [x] Airflow Scheduler (300 MB)
- [x] Dashboard Streamlit (128 MB)

### 📈 Métricas
- **Total RAM:** ~1.3 GB
- **Containers:** 7 ativos
- **DAGs:** 4 disponíveis
- **Capacidade testada:** 50,000 registros em <1 min
- **Taxa de ingestão:** ~870 registros/segundo

### 🎲 Dados de Teste Atual
- **Raw Transactions:** 50,000
- **Raw Customers:** 8,966
- **Raw Products:** 900

---

## 📚 Documentação

### README.md (Principal)
- Visão geral completa
- Arquitetura detalhada
- Guia de uso
- Arquitetura de dados (4 camadas)
- Testes de capacidade
- Troubleshooting completo

### QUICKSTART.md
- Comandos essenciais
- Fluxo de trabalho básico
- Atalhos úteis

### .env.example
- Todas as variáveis de ambiente
- Valores padrão documentados
- Guia de configuração

---

## 🔧 Melhorias Implementadas

1. **Documentação Única**
   - Antes: 10+ arquivos dispersos
   - Depois: 2 arquivos principais (README + QUICKSTART)

2. **Scripts Consolidados**
   - Antes: 5+ scripts bash separados
   - Depois: 1 CLI unificado (utils.sh)

3. **Comandos Intuitivos**
   - Antes: Precisava saber comandos Docker
   - Depois: `./utils.sh <comando>` auto-explicativo

4. **Health Checks**
   - Verificação automática de todos os serviços
   - Detecção de problemas rápida

5. **Testes Automatizados**
   - Scripts de teste de capacidade
   - Monitor de memória em tempo real

---

## 🚀 Próximos Passos Sugeridos

1. **Performance**
   - [ ] Otimizar queries SQL com indexes
   - [ ] Tune de parâmetros Spark
   - [ ] Cache de dados frequentes

2. **Observabilidade**
   - [ ] Integrar Prometheus + Grafana
   - [ ] Logs centralizados (ELK Stack)
   - [ ] Alertas automáticos

3. **Segurança**
   - [ ] Credenciais via secrets
   - [ ] HTTPS nos endpoints
   - [ ] Network policies

4. **CI/CD**
   - [ ] GitHub Actions
   - [ ] Testes automatizados
   - [ ] Deploy automatizado

5. **Features**
   - [ ] Adicionar Metabase para BI
   - [ ] Data lineage tracking
   - [ ] Data quality framework

---

## 💡 Dicas de Uso

### Para Desenvolvimento
```bash
# Iniciar sem Dashboard (economiza 128MB)
docker-compose up -d postgres minio spark-master spark-worker airflow-webserver airflow-scheduler

# Ver logs em tempo real
./utils.sh logs airflow_webserver

# Monitorar performance
./utils.sh monitor
```

### Para Testes
```bash
# Teste rápido (10K registros)
./utils.sh test 1000 10 1

# Teste médio (50K registros)
./utils.sh test 2000 25 1

# Limpar depois
./utils.sh clean-data
```

### Para Produção
```bash
# Alterar credenciais em .env
cp .env.example .env
vim .env

# Iniciar com volumes persistentes
./utils.sh start

# Monitorar saúde
watch -n 10 './utils.sh health'
```

---

## 📞 Suporte

- **Documentação:** README.md e QUICKSTART.md
- **Ajuda:** `./utils.sh help`
- **Logs:** `./utils.sh logs [servico]`
- **Status:** `./utils.sh status`

---

**✨ Projeto otimizado e pronto para uso!**
