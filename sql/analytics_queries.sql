-- Queries úteis para análise de dados no Metabase

-- 1. Dashboard Overview - Métricas Principais
SELECT 
    COUNT(DISTINCT transaction_id) as total_transactions,
    COUNT(DISTINCT customer_key) as total_customers,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_transaction_value,
    SUM(quantity) as total_items_sold
FROM processed.fact_sales
WHERE date_key >= TO_CHAR(CURRENT_DATE - INTERVAL '30 days', 'YYYYMMDD')::INTEGER;

-- 2. Vendas por Dia (últimos 30 dias)
SELECT 
    d.full_date,
    COUNT(*) as transactions,
    SUM(f.total_amount) as revenue,
    AVG(f.total_amount) as avg_value
FROM processed.fact_sales f
JOIN processed.dim_date d ON f.date_key = d.date_key
WHERE d.full_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY d.full_date
ORDER BY d.full_date;

-- 3. Top 10 Produtos Mais Vendidos
SELECT 
    p.product_name,
    p.category,
    COUNT(*) as sales_count,
    SUM(f.quantity) as total_quantity,
    SUM(f.total_amount) as total_revenue
FROM processed.fact_sales f
JOIN processed.dim_products p ON f.product_key = p.product_key
GROUP BY p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 10;

-- 4. Vendas por Categoria
SELECT 
    p.category,
    COUNT(*) as transaction_count,
    SUM(f.total_amount) as total_revenue,
    AVG(f.total_amount) as avg_transaction,
    SUM(f.quantity) as total_items
FROM processed.fact_sales f
JOIN processed.dim_products p ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- 5. Top 10 Clientes (por valor gasto)
SELECT 
    c.customer_name,
    c.city,
    c.state,
    COUNT(*) as purchase_count,
    SUM(f.total_amount) as total_spent,
    AVG(f.total_amount) as avg_order_value
FROM processed.fact_sales f
JOIN processed.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.customer_name, c.city, c.state
ORDER BY total_spent DESC
LIMIT 10;

-- 6. Análise de Métodos de Pagamento
SELECT 
    payment_method,
    COUNT(*) as transaction_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_transaction,
    ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 2) as percentage
FROM processed.fact_sales
GROUP BY payment_method
ORDER BY total_revenue DESC;

-- 7. Vendas: Fim de Semana vs Dias de Semana
SELECT 
    CASE WHEN d.is_weekend THEN 'Weekend' ELSE 'Weekday' END as period_type,
    COUNT(*) as transactions,
    SUM(f.total_amount) as revenue,
    AVG(f.total_amount) as avg_value
FROM processed.fact_sales f
JOIN processed.dim_date d ON f.date_key = d.date_key
GROUP BY d.is_weekend;

-- 8. Tendência Mensal de Vendas
SELECT 
    d.year,
    d.month,
    d.month_name,
    COUNT(*) as transactions,
    SUM(f.total_amount) as revenue,
    COUNT(DISTINCT f.customer_key) as unique_customers
FROM processed.fact_sales f
JOIN processed.dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- 9. Análise de Coorte - Primeira vs Última Compra
SELECT 
    DATE_TRUNC('month', first_purchase_date) as cohort_month,
    COUNT(*) as customers,
    AVG(total_spent) as avg_lifetime_value,
    AVG(total_purchases) as avg_purchases,
    AVG(customer_lifetime_days) as avg_lifetime_days
FROM analytics.customer_metrics
GROUP BY DATE_TRUNC('month', first_purchase_date)
ORDER BY cohort_month;

-- 10. Performance de Produtos por Mês
SELECT 
    d.year,
    d.month_name,
    p.category,
    COUNT(*) as sales_count,
    SUM(f.total_amount) as revenue,
    SUM(f.quantity) as units_sold
FROM processed.fact_sales f
JOIN processed.dim_products p ON f.product_key = p.product_key
JOIN processed.dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month, d.month_name, p.category
ORDER BY d.year, d.month, revenue DESC;

-- 11. Análise de Status das Transações
SELECT 
    status,
    COUNT(*) as count,
    SUM(total_amount) as total_value,
    ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 2) as percentage
FROM processed.fact_sales
GROUP BY status
ORDER BY count DESC;

-- 12. Análise Geográfica (por Estado)
SELECT 
    c.state,
    COUNT(DISTINCT c.customer_key) as total_customers,
    COUNT(*) as total_transactions,
    SUM(f.total_amount) as total_revenue,
    AVG(f.total_amount) as avg_transaction_value
FROM processed.fact_sales f
JOIN processed.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.state
ORDER BY total_revenue DESC;
