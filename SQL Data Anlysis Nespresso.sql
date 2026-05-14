select * from city

-- 1) Coffee consumers counts by city
--    Considering that 25% consumers in the city
SELECT
    city_name,
    population,
    CAST(ROUND((population * 0.25) / 1000000.0, 1) AS DECIMAL(10,1)) 
        AS estimated_coffee_consumers_millions
FROM City
ORDER BY estimated_coffee_consumers_millions DESC;

-- 2) Total revenue from coffee sales in last quater 2023
-- The sum of sales from 2023-10-01 to 2024-01-01

SELECT
   CAST( SUM(s.total) AS decimal(10,1))
   AS total_revenue_last_quarter_2023
FROM sales s
WHERE s.sale_date >= '2023-10-01'
  AND s.sale_date < '2024-01-01';


-- 3) Sales counts for each products 
-- This counts will show how many units of each product were sold 
--  select * from products
--  select * from sales

SELECT
    p.product_id,
    p.product_name,
    COUNT(*) AS units_sold
FROM sales s
JOIN products p
    ON s.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC, p.product_name;

-- 4) Average sales amount per city
-- This calculate avg sales amount per customer in each city
-- select * from sales
-- select * from customers 
-- select * from city 

SELECT
    c.city_name,
    cast(ROUND(AVG(s.total), 2) as decimal (10,1))
    AS avg_sales_amount_per_customer
FROM sales s
JOIN customers cu
    ON s.customer_id = cu.customer_id
JOIN City c
    ON cu.city_id = c.city_id
GROUP BY c.city_name
ORDER BY avg_sales_amount_per_customer DESC;

-- 5) City population and coffee onsumer 
-- This will list each city with population and coffee consumer 

SELECT
    city_name,
    population,
    CAST(ROUND((population * 0.25) / 1000000.0, 1) AS DECIMAL(10,1))
    AS estimated_coffee_consumers
FROM City
ORDER BY estimated_coffee_consumers DESC;

-- 06) Top three products in each city 
-- This will return top 3 products by sales volume per city using window function
WITH city_product_sales AS (
    SELECT
        c.city_name,
        p.product_name,
        COUNT(*) AS units_sold,
        ROW_NUMBER() OVER (
            PARTITION BY c.city_name
            ORDER BY COUNT(*) DESC, p.product_name
        ) AS rn
    FROM sales s
    JOIN customers cu
        ON s.customer_id = cu.customer_id
    JOIN City c
        ON cu.city_id = c.city_id
    JOIN products p
        ON s.product_id = p.product_id
    GROUP BY c.city_name, p.product_name
)
SELECT
    city_name,
    product_name,
    units_sold
FROM city_product_sales
WHERE rn <= 3
ORDER BY city_name, units_sold DESC, product_name;

-- 7) Customer Segmentation by City 
-- This will counts unique customers in each city who purchase coffee products 
SELECT
    c.city_name,
    COUNT(DISTINCT cu.customer_id) AS unique_customers
FROM sales s
JOIN customers cu
    ON s.customer_id = cu.customer_id
JOIN City c
    ON cu.city_id = c.city_id
GROUP BY c.city_name
ORDER BY unique_customers DESC;

-- 8) Average Sales vs Rent
-- This will return avg sales per customer and avg rent per customer by city
WITH city_sales AS (
    SELECT
        c.city_id,
        c.city_name,
        SUM(s.total) AS total_sales,
        COUNT(DISTINCT cu.customer_id) AS total_customers,
        MAX(c.estimated_rent) AS estimated_rent
    FROM sales s
    JOIN customers cu
        ON s.customer_id = cu.customer_id
    JOIN City c
        ON cu.city_id = c.city_id
    GROUP BY c.city_id, c.city_name
)
SELECT
    city_name,
    ROUND(total_sales / NULLIF(total_customers, 0), 2) AS avg_sale_per_customer,
    ROUND(estimated_rent / NULLIF(total_customers, 0), 2) AS avg_rent_per_customer
FROM city_sales
ORDER BY avg_rent_per_customer DESC; -- Also can be checked avg_rent_per_customer

--9) Monthly sales growth 
-- This will calculate month over month growth rate 

WITH monthly_sales AS (
    SELECT
        DATEFROMPARTS(YEAR(sale_date), MONTH(sale_date), 1) AS sales_month,
        SUM(total) AS monthly_revenue
    FROM sales
    GROUP BY 
    DATEFROMPARTS(YEAR(sale_date), MONTH(sale_date), 1)

),
growth AS (
    SELECT
        sales_month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (ORDER BY sales_month) AS prev_month_revenue
    FROM monthly_sales
)
SELECT
    sales_month,

    CAST(ROUND(monthly_revenue, 2) AS DECIMAL(10,2)) AS monthly_revenue,

    CAST(ROUND(prev_month_revenue, 2) AS DECIMAL(10,2)) AS prev_month_revenue,

    CAST(
        ROUND(
            ((monthly_revenue - prev_month_revenue)
            / NULLIF(prev_month_revenue, 0)) * 100,
            2
        )
        AS DECIMAL(10,2)
    ) AS growth_rate_percent

FROM growth
ORDER BY sales_month;

--10) Market potential analysis 
-- This returns top 3 cities by total sales, plus rent, customers and estimated coffee consumers 

WITH city_metrics AS (
    SELECT
        c.city_name,
        SUM(s.total) AS total_sale,
        MAX(c.estimated_rent) AS total_rent,
        COUNT(DISTINCT cu.customer_id) AS total_customers,
    --  ROUND(MAX(c.population) * 0.25) AS estimated_coffee_consumers,
        CAST(ROUND((MAX(c.population) * 0.25)/1000000.0 ,1) AS DECIMAL (10,1))
        AS estimated_coffee_consumers_millions,
        ROW_NUMBER() OVER (ORDER BY SUM(s.total) DESC) AS rn
    FROM sales s
    JOIN customers cu
        ON s.customer_id = cu.customer_id
    JOIN City c


        ON cu.city_id = c.city_id
    GROUP BY c.city_name
)
SELECT
    city_name,
    total_sale,
    total_rent,
    total_customers,
    estimated_coffee_consumers_millions
FROM city_metrics
WHERE rn <= 3
ORDER BY total_sale DESC;



/* Suggested final recomendation query will be based on following four factore
High total sales.
High estimated coffee consumers.
Strong number of unique customers.
Lower average rent per customer. */

WITH city_summary AS (
    SELECT
        c.city_name,

        CAST(SUM(s.total) AS DECIMAL(10,2)) AS total_sale,

        MAX(c.estimated_rent) AS total_rent,

        COUNT(DISTINCT cu.customer_id) AS total_customers,

        CAST(ROUND(MAX(c.population) * 0.25, 1) AS DECIMAL(10,1))
            AS estimated_coffee_consumers

    FROM sales s
    JOIN customers cu
        ON s.customer_id = cu.customer_id
    JOIN City c
        ON cu.city_id = c.city_id
    GROUP BY c.city_name
)

SELECT TOP 3
    City_name,
    Total_sale,
    Total_rent,
    Total_customers,
    Estimated_coffee_consumers
FROM city_summary
ORDER BY total_sale DESC,
         estimated_coffee_consumers DESC,
         total_rent ASC;