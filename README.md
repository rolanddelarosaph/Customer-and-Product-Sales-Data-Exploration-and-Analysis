# Customer and Product Sales - Data Exploration and Basic Analysis

##  Project Overview  
An exploratory data analysis project that builds a **retail sales data warehouse** integrating customer, product, and sales data. Using **SQL**, I designed structured tables, imported data from CSV files, and conducted analyses to uncover key business insights.

---

##  Project Workflow  

1. **Database Creation**  
   - Built a new database named `DataWarehouseAnalytics`.  
   - Created the `gold` schema to organize dimension and fact tables.

2. **Data Integration**  
   - Loaded datasets (`dim_customers`, `dim_products`, `fact_sales`) from CSV files using `BULK INSERT`.  
   - Ensured proper structure for dimensions (customers, products) and facts (sales transactions).

3. **Data Exploration**  
   - Inspected database metadata using `INFORMATION_SCHEMA`.  
   - Explored unique attributes like countries, categories, and products.

4. **Analytical Queries**  
   - Measured total sales, order counts, and average prices.  
   - Analyzed customer demographics, product categories, and revenue distribution.  
   - Ranked top and bottom performers (products and customers) using window functions.

---

##  Key Insights Generated  
- Total and average sales metrics  
- Distribution of customers by country and gender  
- Top-selling products and highest-spending customers  
- Revenue by product category and customer group  
- Sales timeline and growth trends  

---

##  Tools & Technologies  
- **Azure Data Studio** (SQL environment)  
- **Docker + Azure SQL Edge** (database engine)  
- **CSV datasets** as data sources  

---

## 📁 Dataset Files  
- `gold.dim_customers.csv`  
- `gold.dim_products.csv`  
- `gold.fact_sales.csv`  
