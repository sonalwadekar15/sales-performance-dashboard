CREATE DATABASE IF NOT EXISTS sales_analytics;
USE sales_analytics;

-- ============================================================
-- 1. DATASET STRUCTURE AND VALIDATION
-- ============================================================

SELECT COUNT(*) AS Total_Columns
FROM information_schema.columns
WHERE table_schema = 'sales_analytics'
  AND table_name = 'sales_data';

SELECT COUNT(*) AS Total_Rows
FROM sales_data;

SELECT *
FROM sales_data
LIMIT 10;

-- ============================================================
-- 2. DATE CLEANING AND VALIDATION
-- ============================================================

-- Run the ALTER TABLE statement only once if the clean date
-- columns do not already exist.

-- ALTER TABLE sales_data
-- ADD COLUMN order_date_clean DATE,
-- ADD COLUMN ship_date_clean DATE;

UPDATE sales_data
SET
    order_date_clean = STR_TO_DATE(`Order Date`, '%d-%m-%Y'),
    ship_date_clean  = STR_TO_DATE(`Ship Date`, '%d-%m-%Y');

SELECT
    MIN(order_date_clean) AS Earliest_Date,
    MAX(order_date_clean) AS Latest_Date,
    COUNT(*) AS Total_Rows
FROM sales_data;

SELECT
    SUM(order_date_clean IS NULL) AS Null_Order_Dates,
    SUM(ship_date_clean IS NULL) AS Null_Ship_Dates
FROM sales_data;

-- ============================================================
-- 3. OVERALL BUSINESS METRICS
-- ============================================================

SELECT
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    COUNT(DISTINCT `Order ID`) AS Total_Orders,
    COUNT(DISTINCT `Customer ID`) AS Total_Customers,
    COUNT(DISTINCT `Product ID`) AS Total_Products,
    ROUND(AVG(Discount), 4) AS Average_Discount,
    ROUND(SUM(Sales) / COUNT(DISTINCT `Order ID`), 2) AS Average_Order_Value
FROM sales_data;

-- ============================================================
-- 4. TIME-BASED ANALYSIS
-- ============================================================

SELECT
    YEAR(order_date_clean) AS Year,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    COUNT(DISTINCT `Order ID`) AS Total_Orders
FROM sales_data
GROUP BY YEAR(order_date_clean)
ORDER BY Year;

SELECT
    YEAR(order_date_clean) AS Year,
    MONTH(order_date_clean) AS Month_Number,
    MONTHNAME(order_date_clean) AS Month_Name,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM sales_data
GROUP BY
    YEAR(order_date_clean),
    MONTH(order_date_clean),
    MONTHNAME(order_date_clean)
ORDER BY Year, Month_Number;

WITH yearly_sales AS
(
    SELECT
        YEAR(order_date_clean) AS Year,
        SUM(Sales) AS Total_Sales
    FROM sales_data
    GROUP BY YEAR(order_date_clean)
)
SELECT
    Year,
    ROUND(Total_Sales, 2) AS Total_Sales,
    ROUND(
        (Total_Sales - LAG(Total_Sales) OVER (ORDER BY Year))
        / LAG(Total_Sales) OVER (ORDER BY Year) * 100,
        2
    ) AS YoY_Growth_Percentage
FROM yearly_sales
ORDER BY Year;

-- ============================================================
-- 5. REGIONAL AND LOCATION ANALYSIS
-- ============================================================

SELECT
    Region,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    COUNT(DISTINCT `Order ID`) AS Total_Orders
FROM sales_data
GROUP BY Region
ORDER BY Total_Sales DESC;

SELECT
    State,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    COUNT(DISTINCT `Order ID`) AS Total_Orders
FROM sales_data
GROUP BY State
ORDER BY Total_Sales DESC;

SELECT
    City,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    COUNT(DISTINCT `Order ID`) AS Total_Orders
FROM sales_data
GROUP BY City
ORDER BY Total_Sales DESC
LIMIT 10;

SELECT
    City,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM sales_data
GROUP BY City
HAVING SUM(Profit) < 0
ORDER BY Total_Profit;

-- ============================================================
-- 6. CATEGORY AND PRODUCT ANALYSIS
-- ============================================================

SELECT
    Category,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    COUNT(DISTINCT `Order ID`) AS Total_Orders
FROM sales_data
GROUP BY Category
ORDER BY Total_Sales DESC;

SELECT
    Category,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM sales_data
GROUP BY Category
HAVING SUM(Profit) > 50000
ORDER BY Total_Profit DESC;

SELECT
    Category,
    `Sub-Category`,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    COUNT(DISTINCT `Order ID`) AS Total_Orders
FROM sales_data
GROUP BY Category, `Sub-Category`
ORDER BY Category, Total_Sales DESC;

SELECT
    `Sub-Category`,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM sales_data
GROUP BY `Sub-Category`
HAVING SUM(Profit) < 0
ORDER BY Total_Profit;

SELECT
    `Product Name`,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM sales_data
GROUP BY `Product Name`
ORDER BY Total_Sales DESC
LIMIT 10;

SELECT
    `Product Name`,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM sales_data
GROUP BY `Product Name`
ORDER BY Total_Profit DESC
LIMIT 5;

SELECT
    `Product Name`,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM sales_data
GROUP BY `Product Name`
ORDER BY Total_Profit
LIMIT 10;

SELECT
    Category,
    ROUND(AVG(Sales), 2) AS Average_Sales
FROM sales_data
GROUP BY Category
ORDER BY Average_Sales DESC
LIMIT 1;

WITH product_sales AS
(
    SELECT
        Category,
        `Product ID`,
        `Product Name`,
        SUM(Sales) AS Total_Sales
    FROM sales_data
    GROUP BY Category, `Product ID`, `Product Name`
),
ranked_products AS
(
    SELECT
        Category,
        `Product ID`,
        `Product Name`,
        Total_Sales,
        ROW_NUMBER() OVER
        (
            PARTITION BY Category
            ORDER BY Total_Sales DESC
        ) AS Sales_Rank
    FROM product_sales
)
SELECT
    Category,
    `Product ID`,
    `Product Name`,
    ROUND(Total_Sales, 2) AS Total_Sales,
    Sales_Rank
FROM ranked_products
WHERE Sales_Rank <= 3
ORDER BY Category, Sales_Rank;

WITH product_sales AS
(
    SELECT
        `Product ID`,
        `Product Name`,
        Category,
        SUM(Sales) AS Total_Sales
    FROM sales_data
    GROUP BY `Product ID`, `Product Name`, Category
)
SELECT
    `Product ID`,
    `Product Name`,
    Category,
    ROUND(Total_Sales, 2) AS Total_Sales
FROM product_sales
WHERE Total_Sales > (SELECT AVG(Total_Sales) FROM product_sales)
ORDER BY Total_Sales DESC;

-- ============================================================
-- 7. CUSTOMER AND SEGMENT ANALYSIS
-- ============================================================

SELECT
    Segment,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    COUNT(DISTINCT `Order ID`) AS Total_Orders
FROM sales_data
GROUP BY Segment
ORDER BY Total_Sales DESC;

SELECT
    `Customer ID`,
    `Customer Name`,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    COUNT(DISTINCT `Order ID`) AS Total_Orders
FROM sales_data
GROUP BY `Customer ID`, `Customer Name`
ORDER BY Total_Sales DESC
LIMIT 10;

SELECT
    `Customer Name`,
    ROUND(SUM(Sales), 2) AS Total_Sales
FROM sales_data
GROUP BY `Customer Name`
ORDER BY Total_Sales DESC
LIMIT 5;

SELECT
    `Customer Name`,
    ROUND(SUM(Sales), 2) AS Total_Sales
FROM sales_data
GROUP BY `Customer Name`
HAVING SUM(Sales) > 15000
ORDER BY Total_Sales DESC;

SELECT
    `Customer Name`,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    CASE
        WHEN SUM(Profit) > 1000 THEN 'High Profit'
        WHEN SUM(Profit) > 0 THEN 'Medium Profit'
        ELSE 'Loss'
    END AS Profit_Status
FROM sales_data
GROUP BY `Customer Name`
ORDER BY Total_Profit DESC;

WITH customer_sales AS
(
    SELECT
        `Customer ID`,
        `Customer Name`,
        SUM(Sales) AS Total_Sales
    FROM sales_data
    GROUP BY `Customer ID`, `Customer Name`
)
SELECT
    `Customer ID`,
    `Customer Name`,
    ROUND(Total_Sales, 2) AS Total_Sales
FROM customer_sales
WHERE Total_Sales > (SELECT AVG(Total_Sales) FROM customer_sales)
ORDER BY Total_Sales DESC;

WITH customer_sales AS
(
    SELECT
        `Customer ID`,
        `Customer Name`,
        SUM(Sales) AS Total_Sales
    FROM sales_data
    GROUP BY `Customer ID`, `Customer Name`
)
SELECT
    `Customer ID`,
    `Customer Name`,
    ROUND(Total_Sales, 2) AS Total_Sales
FROM customer_sales
ORDER BY Total_Sales DESC
LIMIT 1 OFFSET 1;

WITH customer_sales AS
(
    SELECT
        `Customer ID`,
        SUM(Sales) AS Total_Sales
    FROM sales_data
    GROUP BY `Customer ID`
),
top_customer AS
(
    SELECT `Customer ID`
    FROM customer_sales
    ORDER BY Total_Sales DESC
    LIMIT 1
)
SELECT
    `Order ID`,
    `Customer ID`,
    `Customer Name`,
    Sales
FROM sales_data
WHERE `Customer ID` = (SELECT `Customer ID` FROM top_customer)
ORDER BY Sales DESC;

-- ============================================================
-- 8. SHIPPING ANALYSIS
-- ============================================================

SELECT
    `Ship Mode`,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    COUNT(DISTINCT `Order ID`) AS Total_Orders
FROM sales_data
GROUP BY `Ship Mode`
ORDER BY Total_Sales DESC;

SELECT
    `Ship Mode`,
    ROUND(AVG(DATEDIFF(ship_date_clean, order_date_clean)), 2)
        AS Average_Shipping_Days
FROM sales_data
GROUP BY `Ship Mode`
ORDER BY Average_Shipping_Days;

-- ============================================================
-- 9. DISCOUNT AND PROFITABILITY ANALYSIS
-- ============================================================

SELECT
    Discount,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    COUNT(DISTINCT `Order ID`) AS Total_Orders
FROM sales_data
GROUP BY Discount
ORDER BY Discount;

SELECT
    `Order ID`,
    `Customer Name`,
    Discount,
    Sales,
    Profit
FROM sales_data
WHERE Discount = (SELECT MAX(Discount) FROM sales_data);

SELECT
    CASE
        WHEN Discount = 0 THEN 'No Discount'
        WHEN Discount <= 0.20 THEN 'Low Discount'
        WHEN Discount <= 0.40 THEN 'Medium Discount'
        ELSE 'High Discount'
    END AS Discount_Band,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    COUNT(DISTINCT `Order ID`) AS Total_Orders
FROM sales_data
GROUP BY Discount_Band
ORDER BY MIN(Discount);

SELECT
    `Order ID`,
    `Customer Name`,
    `Product Name`,
    Discount,
    Sales,
    Profit
FROM sales_data
WHERE Discount >= 0.40
  AND Profit < 0
ORDER BY Profit;

-- ============================================================
-- 10. SUBQUERIES AND FILTERING
-- ============================================================

SELECT *
FROM sales_data
WHERE Sales > (SELECT AVG(Sales) FROM sales_data);

SELECT *
FROM sales_data
WHERE Profit > (SELECT AVG(Profit) FROM sales_data)
ORDER BY Profit DESC
LIMIT 5;

SELECT
    `Order ID`,
    `Customer Name`,
    Region,
    Sales
FROM sales_data
WHERE `Customer ID` IN
(
    SELECT DISTINCT `Customer ID`
    FROM sales_data
    WHERE Region = 'West'
);

SELECT
    `Order ID`,
    `Customer Name`,
    Category,
    Sales
FROM sales_data
WHERE Category IN
(
    SELECT Category
    FROM sales_data
    GROUP BY Category
    HAVING SUM(Sales) > 700000
);

-- ============================================================
-- 11. WINDOW FUNCTIONS
-- ============================================================

WITH customer_summary AS
(
    SELECT
        `Customer ID`,
        `Customer Name`,
        SUM(Sales) AS Total_Sales
    FROM sales_data
    GROUP BY `Customer ID`, `Customer Name`
)
SELECT
    `Customer ID`,
    `Customer Name`,
    ROUND(Total_Sales, 2) AS Total_Sales,
    ROW_NUMBER() OVER (ORDER BY Total_Sales DESC) AS Row_Number_Rank,
    RANK() OVER (ORDER BY Total_Sales DESC) AS Rank_Value,
    DENSE_RANK() OVER (ORDER BY Total_Sales DESC) AS Dense_Rank_Value
FROM customer_summary
ORDER BY Total_Sales DESC;

WITH yearly_sales AS
(
    SELECT
        YEAR(order_date_clean) AS Year,
        SUM(Sales) AS Total_Sales
    FROM sales_data
    GROUP BY YEAR(order_date_clean)
)
SELECT
    Year,
    ROUND(Total_Sales, 2) AS Total_Sales,
    ROUND(
        SUM(Total_Sales) OVER
        (
            ORDER BY Year
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS Running_Total_Sales
FROM yearly_sales
ORDER BY Year;

-- ============================================================
-- 12. COMMON TABLE EXPRESSIONS
-- ============================================================

WITH customer_summary AS
(
    SELECT
        `Customer ID`,
        `Customer Name`,
        ROUND(SUM(Sales), 2) AS Total_Sales,
        ROUND(SUM(Profit), 2) AS Total_Profit
    FROM sales_data
    GROUP BY `Customer ID`, `Customer Name`
)
SELECT *
FROM customer_summary
ORDER BY Total_Sales DESC;

-- ============================================================
-- 13. UNION
-- ============================================================

SELECT City AS Location, 'City' AS Location_Type
FROM sales_data

UNION

SELECT State AS Location, 'State' AS Location_Type
FROM sales_data;

-- ============================================================
-- 14. VIEW AND INDEX
-- ============================================================

DROP VIEW IF EXISTS category_summary;

CREATE VIEW category_summary AS
SELECT
    Category,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM sales_data
GROUP BY Category;

SELECT *
FROM category_summary
ORDER BY Total_Sales DESC;

-- Create this index only once:
-- CREATE INDEX idx_customer
-- ON sales_data (`Customer ID`);