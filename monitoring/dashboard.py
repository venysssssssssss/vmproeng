"""
Data Engineering Pipeline Dashboard
Interface para monitoramento de DAGs, dados e geração com Faker
"""

import json
import time
from datetime import datetime, timedelta

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import psycopg2
import requests
import streamlit as st

# Configuração da página
st.set_page_config(
    page_title='Data Engineering Dashboard', page_icon='📊', layout='wide'
)

# Funções de conexão
@st.cache_resource
def get_db_connection():
    """Conecta ao PostgreSQL"""
    try:
        conn = psycopg2.connect(
            host='postgres',
            database='datawarehouse',
            user='postgres',
            password='postgres',
            port=5432,
        )
        return conn
    except Exception as e:
        st.error(f'Erro ao conectar PostgreSQL: {e}')
        return None


def execute_query(query, params=None):
    """Executa query e retorna resultados"""
    conn = get_db_connection()
    if not conn:
        return None

    try:
        cursor = conn.cursor()
        cursor.execute(query, params)

        if query.strip().upper().startswith('SELECT'):
            results = cursor.fetchall()
            columns = [desc[0] for desc in cursor.description]
            return results, columns
        else:
            conn.commit()
            return cursor.rowcount, None
    except Exception as e:
        st.error(f'Erro ao executar query: {e}')
        return None, None
    finally:
        cursor.close()


def get_airflow_status():
    """Verifica status do Airflow"""
    try:
        response = requests.get(
            'http://airflow-webserver:8080/health', timeout=5
        )
        return response.status_code == 200
    except:
        return False


def trigger_dag(dag_id):
    """Dispara uma DAG via API do Airflow"""
    try:
        # Como estamos usando SQLite, vamos simular o trigger via arquivo
        st.success(f'DAG {dag_id} seria executada aqui!')
        return True
    except Exception as e:
        st.error(f'Erro ao executar DAG: {e}')
        return False


# Interface principal
def main():
    st.title('🚀 Data Engineering Pipeline Dashboard')
    st.markdown('---')

    # Sidebar
    st.sidebar.title('🎛️ Controles')

    # Status dos serviços
    st.sidebar.subheader('📊 Status dos Serviços')

    # Verificar PostgreSQL
    conn = get_db_connection()
    if conn:
        st.sidebar.success('✅ PostgreSQL')
    else:
        st.sidebar.error('❌ PostgreSQL')

    # Verificar Airflow
    if get_airflow_status():
        st.sidebar.success('✅ Airflow')
    else:
        st.sidebar.warning('⚠️ Airflow')

    # Tabs principais
    tab1, tab2, tab3, tab4 = st.tabs(
        ['📊 Visão Geral', '🔄 DAGs', '📈 Dados', '🎲 Gerador Faker']
    )

    with tab1:
        show_overview()

    with tab2:
        show_dags()

    with tab3:
        show_data_layers()

    with tab4:
        show_faker_generator()


def show_overview():
    """Visão geral do sistema"""
    st.header('📊 Visão Geral do Pipeline')

    col1, col2, col3, col4 = st.columns(4)

    try:
        # Total de transações
        data, _ = execute_query('SELECT COUNT(*) FROM raw.sales_transactions')
        if data:
            col1.metric('Total Transações', data[0][0])

        # Revenue total
        data, _ = execute_query(
            "SELECT COALESCE(SUM(total_amount), 0) FROM raw.sales_transactions WHERE status = 'Completed'"
        )
        if data:
            col2.metric('Revenue Total', f'R$ {data[0][0]:,.2f}')

        # Clientes únicos
        data, _ = execute_query(
            'SELECT COUNT(DISTINCT customer_id) FROM raw.sales_transactions'
        )
        if data:
            col3.metric('Clientes Únicos', data[0][0])

        # Produtos únicos
        data, _ = execute_query(
            'SELECT COUNT(DISTINCT product_id) FROM raw.sales_transactions'
        )
        if data:
            col4.metric('Produtos Únicos', data[0][0])

        # Gráfico de vendas por categoria
        st.subheader('📈 Vendas por Categoria')
        data, columns = execute_query(
            """
            SELECT category, COUNT(*) as transactions, SUM(total_amount) as revenue
            FROM raw.sales_transactions 
            WHERE status = 'Completed'
            GROUP BY category 
            ORDER BY revenue DESC
        """
        )

        if data:
            df = pd.DataFrame(
                data, columns=['Categoria', 'Transações', 'Revenue']
            )

            col1, col2 = st.columns(2)

            with col1:
                fig = px.bar(
                    df,
                    x='Categoria',
                    y='Transações',
                    title='Transações por Categoria',
                )
                st.plotly_chart(fig, use_container_width=True)

            with col2:
                fig = px.pie(
                    df,
                    values='Revenue',
                    names='Categoria',
                    title='Revenue por Categoria',
                )
                st.plotly_chart(fig, use_container_width=True)

    except Exception as e:
        st.error(f'Erro ao buscar dados: {e}')


def show_dags():
    """Informações sobre DAGs"""
    st.header('🔄 Controle de DAGs')

    # Simulação de DAGs disponíveis
    dags = [
        {
            'id': 'ecommerce_etl_pipeline',
            'name': 'Pipeline ETL E-commerce',
            'status': 'active',
        },
        {
            'id': 'data_quality_check',
            'name': 'Verificação de Qualidade',
            'status': 'active',
        },
        {
            'id': 'api_data_ingestion',
            'name': 'Ingestão de APIs',
            'status': 'paused',
        },
        {
            'id': 'minio_data_lake',
            'name': 'Pipeline Data Lake',
            'status': 'active',
        },
    ]

    col1, col2 = st.columns([2, 1])

    with col1:
        st.subheader('📋 DAGs Disponíveis')

        for dag in dags:
            with st.container():
                col_name, col_status, col_action = st.columns([3, 1, 1])

                col_name.write(f"**{dag['name']}**")
                col_name.caption(f"ID: {dag['id']}")

                if dag['status'] == 'active':
                    col_status.success('✅ Ativo')
                else:
                    col_status.warning('⏸️ Pausado')

                if col_action.button('▶️ Executar', key=dag['id']):
                    trigger_dag(dag['id'])

                st.markdown('---')

    with col2:
        st.subheader('📊 Estatísticas')
        st.metric(
            'DAGs Ativas', len([d for d in dags if d['status'] == 'active'])
        )
        st.metric(
            'DAGs Pausadas', len([d for d in dags if d['status'] == 'paused'])
        )

        st.info(
            '💡 **Dica**: Use o Airflow UI em http://localhost:8080 para controle avançado das DAGs'
        )


def show_data_layers():
    """Visualiza dados nas diferentes camadas"""
    st.header('📈 Dados por Camada')

    # Seleção de camada
    layer = st.selectbox(
        'Escolha a camada:', ['Raw', 'Staging', 'Processed', 'Analytics']
    )

    try:
        if layer == 'Raw':
            st.subheader('🗃️ Camada Raw')

            # Tabela sales_transactions
            st.write('**Sales Transactions**')
            data, columns = execute_query(
                'SELECT * FROM raw.sales_transactions ORDER BY created_at DESC LIMIT 100'
            )

            if data and columns:
                df = pd.DataFrame(data, columns=columns)
                st.dataframe(df, use_container_width=True)

                # Estatísticas
                col1, col2, col3 = st.columns(3)
                col1.metric('Total Registros', len(df))
                col2.metric(
                    'Última Atualização',
                    df['created_at'].max() if not df.empty else 'N/A',
                )
                col3.metric(
                    'Revenue Total',
                    f"R$ {df['total_amount'].sum():,.2f}"
                    if not df.empty
                    else 'R$ 0,00',
                )
            else:
                st.info('Nenhum dado encontrado na camada Raw')

        elif layer == 'Staging':
            st.subheader('🔄 Camada Staging')
            data, columns = execute_query(
                'SELECT * FROM staging.sales_clean ORDER BY processed_at DESC LIMIT 100'
            )

            if data and columns:
                df = pd.DataFrame(data, columns=columns)
                st.dataframe(df, use_container_width=True)
                st.metric('Registros Limpos', len(df))
            else:
                st.info('Nenhum dado encontrado na camada Staging')

        elif layer == 'Processed':
            st.subheader('⚙️ Camada Processed')

            # Dimensões
            st.write('**Dimensão Clientes**')
            data, columns = execute_query(
                'SELECT * FROM processed.dim_customers LIMIT 50'
            )
            if data and columns:
                df = pd.DataFrame(data, columns=columns)
                st.dataframe(df, use_container_width=True)

            st.write('**Dimensão Produtos**')
            data, columns = execute_query(
                'SELECT * FROM processed.dim_products LIMIT 50'
            )
            if data and columns:
                df = pd.DataFrame(data, columns=columns)
                st.dataframe(df, use_container_width=True)

            st.write('**Fato Vendas**')
            data, columns = execute_query(
                'SELECT * FROM processed.fact_sales LIMIT 50'
            )
            if data and columns:
                df = pd.DataFrame(data, columns=columns)
                st.dataframe(df, use_container_width=True)

        elif layer == 'Analytics':
            st.subheader('📊 Camada Analytics')

            # Resumo diário
            data, columns = execute_query(
                'SELECT * FROM analytics.daily_sales_summary ORDER BY summary_date DESC'
            )
            if data and columns:
                df = pd.DataFrame(data, columns=columns)
                st.dataframe(df, use_container_width=True)

                if not df.empty:
                    fig = px.line(
                        df,
                        x='summary_date',
                        y='total_revenue',
                        title='Revenue ao Longo do Tempo',
                    )
                    st.plotly_chart(fig, use_container_width=True)
            else:
                st.info('Nenhum dado encontrado na camada Analytics')

    except Exception as e:
        st.error(f'Erro ao buscar dados: {e}')


def show_faker_generator():
    """Interface para gerar dados com Faker"""
    st.header('🎲 Gerador de Dados com Faker')

    st.info(
        '💡 Esta interface permite gerar dados sintéticos para testar o pipeline'
    )

    col1, col2 = st.columns(2)

    with col1:
        st.subheader('⚙️ Configurações')

        num_records = st.slider('Número de registros', 10, 1000, 100)

        categories = st.multiselect(
            'Categorias de produtos',
            [
                'Electronics',
                'Clothing',
                'Books',
                'Home & Garden',
                'Sports',
                'Toys',
            ],
            default=['Electronics', 'Clothing', 'Books'],
        )

        payment_methods = st.multiselect(
            'Métodos de pagamento',
            ['Credit Card', 'Debit Card', 'PayPal', 'Bank Transfer', 'Cash'],
            default=['Credit Card', 'Debit Card', 'PayPal'],
        )

        date_range = st.date_input(
            'Período das transações',
            value=[
                datetime.now().date() - timedelta(days=30),
                datetime.now().date(),
            ],
            max_value=datetime.now().date(),
        )

    with col2:
        st.subheader('🎯 Ação')

        if st.button(
            '🚀 Gerar Dados', type='primary', use_container_width=True
        ):

            if not categories or not payment_methods:
                st.error(
                    'Selecione pelo menos uma categoria e um método de pagamento'
                )
                return

            # Gerar dados simulados
            progress_bar = st.progress(0)
            status_text = st.empty()

            try:
                import random
                import uuid

                status_text.text('Gerando dados...')

                conn = get_db_connection()
                if not conn:
                    st.error('Não foi possível conectar ao banco de dados')
                    return

                cursor = conn.cursor()

                for i in range(num_records):
                    # Simular dados
                    transaction_id = f'FAKE_{uuid.uuid4().hex[:8].upper()}'
                    customer_id = f'CUST_{random.randint(1000, 9999)}'
                    product_id = f'PROD_{random.randint(100, 999)}'

                    # Data aleatória no período
                    start_date = datetime.combine(
                        date_range[0], datetime.min.time()
                    )
                    end_date = datetime.combine(
                        date_range[1], datetime.max.time()
                    )
                    random_date = start_date + timedelta(
                        seconds=random.randint(
                            0, int((end_date - start_date).total_seconds())
                        )
                    )

                    # Outros campos
                    category = random.choice(categories)
                    payment_method = random.choice(payment_methods)
                    quantity = random.randint(1, 5)
                    unit_price = round(random.uniform(10, 500), 2)
                    total_amount = round(quantity * unit_price, 2)

                    # Produtos fake baseados na categoria
                    product_names = {
                        'Electronics': [
                            'Smartphone',
                            'Laptop',
                            'Tablet',
                            'Headphones',
                            'Camera',
                        ],
                        'Clothing': [
                            'T-shirt',
                            'Jeans',
                            'Dress',
                            'Shoes',
                            'Jacket',
                        ],
                        'Books': [
                            'Novel',
                            'Textbook',
                            'Magazine',
                            'Comic',
                            'Biography',
                        ],
                        'Home & Garden': [
                            'Chair',
                            'Table',
                            'Plant',
                            'Lamp',
                            'Vase',
                        ],
                        'Sports': [
                            'Ball',
                            'Racket',
                            'Bike',
                            'Weights',
                            'Shoes',
                        ],
                        'Toys': ['Doll', 'Car', 'Puzzle', 'Game', 'Robot'],
                    }

                    product_name = f"{random.choice(product_names[category])} {random.choice(['Pro', 'Max', 'Ultra', 'Plus', 'Standard'])}"

                    # Inserir no banco
                    cursor.execute(
                        """
                        INSERT INTO raw.sales_transactions 
                        (transaction_id, transaction_date, customer_id, product_id, product_name, 
                         category, quantity, unit_price, total_amount, payment_method, status)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                        (
                            transaction_id,
                            random_date,
                            customer_id,
                            product_id,
                            product_name,
                            category,
                            quantity,
                            unit_price,
                            total_amount,
                            payment_method,
                            'Completed',
                        ),
                    )

                    # Atualizar progresso
                    progress_bar.progress((i + 1) / num_records)
                    status_text.text(f'Gerando registro {i + 1}/{num_records}')

                conn.commit()
                cursor.close()

                status_text.text('✅ Dados gerados com sucesso!')
                st.success(
                    f'🎉 {num_records} registros inseridos na camada Raw!'
                )

                # Auto-refresh para mostrar novos dados
                time.sleep(2)
                st.rerun()

            except Exception as e:
                st.error(f'Erro ao gerar dados: {e}')

    # Instruções
    st.markdown('---')
    st.subheader('📖 Como usar')
    st.markdown(
        """
    1. **Configure** o número de registros e parâmetros desejados
    2. **Clique** em "Gerar Dados" para criar transações sintéticas
    3. **Visualize** os dados gerados na aba "Dados"
    4. **Execute** as DAGs na aba "DAGs" para processar os dados
    5. **Monitore** o progresso na aba "Visão Geral"
    """
    )


if __name__ == '__main__':
    main()
