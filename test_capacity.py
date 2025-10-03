#!/usr/bin/env python3
"""
Script de Teste de Capacidade - Data Engineering Pipeline
Testa a capacidade máxima de ingestão com 900MB de RAM
"""

import psycopg2
import time
import os
from datetime import datetime, timedelta
import random
import uuid

# Configuração do banco
DB_CONFIG = {
    'host': 'localhost',
    'database': 'datawarehouse',
    'user': 'postgres',
    'password': 'postgres',
    'port': 5432
}

def get_db_connection():
    """Conecta ao PostgreSQL"""
    return psycopg2.connect(**DB_CONFIG)

def clear_raw_data():
    """Limpa dados da camada raw"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    print("🧹 Limpando dados antigos...")
    cursor.execute("TRUNCATE TABLE raw.transactions_raw CASCADE")
    cursor.execute("TRUNCATE TABLE raw.customers_raw CASCADE")
    cursor.execute("TRUNCATE TABLE raw.products_raw CASCADE")
    conn.commit()
    cursor.close()
    conn.close()
    print("✅ Dados limpos\n")

def get_row_counts():
    """Retorna contagem de registros em cada camada"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    counts = {}
    tables = [
        ('raw.transactions_raw', 'Raw Transactions'),
        ('raw.customers_raw', 'Raw Customers'),
        ('raw.products_raw', 'Raw Products'),
        ('staging.transactions_staging', 'Staging Transactions'),
        ('processed.fact_sales', 'Fact Sales'),
        ('analytics.sales_summary', 'Analytics Summary')
    ]
    
    for table, label in tables:
        try:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            counts[label] = cursor.fetchone()[0]
        except:
            counts[label] = 0
    
    cursor.close()
    conn.close()
    return counts

def generate_batch(batch_size, batch_num):
    """Gera um batch de dados simulados"""
    transactions = []
    customers = set()
    products = set()
    
    categories = ['Electronics', 'Clothing', 'Food', 'Books', 'Home & Garden']
    payment_methods = ['Credit Card', 'Debit Card', 'PayPal', 'Bank Transfer', 'Cash']
    
    start_date = datetime.now() - timedelta(days=365)
    end_date = datetime.now()
    
    for i in range(batch_size):
        # IDs únicos
        transaction_id = f"TEST_{batch_num}_{uuid.uuid4().hex[:8].upper()}"
        customer_id = f"CUST_{random.randint(1000, 9999)}"
        product_id = f"PROD_{random.randint(100, 999)}"
        
        customers.add(customer_id)
        products.add(product_id)
        
        # Data aleatória
        random_date = start_date + timedelta(
            seconds=random.randint(0, int((end_date - start_date).total_seconds()))
        )
        
        # Dados da transação
        quantity = random.randint(1, 10)
        unit_price = round(random.uniform(10, 1000), 2)
        total_amount = round(quantity * unit_price, 2)
        
        transactions.append({
            'transaction_id': transaction_id,
            'customer_id': customer_id,
            'product_id': product_id,
            'transaction_date': random_date,
            'quantity': quantity,
            'unit_price': unit_price,
            'total_amount': total_amount,
            'payment_method': random.choice(payment_methods),
            'category': random.choice(categories)
        })
    
    return transactions, customers, products

def insert_batch(transactions, customers, products):
    """Insere um batch no banco de dados"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Inserir clientes
        for customer_id in customers:
            cursor.execute("""
                INSERT INTO raw.customers_raw (customer_id, name, email, phone, address, city, country, signup_date)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (customer_id) DO NOTHING
            """, (
                customer_id,
                f"Customer {customer_id}",
                f"{customer_id.lower()}@example.com",
                f"+55 11 {random.randint(10000, 99999)}-{random.randint(1000, 9999)}",
                f"Street {random.randint(1, 1000)}",
                random.choice(['São Paulo', 'Rio de Janeiro', 'Brasília', 'Belo Horizonte']),
                'Brazil',
                datetime.now() - timedelta(days=random.randint(1, 730))
            ))
        
        # Inserir produtos
        for product_id in products:
            cursor.execute("""
                INSERT INTO raw.products_raw (product_id, name, category, price, stock, supplier)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT (product_id) DO NOTHING
            """, (
                product_id,
                f"Product {product_id}",
                random.choice(['Electronics', 'Clothing', 'Food', 'Books', 'Home & Garden']),
                round(random.uniform(10, 1000), 2),
                random.randint(0, 1000),
                f"Supplier {random.randint(1, 50)}"
            ))
        
        # Inserir transações
        for t in transactions:
            cursor.execute("""
                INSERT INTO raw.transactions_raw 
                (transaction_id, customer_id, product_id, transaction_date, quantity, 
                 unit_price, total_amount, payment_method, category)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                t['transaction_id'], t['customer_id'], t['product_id'],
                t['transaction_date'], t['quantity'], t['unit_price'],
                t['total_amount'], t['payment_method'], t['category']
            ))
        
        conn.commit()
        return True
    except Exception as e:
        conn.rollback()
        print(f"❌ Erro ao inserir batch: {e}")
        return False
    finally:
        cursor.close()
        conn.close()

def run_capacity_test(batch_size=1000, max_batches=100, delay=2):
    """
    Executa teste de capacidade
    
    Args:
        batch_size: Número de registros por batch
        max_batches: Número máximo de batches
        delay: Delay entre batches (segundos)
    """
    print("=" * 70)
    print("🚀 TESTE DE CAPACIDADE - DATA ENGINEERING PIPELINE")
    print("=" * 70)
    print(f"Configuração:")
    print(f"  • Batch Size: {batch_size:,} registros")
    print(f"  • Max Batches: {max_batches}")
    print(f"  • Delay: {delay}s entre batches")
    print(f"  • Total Máximo: {batch_size * max_batches:,} registros")
    print("=" * 70)
    print()
    
    # Limpar dados antigos
    clear_raw_data()
    
    # Estatísticas
    total_inserted = 0
    batch_times = []
    start_time = time.time()
    
    print("📊 Iniciando ingestão de dados...\n")
    
    for batch_num in range(1, max_batches + 1):
        batch_start = time.time()
        
        # Gerar dados
        print(f"Batch {batch_num}/{max_batches}: Gerando {batch_size:,} registros...", end=" ", flush=True)
        transactions, customers, products = generate_batch(batch_size, batch_num)
        
        # Inserir dados
        success = insert_batch(transactions, customers, products)
        
        batch_time = time.time() - batch_start
        batch_times.append(batch_time)
        
        if success:
            total_inserted += len(transactions)
            print(f"✅ ({batch_time:.2f}s) - Total: {total_inserted:,}")
        else:
            print(f"❌ FALHOU")
            break
        
        # Mostrar estatísticas a cada 10 batches
        if batch_num % 10 == 0:
            counts = get_row_counts()
            elapsed = time.time() - start_time
            rate = total_inserted / elapsed
            
            print(f"\n📈 Estatísticas (após {batch_num} batches):")
            print(f"   • Total inserido: {total_inserted:,} registros")
            print(f"   • Tempo decorrido: {elapsed:.1f}s")
            print(f"   • Taxa: {rate:.0f} registros/s")
            print(f"   • Tempo médio/batch: {sum(batch_times)/len(batch_times):.2f}s")
            for table, count in counts.items():
                if count > 0:
                    print(f"   • {table}: {count:,}")
            print()
        
        # Delay entre batches
        if batch_num < max_batches:
            time.sleep(delay)
    
    # Relatório final
    total_time = time.time() - start_time
    
    print("\n" + "=" * 70)
    print("📊 RELATÓRIO FINAL")
    print("=" * 70)
    print(f"Total de registros inseridos: {total_inserted:,}")
    print(f"Tempo total: {total_time:.1f}s ({total_time/60:.1f} minutos)")
    print(f"Taxa média: {total_inserted/total_time:.0f} registros/s")
    print(f"Tempo médio por batch: {sum(batch_times)/len(batch_times):.2f}s")
    print(f"Batch mais rápido: {min(batch_times):.2f}s")
    print(f"Batch mais lento: {max(batch_times):.2f}s")
    
    print("\n📊 Contagem por camada:")
    counts = get_row_counts()
    for table, count in counts.items():
        print(f"   • {table}: {count:,}")
    
    print("\n" + "=" * 70)
    print("✅ Teste concluído!")
    print("=" * 70)

if __name__ == "__main__":
    import sys
    
    # Parâmetros via linha de comando
    batch_size = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
    max_batches = int(sys.argv[2]) if len(sys.argv) > 2 else 50
    delay = int(sys.argv[3]) if len(sys.argv) > 3 else 2
    
    try:
        run_capacity_test(batch_size, max_batches, delay)
    except KeyboardInterrupt:
        print("\n\n⚠️  Teste interrompido pelo usuário")
        counts = get_row_counts()
        print("\n📊 Contagem atual:")
        for table, count in counts.items():
            if count > 0:
                print(f"   • {table}: {count:,}")
    except Exception as e:
        print(f"\n❌ Erro: {e}")
