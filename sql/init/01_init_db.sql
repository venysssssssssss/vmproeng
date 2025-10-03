-- Create airflow database
SELECT 'CREATE DATABASE airflow'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'airflow')\gexec

-- Create metabase database  
SELECT 'CREATE DATABASE metabase'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'metabase')\gexec

-- Create data warehouse schemas
\c datawarehouse;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS processed;
CREATE SCHEMA IF NOT EXISTS analytics;

-- Raw layer - E-commerce example
CREATE TABLE IF NOT EXISTS raw.sales_transactions (
    transaction_id VARCHAR(100),
    transaction_date TIMESTAMP,
    customer_id VARCHAR(100),
    product_id VARCHAR(100),
    product_name VARCHAR(255),
    category VARCHAR(100),
    quantity INTEGER,
    unit_price DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),
    payment_method VARCHAR(50),
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS raw.customer_data (
    customer_id VARCHAR(100),
    customer_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    registration_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staging layer
CREATE TABLE IF NOT EXISTS staging.sales_clean (
    transaction_id VARCHAR(100) PRIMARY KEY,
    transaction_date TIMESTAMP,
    customer_id VARCHAR(100),
    product_id VARCHAR(100),
    product_name VARCHAR(255),
    category VARCHAR(100),
    quantity INTEGER,
    unit_price DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),
    payment_method VARCHAR(50),
    status VARCHAR(50),
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Processed layer - Dimensional Model
CREATE TABLE IF NOT EXISTS processed.dim_customers (
    customer_key SERIAL PRIMARY KEY,
    customer_id VARCHAR(100) UNIQUE,
    customer_name VARCHAR(255),
    email VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    registration_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS processed.dim_products (
    product_key SERIAL PRIMARY KEY,
    product_id VARCHAR(100) UNIQUE,
    product_name VARCHAR(255),
    category VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS processed.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE,
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    month_name VARCHAR(20),
    week INTEGER,
    day_of_month INTEGER,
    day_of_week INTEGER,
    day_name VARCHAR(20),
    is_weekend BOOLEAN
);

CREATE TABLE IF NOT EXISTS processed.fact_sales (
    sale_key SERIAL PRIMARY KEY,
    transaction_id VARCHAR(100) UNIQUE,
    date_key INTEGER REFERENCES processed.dim_date(date_key),
    customer_key INTEGER REFERENCES processed.dim_customers(customer_key),
    product_key INTEGER REFERENCES processed.dim_products(product_key),
    quantity INTEGER,
    unit_price DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),
    payment_method VARCHAR(50),
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Analytics layer - Aggregations
CREATE TABLE IF NOT EXISTS analytics.daily_sales_summary (
    summary_date DATE PRIMARY KEY,
    total_transactions INTEGER,
    total_revenue DECIMAL(15, 2),
    total_quantity INTEGER,
    avg_transaction_value DECIMAL(10, 2),
    unique_customers INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS analytics.product_performance (
    product_id VARCHAR(100),
    summary_date DATE,
    category VARCHAR(100),
    total_quantity INTEGER,
    total_revenue DECIMAL(15, 2),
    transaction_count INTEGER,
    PRIMARY KEY (product_id, summary_date)
);

CREATE TABLE IF NOT EXISTS analytics.customer_metrics (
    customer_id VARCHAR(100),
    total_purchases INTEGER,
    total_spent DECIMAL(15, 2),
    avg_order_value DECIMAL(10, 2),
    first_purchase_date DATE,
    last_purchase_date DATE,
    customer_lifetime_days INTEGER,
    PRIMARY KEY (customer_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_sales_date ON raw.sales_transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_sales_customer ON raw.sales_transactions(customer_id);
CREATE INDEX IF NOT EXISTS idx_fact_sales_date ON processed.fact_sales(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_sales_customer ON processed.fact_sales(customer_key);
CREATE INDEX IF NOT EXISTS idx_fact_sales_product ON processed.fact_sales(product_key);

-- Populate dim_date with sample data (2024-2025)
INSERT INTO processed.dim_date (date_key, full_date, year, quarter, month, month_name, week, day_of_month, day_of_week, day_name, is_weekend)
SELECT 
    TO_CHAR(date_series, 'YYYYMMDD')::INTEGER as date_key,
    date_series::DATE as full_date,
    EXTRACT(YEAR FROM date_series) as year,
    EXTRACT(QUARTER FROM date_series) as quarter,
    EXTRACT(MONTH FROM date_series) as month,
    TO_CHAR(date_series, 'Month') as month_name,
    EXTRACT(WEEK FROM date_series) as week,
    EXTRACT(DAY FROM date_series) as day_of_month,
    EXTRACT(DOW FROM date_series) as day_of_week,
    TO_CHAR(date_series, 'Day') as day_name,
    CASE WHEN EXTRACT(DOW FROM date_series) IN (0, 6) THEN true ELSE false END as is_weekend
FROM generate_series('2024-01-01'::DATE, '2025-12-31'::DATE, '1 day'::interval) date_series
ON CONFLICT (date_key) DO NOTHING;

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA raw TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA staging TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA processed TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA analytics TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA processed TO postgres;
