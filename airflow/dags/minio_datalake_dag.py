"""
MinIO Integration - Upload data to object storage
"""

import json
import os
from datetime import datetime, timedelta

from airflow.operators.python import PythonOperator
from minio import Minio
from minio.error import S3Error

from airflow import DAG

default_args = {
    'owner': 'data_engineer',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'minio_data_lake',
    default_args=default_args,
    description='Upload processed data to MinIO data lake',
    schedule_interval='@daily',
    catchup=False,
    tags=['minio', 'datalake', 'storage'],
)


def create_minio_client():
    """Create MinIO client"""
    return Minio(
        'minio:9000',
        access_key='minioadmin',
        secret_key='minioadmin',
        secure=False,
    )


def create_buckets(**context):
    """Create necessary buckets in MinIO"""
    client = create_minio_client()

    buckets = ['raw-data', 'processed-data', 'analytics', 'backups']

    for bucket in buckets:
        try:
            if not client.bucket_exists(bucket):
                client.make_bucket(bucket)
                print(f'Created bucket: {bucket}')
            else:
                print(f'Bucket already exists: {bucket}')
        except S3Error as e:
            print(f'Error creating bucket {bucket}: {e}')


def upload_to_datalake(**context):
    """Upload data files to MinIO"""
    client = create_minio_client()

    # Upload sample data
    data_file = '/opt/airflow/data/raw/sales_transactions.csv'

    if os.path.exists(data_file):
        try:
            # Upload to raw-data bucket
            client.fput_object(
                'raw-data',
                f'sales/{datetime.now().strftime("%Y/%m/%d")}/transactions.csv',
                data_file,
            )
            print(f'Uploaded {data_file} to MinIO')
        except S3Error as e:
            print(f'Error uploading file: {e}')
    else:
        print(f'File not found: {data_file}')


def list_objects(**context):
    """List objects in MinIO buckets"""
    client = create_minio_client()

    buckets = client.list_buckets()

    for bucket in buckets:
        print(f'\nBucket: {bucket.name}')
        objects = client.list_objects(bucket.name, recursive=True)
        for obj in objects:
            print(f'  - {obj.object_name} ({obj.size} bytes)')


# Define tasks
t1 = PythonOperator(
    task_id='create_buckets',
    python_callable=create_buckets,
    dag=dag,
)

t2 = PythonOperator(
    task_id='upload_to_datalake',
    python_callable=upload_to_datalake,
    dag=dag,
)

t3 = PythonOperator(
    task_id='list_objects',
    python_callable=list_objects,
    dag=dag,
)

# Task dependencies
t1 >> t2 >> t3
