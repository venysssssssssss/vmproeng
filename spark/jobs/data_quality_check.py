"""
PySpark Job - Data Quality Check
This job performs data quality validations on the sales data
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count, when, isnan, isnull, sum as spark_sum
from datetime import datetime
import sys

def create_spark_session():
    """Create Spark session with optimized settings for low memory"""
    return SparkSession.builder \
        .appName("DataQualityCheck") \
        .config("spark.driver.memory", "256m") \
        .config("spark.executor.memory", "256m") \
        .config("spark.sql.shuffle.partitions", "2") \
        .config("spark.default.parallelism", "2") \
        .getOrCreate()

def check_data_quality(spark, jdbc_url, db_properties):
    """Run data quality checks"""
    
    print("=" * 50)
    print("Starting Data Quality Checks")
    print("=" * 50)
    
    # Read data from staging
    df = spark.read.jdbc(
        url=jdbc_url,
        table="staging.sales_clean",
        properties=db_properties
    )
    
    total_records = df.count()
    print(f"\nTotal records in staging: {total_records}")
    
    # Check 1: Null values
    print("\n1. Checking for null values...")
    null_counts = df.select([
        count(when(isnull(c) | isnan(c), c)).alias(c) 
        for c in df.columns
    ])
    null_counts.show()
    
    # Check 2: Duplicate transactions
    print("\n2. Checking for duplicate transactions...")
    duplicates = df.groupBy("transaction_id").count().filter(col("count") > 1)
    duplicate_count = duplicates.count()
    print(f"Found {duplicate_count} duplicate transaction IDs")
    if duplicate_count > 0:
        duplicates.show(5)
    
    # Check 3: Negative values
    print("\n3. Checking for negative values...")
    negative_quantity = df.filter(col("quantity") < 0).count()
    negative_price = df.filter(col("unit_price") < 0).count()
    negative_total = df.filter(col("total_amount") < 0).count()
    
    print(f"Records with negative quantity: {negative_quantity}")
    print(f"Records with negative unit_price: {negative_price}")
    print(f"Records with negative total_amount: {negative_total}")
    
    # Check 4: Data consistency
    print("\n4. Checking data consistency...")
    inconsistent = df.filter(
        (col("quantity") * col("unit_price")) != col("total_amount")
    ).count()
    print(f"Records with inconsistent total_amount: {inconsistent}")
    
    # Check 5: Category distribution
    print("\n5. Category distribution:")
    df.groupBy("category").count().orderBy(col("count").desc()).show()
    
    # Check 6: Status distribution
    print("\n6. Status distribution:")
    df.groupBy("status").count().show()
    
    # Check 7: Date range
    print("\n7. Date range:")
    df.select("transaction_date").summary("min", "max").show()
    
    # Generate quality report
    quality_report = {
        'timestamp': datetime.now().isoformat(),
        'total_records': total_records,
        'duplicate_transactions': duplicate_count,
        'negative_values': {
            'quantity': negative_quantity,
            'unit_price': negative_price,
            'total_amount': negative_total
        },
        'inconsistent_totals': inconsistent
    }
    
    print("\n" + "=" * 50)
    print("Data Quality Check Complete")
    print("=" * 50)
    print(f"Quality Report: {quality_report}")
    
    return quality_report

def main():
    # Database connection settings
    jdbc_url = "jdbc:postgresql://postgres:5432/datawarehouse"
    db_properties = {
        "user": "postgres",
        "password": "postgres",
        "driver": "org.postgresql.Driver"
    }
    
    # Create Spark session
    spark = create_spark_session()
    
    try:
        # Run quality checks
        report = check_data_quality(spark, jdbc_url, db_properties)
        
        # Save report (you could save to database or file)
        print("\nQuality check completed successfully!")
        
    except Exception as e:
        print(f"Error during quality check: {str(e)}")
        sys.exit(1)
    finally:
        spark.stop()

if __name__ == "__main__":
    main()
