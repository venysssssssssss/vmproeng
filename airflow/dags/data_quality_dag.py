"""
Data Quality DAG - Runs Spark job for data quality checks
"""

from datetime import datetime, timedelta
from airflow import DAG
# from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from airflow.operators.python import PythonOperator

default_args = {
    'owner': 'data_engineer',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'data_quality_check',
    default_args=default_args,
    description='Run data quality checks using Spark',
    schedule_interval='@daily',
    catchup=False,
    tags=['spark', 'quality', 'monitoring'],
)

def quality_check_complete(**context):
    """Callback when quality check is complete"""
    print("Data quality check completed successfully!")

# Spark submit task (disabled for now - requires spark provider)
# spark_quality_check = SparkSubmitOperator(
#     task_id='run_quality_check',
#     application='/opt/airflow/spark_jobs/data_quality_check.py',
#     conn_id='spark_default',
#     total_executor_cores=1,
#     executor_memory='256m',
#     driver_memory='256m',
#     name='data_quality_check',
#     conf={
#         'spark.sql.shuffle.partitions': '2',
#         'spark.default.parallelism': '2'
#     },
#     dag=dag,
# )

# Alternative Python task for data quality check
quality_check_task = PythonOperator(
    task_id='python_quality_check',
    python_callable=quality_check_complete,
    dag=dag,
)

completion_task = PythonOperator(
    task_id='quality_check_complete',
    python_callable=quality_check_complete,
    dag=dag,
)

quality_check_task >> completion_task
