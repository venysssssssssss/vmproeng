"""
PySpark Job - Sales Aggregation
This job performs aggregations on sales data and loads to analytics layer
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum, count, avg, min, max, round as spark_round
from pyspark.sql.window import Window
import sys

def create_spark_session():
    """Create Spark session with optimized settings"""
    return SparkSession.builder \
        .appName("SalesAggregation") \
        .config("spark.driver.memory", "256m") \
        .config("spark.executor.memory", "256m") \
        .config("spark.sql.shuffle.partitions", "2") \
        .config("spark.default.parallelism", "2") \
        .getOrCreate()

def aggregate_sales(spark, jdbc_url, db_properties):
    """Perform sales aggregations"""
    
    print("Loading sales data from fact table...")
    
    # Read fact_sales
    fact_sales = spark.read.jdbc(
        url=jdbc_url,
        table="processed.fact_sales",
        properties=db_properties
    )
    
    # Read dimensions
    dim_date = spark.read.jdbc(
        url=jdbc_url,
        table="processed.dim_date",
        properties=db_properties
    )
    
    dim_products = spark.read.jdbc(
        url=jdbc_url,
        table="processed.dim_products",
        properties=db_properties
    )
    
    dim_customers = spark.read.jdbc(
        url=jdbc_url,
        table="processed.dim_customers",
        properties=db_properties
    )
    
    # Join datasets
    sales_full = fact_sales \
        .join(dim_date, fact_sales.date_key == dim_date.date_key) \
        .join(dim_products, fact_sales.product_key == dim_products.product_key) \
        .join(dim_customers, fact_sales.customer_key == dim_customers.customer_key)
    
    print(f"Total records processed: {sales_full.count()}")
    
    # Aggregation 1: Monthly sales by category
    print("\n1. Aggregating monthly sales by category...")
    monthly_category = sales_full.groupBy(
        col("year"),
        col("month"),
        col("month_name"),
        col("category")
    ).agg(
        count("*").alias("transaction_count"),
        spark_round(sum("total_amount"), 2).alias("total_revenue"),
        sum("quantity").alias("total_quantity"),
        spark_round(avg("total_amount"), 2).alias("avg_transaction_value")
    ).orderBy("year", "month", col("total_revenue").desc())
    
    monthly_category.show(10)
    
    # Aggregation 2: Top selling products
    print("\n2. Finding top selling products...")
    top_products = sales_full.groupBy(
        col("product_id"),
        col("product_name"),
        col("category")
    ).agg(
        count("*").alias("sales_count"),
        sum("quantity").alias("total_quantity_sold"),
        spark_round(sum("total_amount"), 2).alias("total_revenue")
    ).orderBy(col("total_revenue").desc())
    
    top_products.show(10)
    
    # Aggregation 3: Customer segmentation by spending
    print("\n3. Customer segmentation by spending...")
    customer_spending = sales_full.groupBy(
        col("customer_id"),
        col("customer_name"),
        col("city"),
        col("state")
    ).agg(
        count("*").alias("purchase_count"),
        spark_round(sum("total_amount"), 2).alias("total_spent"),
        spark_round(avg("total_amount"), 2).alias("avg_order_value"),
        min("full_date").alias("first_purchase"),
        max("full_date").alias("last_purchase")
    ).orderBy(col("total_spent").desc())
    
    customer_spending.show(10)
    
    # Aggregation 4: Payment method analysis
    print("\n4. Payment method analysis...")
    payment_analysis = sales_full.groupBy("payment_method").agg(
        count("*").alias("transaction_count"),
        spark_round(sum("total_amount"), 2).alias("total_revenue"),
        spark_round(avg("total_amount"), 2).alias("avg_transaction_value")
    ).orderBy(col("transaction_count").desc())
    
    payment_analysis.show()
    
    # Aggregation 5: Weekend vs Weekday sales
    print("\n5. Weekend vs Weekday sales...")
    weekend_analysis = sales_full.groupBy("is_weekend").agg(
        count("*").alias("transaction_count"),
        spark_round(sum("total_amount"), 2).alias("total_revenue"),
        spark_round(avg("total_amount"), 2).alias("avg_transaction_value")
    )
    
    weekend_analysis.show()
    
    print("\nAggregations completed successfully!")
    
    return {
        'monthly_category': monthly_category,
        'top_products': top_products,
        'customer_spending': customer_spending,
        'payment_analysis': payment_analysis,
        'weekend_analysis': weekend_analysis
    }

def main():
    # Database connection
    jdbc_url = "jdbc:postgresql://postgres:5432/datawarehouse"
    db_properties = {
        "user": "postgres",
        "password": "postgres",
        "driver": "org.postgresql.Driver"
    }
    
    # Create Spark session
    spark = create_spark_session()
    
    try:
        # Run aggregations
        results = aggregate_sales(spark, jdbc_url, db_properties)
        
        # Optionally save results back to database or files
        print("\nSales aggregation job completed successfully!")
        
    except Exception as e:
        print(f"Error during aggregation: {str(e)}")
        sys.exit(1)
    finally:
        spark.stop()

if __name__ == "__main__":
    main()
