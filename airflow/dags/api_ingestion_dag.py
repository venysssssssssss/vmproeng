"""
API Data Ingestion DAG
Simulates fetching data from external API and loading to data lake
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
import pandas as pd
import json
from faker import Faker
import random

default_args = {
    'owner': 'data_engineer',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=3),
}

dag = DAG(
    'api_data_ingestion',
    default_args=default_args,
    description='Ingest data from API and load to raw layer',
    schedule_interval='0 */6 * * *',  # Every 6 hours
    catchup=False,
    tags=['ingestion', 'api', 'raw'],
)

def fetch_api_data(**context):
    """Simulate API data fetch"""
    fake = Faker()
    
    # Simulate customer data from CRM API
    num_customers = random.randint(10, 50)
    customers = []
    
    for _ in range(num_customers):
        customer = {
            'customer_id': f'CUST_{random.randint(1000, 9999)}',
            'customer_name': fake.name(),
            'email': fake.email(),
            'phone': fake.phone_number(),
            'city': fake.city(),
            'state': fake.state(),
            'country': 'Brazil',
            'registration_date': fake.date_between(start_date='-2y', end_date='today').isoformat()
        }
        customers.append(customer)
    
    # Save to JSON (simulating API response)
    with open('/opt/airflow/data/raw/customers_api.json', 'w') as f:
        json.dump(customers, f, indent=2)
    
    print(f"Fetched {num_customers} customers from API")
    return num_customers

def load_customers_to_db(**context):
    """Load customer data to database"""
    
    # Read JSON data
    with open('/opt/airflow/data/raw/customers_api.json', 'r') as f:
        customers = json.load(f)
    
    df = pd.DataFrame(customers)
    
    # Connect to database
    hook = PostgresHook(postgres_conn_id='postgres_default')
    engine = hook.get_sqlalchemy_engine()
    
    # Load to raw.customer_data
    df.to_sql('customer_data', engine, schema='raw', if_exists='append', index=False)
    
    print(f"Loaded {len(df)} customers to raw.customer_data")

def update_customer_dimensions(**context):
    """Update customer dimension table"""
    hook = PostgresHook(postgres_conn_id='postgres_default')
    
    sql = """
        INSERT INTO processed.dim_customers (
            customer_id, customer_name, email, phone, 
            city, state, country, registration_date
        )
        SELECT DISTINCT
            customer_id,
            customer_name,
            email,
            phone,
            city,
            state,
            country,
            registration_date::DATE
        FROM raw.customer_data
        WHERE created_at >= CURRENT_TIMESTAMP - INTERVAL '1 day'
        ON CONFLICT (customer_id) DO UPDATE
        SET customer_name = EXCLUDED.customer_name,
            email = EXCLUDED.email,
            phone = EXCLUDED.phone,
            city = EXCLUDED.city,
            state = EXCLUDED.state,
            country = EXCLUDED.country,
            updated_at = CURRENT_TIMESTAMP
    """
    
    hook.run(sql)
    print("Customer dimension updated")

# Define tasks
t1 = PythonOperator(
    task_id='fetch_api_data',
    python_callable=fetch_api_data,
    dag=dag,
)

t2 = PythonOperator(
    task_id='load_to_database',
    python_callable=load_customers_to_db,
    dag=dag,
)

t3 = PythonOperator(
    task_id='update_dimensions',
    python_callable=update_customer_dimensions,
    dag=dag,
)

# Task dependencies
t1 >> t2 >> t3
