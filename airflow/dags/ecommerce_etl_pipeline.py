"""
ETL Pipeline Example - E-commerce Sales Data
This DAG demonstrates a complete ETL process:
1. Generate/Extract sample data
2. Load to raw layer
3. Transform and clean data
4. Load to staging
5. Process to dimensional model
6. Create analytics aggregations
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
import pandas as pd
import random
from faker import Faker

# Default arguments
default_args = {
    'owner': 'data_engineer',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Initialize DAG
dag = DAG(
    'ecommerce_etl_pipeline',
    default_args=default_args,
    description='Complete ETL pipeline for e-commerce data',
    schedule_interval='@daily',
    catchup=False,
    tags=['etl', 'ecommerce', 'example'],
)

def generate_sample_data(**context):
    """Generate sample e-commerce data"""
    fake = Faker()
    
    # Generate sample transactions
    num_transactions = random.randint(50, 200)
    transactions = []
    
    categories = ['Electronics', 'Clothing', 'Books', 'Home & Garden', 'Sports', 'Toys']
    payment_methods = ['Credit Card', 'Debit Card', 'PayPal', 'Bank Transfer']
    statuses = ['Completed', 'Pending', 'Cancelled']
    
    for _ in range(num_transactions):
        transaction = {
            'transaction_id': fake.uuid4(),
            'transaction_date': fake.date_time_between(start_date='-1d', end_date='now'),
            'customer_id': f'CUST_{random.randint(1000, 9999)}',
            'product_id': f'PROD_{random.randint(100, 999)}',
            'product_name': fake.catch_phrase(),
            'category': random.choice(categories),
            'quantity': random.randint(1, 10),
            'unit_price': round(random.uniform(10, 500), 2),
            'payment_method': random.choice(payment_methods),
            'status': random.choices(statuses, weights=[0.8, 0.15, 0.05])[0]
        }
        transaction['total_amount'] = round(transaction['quantity'] * transaction['unit_price'], 2)
        transactions.append(transaction)
    
    # Save to CSV
    df = pd.DataFrame(transactions)
    df.to_csv('/opt/airflow/data/raw/sales_transactions.csv', index=False)
    
    print(f"Generated {num_transactions} sample transactions")
    return num_transactions

def load_to_raw_layer(**context):
    """Load CSV data to raw layer in PostgreSQL"""
    df = pd.read_csv('/opt/airflow/data/raw/sales_transactions.csv')
    
    # Connect to PostgreSQL
    hook = PostgresHook(postgres_conn_id='postgres_default')
    engine = hook.get_sqlalchemy_engine()
    
    # Load to raw table
    df.to_sql('sales_transactions', engine, schema='raw', if_exists='append', index=False)
    
    print(f"Loaded {len(df)} records to raw.sales_transactions")

def transform_and_clean(**context):
    """Transform and clean data, load to staging"""
    hook = PostgresHook(postgres_conn_id='postgres_default')
    
    # Extract from raw
    sql = """
        SELECT DISTINCT ON (transaction_id)
            transaction_id,
            transaction_date,
            customer_id,
            product_id,
            product_name,
            category,
            quantity,
            unit_price,
            total_amount,
            payment_method,
            status
        FROM raw.sales_transactions
        WHERE transaction_date >= CURRENT_DATE - INTERVAL '2 days'
          AND status != 'Cancelled'
          AND quantity > 0
          AND total_amount > 0
        ORDER BY transaction_id, created_at DESC
    """
    
    df = hook.get_pandas_df(sql)
    
    # Clean data
    df['product_name'] = df['product_name'].str.strip().str.title()
    df['category'] = df['category'].str.strip()
    
    # Load to staging
    engine = hook.get_sqlalchemy_engine()
    df.to_sql('sales_clean', engine, schema='staging', if_exists='replace', index=False)
    
    print(f"Transformed and loaded {len(df)} clean records to staging")

def load_dimensions(**context):
    """Load dimension tables"""
    hook = PostgresHook(postgres_conn_id='postgres_default')
    
    # Load dim_customers
    sql_customers = """
        INSERT INTO processed.dim_customers (customer_id, customer_name, email, city, state, country, registration_date)
        SELECT DISTINCT
            customer_id,
            'Customer ' || customer_id as customer_name,
            customer_id || '@email.com' as email,
            'Sample City' as city,
            'Sample State' as state,
            'Brazil' as country,
            CURRENT_DATE - (random() * 365)::INTEGER as registration_date
        FROM staging.sales_clean
        WHERE customer_id NOT IN (SELECT customer_id FROM processed.dim_customers)
    """
    
    # Load dim_products
    sql_products = """
        INSERT INTO processed.dim_products (product_id, product_name, category)
        SELECT DISTINCT
            product_id,
            product_name,
            category
        FROM staging.sales_clean
        WHERE product_id NOT IN (SELECT product_id FROM processed.dim_products)
        ON CONFLICT (product_id) DO UPDATE
        SET product_name = EXCLUDED.product_name,
            category = EXCLUDED.category,
            updated_at = CURRENT_TIMESTAMP
    """
    
    hook.run(sql_customers)
    hook.run(sql_products)
    
    print("Dimension tables updated")

def load_fact_table(**context):
    """Load fact table"""
    hook = PostgresHook(postgres_conn_id='postgres_default')
    
    sql = """
        INSERT INTO processed.fact_sales (
            transaction_id, date_key, customer_key, product_key,
            quantity, unit_price, total_amount, payment_method, status
        )
        SELECT 
            s.transaction_id,
            TO_CHAR(s.transaction_date, 'YYYYMMDD')::INTEGER as date_key,
            c.customer_key,
            p.product_key,
            s.quantity,
            s.unit_price,
            s.total_amount,
            s.payment_method,
            s.status
        FROM staging.sales_clean s
        JOIN processed.dim_customers c ON s.customer_id = c.customer_id
        JOIN processed.dim_products p ON s.product_id = p.product_id
        WHERE s.transaction_id NOT IN (SELECT transaction_id FROM processed.fact_sales)
    """
    
    hook.run(sql)
    print("Fact table loaded")

def create_analytics(**context):
    """Create analytics aggregations"""
    hook = PostgresHook(postgres_conn_id='postgres_default')
    
    # Daily sales summary
    sql_daily = """
        INSERT INTO analytics.daily_sales_summary (
            summary_date, total_transactions, total_revenue, 
            total_quantity, avg_transaction_value, unique_customers
        )
        SELECT 
            d.full_date,
            COUNT(*) as total_transactions,
            SUM(f.total_amount) as total_revenue,
            SUM(f.quantity) as total_quantity,
            AVG(f.total_amount) as avg_transaction_value,
            COUNT(DISTINCT f.customer_key) as unique_customers
        FROM processed.fact_sales f
        JOIN processed.dim_date d ON f.date_key = d.date_key
        WHERE d.full_date >= CURRENT_DATE - INTERVAL '1 day'
        GROUP BY d.full_date
        ON CONFLICT (summary_date) DO UPDATE
        SET total_transactions = EXCLUDED.total_transactions,
            total_revenue = EXCLUDED.total_revenue,
            total_quantity = EXCLUDED.total_quantity,
            avg_transaction_value = EXCLUDED.avg_transaction_value,
            unique_customers = EXCLUDED.unique_customers,
            created_at = CURRENT_TIMESTAMP
    """
    
    # Product performance
    sql_product = """
        INSERT INTO analytics.product_performance (
            product_id, summary_date, category, total_quantity, 
            total_revenue, transaction_count
        )
        SELECT 
            p.product_id,
            d.full_date,
            p.category,
            SUM(f.quantity) as total_quantity,
            SUM(f.total_amount) as total_revenue,
            COUNT(*) as transaction_count
        FROM processed.fact_sales f
        JOIN processed.dim_products p ON f.product_key = p.product_key
        JOIN processed.dim_date d ON f.date_key = d.date_key
        WHERE d.full_date >= CURRENT_DATE - INTERVAL '1 day'
        GROUP BY p.product_id, d.full_date, p.category
        ON CONFLICT (product_id, summary_date) DO UPDATE
        SET total_quantity = EXCLUDED.total_quantity,
            total_revenue = EXCLUDED.total_revenue,
            transaction_count = EXCLUDED.transaction_count
    """
    
    # Customer metrics
    sql_customer = """
        INSERT INTO analytics.customer_metrics (
            customer_id, total_purchases, total_spent, avg_order_value,
            first_purchase_date, last_purchase_date, customer_lifetime_days
        )
        SELECT 
            c.customer_id,
            COUNT(*) as total_purchases,
            SUM(f.total_amount) as total_spent,
            AVG(f.total_amount) as avg_order_value,
            MIN(d.full_date) as first_purchase_date,
            MAX(d.full_date) as last_purchase_date,
            MAX(d.full_date) - MIN(d.full_date) as customer_lifetime_days
        FROM processed.fact_sales f
        JOIN processed.dim_customers c ON f.customer_key = c.customer_key
        JOIN processed.dim_date d ON f.date_key = d.date_key
        GROUP BY c.customer_id
        ON CONFLICT (customer_id) DO UPDATE
        SET total_purchases = EXCLUDED.total_purchases,
            total_spent = EXCLUDED.total_spent,
            avg_order_value = EXCLUDED.avg_order_value,
            last_purchase_date = EXCLUDED.last_purchase_date,
            customer_lifetime_days = EXCLUDED.customer_lifetime_days,
            updated_at = CURRENT_TIMESTAMP
    """
    
    hook.run(sql_daily)
    hook.run(sql_product)
    hook.run(sql_customer)
    
    print("Analytics aggregations created")

# Define tasks
t1 = PythonOperator(
    task_id='generate_sample_data',
    python_callable=generate_sample_data,
    dag=dag,
)

t2 = PythonOperator(
    task_id='load_to_raw_layer',
    python_callable=load_to_raw_layer,
    dag=dag,
)

t3 = PythonOperator(
    task_id='transform_and_clean',
    python_callable=transform_and_clean,
    dag=dag,
)

t4 = PythonOperator(
    task_id='load_dimensions',
    python_callable=load_dimensions,
    dag=dag,
)

t5 = PythonOperator(
    task_id='load_fact_table',
    python_callable=load_fact_table,
    dag=dag,
)

t6 = PythonOperator(
    task_id='create_analytics',
    python_callable=create_analytics,
    dag=dag,
)

# Define task dependencies
t1 >> t2 >> t3 >> t4 >> t5 >> t6
