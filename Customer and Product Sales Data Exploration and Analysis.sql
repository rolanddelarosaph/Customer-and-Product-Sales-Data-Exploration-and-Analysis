/*
=============================================================
Create Database and Schemas
=============================================================
Project Overview:
    This script initializes a SQL Server database named 'DataWarehouseAnalytics' for analytics and reporting.
    It ensures a fresh environment by replacing any existing database with the same name.
    The schema and tables are designed to support dimensional modeling and business analysis.

*/

USE master;
GO

-- Drop and recreate the 'DataWarehouseAnalytics' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseAnalytics')
BEGIN
    ALTER DATABASE DataWarehouseAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouseAnalytics;
END;
GO

CREATE DATABASE DataWarehouseAnalytics;
GO

USE DataWarehouseAnalytics;
GO

-- Create schema for analytics tables
CREATE SCHEMA gold;
GO

-- Dimension and fact tables for core analytics
CREATE TABLE gold.dim_customers(
    customer_key int,
    customer_id int,
    customer_number nvarchar(50),
    first_name nvarchar(50),
    last_name nvarchar(50),
    country nvarchar(50),
    marital_status nvarchar(50),
    gender nvarchar(50),
    birthdate date,
    create_date date
);
GO

CREATE TABLE gold.dim_products(
    product_key int,
    product_id int,
    product_number nvarchar(50),
    product_name nvarchar(50),
    category_id nvarchar(50),
    category nvarchar(50),
    subcategory nvarchar(50),
    maintenance nvarchar(50),
    cost int,
    product_line nvarchar(50),
    start_date date 
);
GO

CREATE TABLE gold.fact_sales(
    order_number nvarchar(50),
    product_key int,
    customer_key int,
    order_date date,
    shipping_date date,
    due_date date,
    sales_amount int,
    quantity tinyint,
    price int 
);
GO

-- Load sample data for analysis
TRUNCATE TABLE gold.dim_customers;
GO

BULK INSERT gold.dim_customers
FROM '/var/opt/mssql/data/gold.dim_customers.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);
GO

TRUNCATE TABLE gold.dim_products;
GO

BULK INSERT gold.dim_products
FROM '/var/opt/mssql/data/gold.dim_products.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);
GO

TRUNCATE TABLE gold.fact_sales;
GO

BULK INSERT gold.fact_sales
FROM '/var/opt/mssql/data/gold.fact_sales.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);
GO

/*
===============================================================================
Database Exploration
===============================================================================
Purpose:
    Review the structure and metadata of the database, including table listing and schema details.
    This section is key for understanding how the data warehouse is organized and for validating schema setup.

*/

-- Show all tables in the database
SELECT 'Database Tables Overview' AS [Result Title],
    TABLE_CATALOG, 
    TABLE_SCHEMA, 
    TABLE_NAME, 
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES;

-- Show columns and types for the dim_customers table
SELECT 'dim_customers Table Columns' AS [Result Title],
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE, 
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';


/*
===============================================================================
Dimensions Exploration
===============================================================================
Purpose:
    Inspect dimension tables to understand the diversity of customers and products.
    These queries help profile the range and uniqueness of business attributes.

*/

-- Unique countries represented by customers
SELECT 'Unique Countries in Customers' AS [Result Title],
    country 
FROM gold.dim_customers
GROUP BY country
ORDER BY country;

-- Unique combinations of category, subcategory, and product
SELECT 'Unique Categories, Subcategories, and Products' AS [Result Title],
    category, 
    subcategory, 
    product_name 
FROM gold.dim_products
GROUP BY category, subcategory, product_name
ORDER BY category, subcategory, product_name;


/*
===============================================================================
Date Range Exploration 
===============================================================================
Purpose:
    Analyze the timeline coverage for sales and customer data.
    These queries establish data boundaries, such as the earliest and latest order dates and the age span of customers.

*/

-- Range of order dates and the period of business activity
SELECT 'Order Date Range and Duration (in months)' AS [Result Title],
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS order_range_months
FROM gold.fact_sales;

-- Age profile for customers (oldest and youngest)
SELECT 'Customer Age Range (by birthdate)' AS [Result Title],
    MIN(birthdate) AS oldest_birthdate,
    DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS oldest_age,
    MAX(birthdate) AS youngest_birthdate,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS youngest_age
FROM gold.dim_customers;


/*
===============================================================================
Measures Exploration (Key Metrics)
===============================================================================
Purpose:
    Calculate business-critical metrics such as total sales, quantities, average prices, and counts.
    These queries provide a snapshot of overall performance and scale.

*/

-- Total sales value
SELECT 'Total Sales' AS [Result Title], SUM(sales_amount) AS total_sales FROM gold.fact_sales;

-- Total quantity sold
SELECT 'Total Quantity Sold' AS [Result Title], SUM(quantity) AS total_quantity FROM gold.fact_sales;

-- Average selling price
SELECT 'Average Selling Price' AS [Result Title], AVG(price) AS avg_price FROM gold.fact_sales;

-- Total orders (including duplicates)
SELECT 'Total Number of Orders' AS [Result Title], COUNT(order_number) AS total_orders FROM gold.fact_sales;

-- Unique orders
SELECT 'Total Number of Distinct Orders' AS [Result Title], COUNT(DISTINCT order_number) AS total_orders FROM gold.fact_sales;

-- Total products available
SELECT 'Total Number of Products' AS [Result Title], COUNT(product_name) AS total_products FROM gold.dim_products;

-- Total customers in the database
SELECT 'Total Number of Customers' AS [Result Title], COUNT(customer_key) AS total_customers FROM gold.dim_customers;

-- Customers who placed at least one order
SELECT 'Total Number of Customers Who Placed Orders' AS [Result Title], COUNT(DISTINCT customer_key) AS total_customers FROM gold.fact_sales;

-- Summary report on all key metrics
SELECT 'Business Key Metrics Summary' AS [Result Title], 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Business Key Metrics Summary', 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'Business Key Metrics Summary', 'Average Price', AVG(price) FROM gold.fact_sales
UNION ALL
SELECT 'Business Key Metrics Summary', 'Total Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Business Key Metrics Summary', 'Total Products', COUNT(DISTINCT product_name) FROM gold.dim_products
UNION ALL
SELECT 'Business Key Metrics Summary', 'Total Customers', COUNT(customer_key) FROM gold.dim_customers;


/*
===============================================================================
Magnitude Analysis
===============================================================================
Purpose:
    Group and aggregate data by business-relevant dimensions such as country, gender, and product category.
    These queries support segmentation and reveal patterns in business volume and distribution.

*/

-- Customers grouped by country
SELECT 'Total Customers by Country' AS [Result Title], country, COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- Customers grouped by gender
SELECT 'Total Customers by Gender' AS [Result Title], gender, COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- Products grouped by category
SELECT 'Total Products by Category' AS [Result Title], category, COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- Average product cost in each category
SELECT 'Average Cost by Category' AS [Result Title], category, AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;

-- Revenue grouped by product category
SELECT 'Total Revenue by Category' AS [Result Title], p.category, SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Revenue grouped by customer
SELECT 'Total Revenue by Customer' AS [Result Title], c.customer_key, c.first_name, c.last_name, SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC;

-- Sold items distribution across countries
SELECT 'Sold Items Distribution Across Countries' AS [Result Title], c.country, SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC;


/*
===============================================================================
Ranking Analysis
===============================================================================
Purpose:
    Identify top and bottom performers among products and customers.
    These queries support data-driven decisions for sales strategies and customer engagement.

*/

-- Top 5 products by sales revenue
SELECT 'Top 5 Products by Revenue' AS [Result Title], p.product_name, SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;

-- Top 5 products by revenue using window function
SELECT * FROM (
    SELECT 'Top 5 Products by Revenue (Window Function)' AS [Result Title], p.product_name, SUM(f.sales_amount) AS total_revenue,
        RANK() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_products
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
    GROUP BY p.product_name
) AS ranked_products
WHERE rank_products <= 5;

-- 5 lowest-performing products by sales revenue
SELECT '5 Worst-Performing Products by Revenue' AS [Result Title], p.product_name, SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;

-- Top 10 customers by total sales revenue
SELECT 'Top 10 Customers by Revenue' AS [Result Title], c.customer_key, c.first_name, c.last_name, SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- 3 customers with the fewest orders placed
SELECT '3 Customers with Fewest Orders' AS [Result Title], c.customer_key, c.first_name, c.last_name, COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_orders ASC
OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY;