Create Schema farah_qutab;
Use farah_qutab;

SELECT 
    *
FROM
    customers_data;
SELECT 
    *
FROM
    inventory_movements_data;
SELECT 
    *
FROM
    products_data;
SELECT 
    *
FROM
    sales_data;

-- Module 1: Sales Performance Analysis
-- 1. Total Sales per Month: Calculate the total sales amount per month, including the number of units sold and the total revenue generated.
-- Total Sales Per Month: (Revenue = sales from product * units sold)/month

SELECT 
    DATE_FORMAT(STR_TO_DATE(CONCAT(YEAR(sale_date),
                            '-',
                            MONTH(sale_date),
                            '-01'),
                    '%Y-%m-%d'),
            '%Y-%m') AS Months,
    ROUND(SUM(p.price), 2) AS total_price,
    SUM(quantity_sold) AS total_quantity_sold,
    ROUND(SUM(p.price * quantity_sold), 2) AS total_revenue,
    ROUND(SUM(total_amount), 2) AS total_sales
FROM
    sales_data s
        INNER JOIN
    products_data p ON p.product_id = s.product_id
GROUP BY months
ORDER BY months ASC;

-- 2. Average Discount per Month: Calculate the average discount applied to sales in each month and assess how discounting strategies impact total sales.

SELECT 
    DATE_FORMAT(STR_TO_DATE(CONCAT(YEAR(sale_date),
                            '-',
                            MONTH(sale_date),
                            '-01'),
                    '%Y-%m-%d'),
            '%Y-%m') AS Months,
    AVG(discount_applied) AS avg_discount
FROM
    sales_data
GROUP BY months
ORDER BY months ASC; 


-- Module 2: Customer Behavior and Insights

-- 3. Identify high-value customers: Which customers have spent the most on their purchases? Show their details

SELECT 
    c.customer_id, total_amount AS total_sales
FROM
    sales_data s
        INNER JOIN
    customers_data c ON c.customer_id = s.customer_id
ORDER BY total_sales DESC
LIMIT 10;


-- 4. Identify the oldest Customer: Find the details of customers born in the 1990s, including their total spending and specific order details.

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    c.date_of_birth,
    s.product_id,
    p.product_name,
    p.category,
    s.quantity_sold AS quantity_bought,
    s.total_amount AS total_spending
FROM
    customers_data c
        INNER JOIN
    sales_data s ON c.customer_id = s.customer_id
        INNER JOIN
    products_data p ON s.product_id = p.product_id
WHERE
    date_of_birth LIKE '199%';

-- 5. Customer Segmentation: Use SQL to create customer segments based on their total spending (e.g., Low Spenders, High Spenders)

With ts as
(
Select s.customer_id, round(sum(s.total_amount),2) as total_spending
from sales_data s
group by s.customer_id
)
select c.customer_id,  concat(c.first_name, " ", c.last_name) as full_name,  ts.total_spending,
case 
	when ts.total_spending >= (select avg(total_spending) from ts) 
    then 'high spender'
    Else 'low spender'
End as Spender_Category
from customers_data c 
inner join sales_data s on c.customer_id= s.customer_id 
inner join products_data p on s.product_id= p.product_id
inner join  ts ON c.customer_id = ts.customer_id
group by customer_id, full_name, total_spending
ORDER BY Spender_Category Asc, ts.total_spending asc;

-- Module 3: Inventory and Product Management

-- 6. Stock Management: Write a query to find products that are running low in stock (below a threshold like 10 units) and recommend restocking amounts based on past sales performance.

SELECT 
    p.product_id, p.product_name
FROM
    products_data p
        INNER JOIN
    sales_data s ON s.product_id = p.product_id
WHERE
    p.stock_quantity < 10
GROUP BY p.product_id , p.product_name
ORDER BY product_name ASC;

-- 7. Inventory Movements Overview: Create a report showing the daily inventory movements (restock vs. sales) for each product over a given period.

SELECT 
    im.product_id,
    p.product_name,
    im.movement_date,
    SUM(CASE
        WHEN im.movement_type = 'IN' THEN im.quantity_moved
        ELSE 0
    END) AS total_restocked,
    SUM(CASE
        WHEN im.movement_type = 'OUT' THEN im.quantity_moved
        ELSE 0
    END) AS total_sold
FROM
    inventory_movements_data im
        INNER JOIN
    products_data p ON im.product_id = p.product_id
WHERE
    im.movement_date BETWEEN '2023-01-01' AND '2024-01-31'
GROUP BY im.product_id , p.product_name , im.movement_date
ORDER BY im.movement_date ASC , p.product_name ASC;

-- 8. Rank Products: Rank products in each category by their prices

select product_id, price, category, rank() over(partition by category order by price) 
from products_data;

-- Module 4: Advanced Analytics
-- 9. Average order size: What is the average order size in terms of quantity sold for each product?

SELECT 
    product_id, AVG(quantity_sold)
FROM
    sales_data
GROUP BY product_id;

-- 10. Recent Restock Product: Which products have seen the most recent restocks

SELECT 
    i.product_id, p.product_name, i.movement_date
FROM
    inventory_movements_data i
        INNER JOIN
    products_data p ON p.product_id = i.product_id
WHERE
    movement_type = 'IN'
ORDER BY movement_date DESC
LIMIT 5;


-- Advanced Features to Challenge Students
-- ● Dynamic Pricing Simulation: Challenge students to analyze how price changes for products impact sales volume, revenue, and customer behavior.

-- 1. Sales Volume Analysis: Analyze how price changes affected the number of units sold over time.


WITH ProductSales AS (
    SELECT 
        p.product_id,
        p.product_name,
        s.sale_date,
        s.quantity_sold,
        p.price AS original_price,
        (s.total_amount / s.quantity_sold) AS effective_price -- Derive per-unit sale price
    FROM 
        Products_data p
        JOIN Sales_data s ON p.product_id = s.product_id
),
PriceImpact AS (
    SELECT 
        ps.product_id,
        ps.product_name,
        ps.sale_date,
        ps.effective_price,
        SUM(ps.quantity_sold) OVER (PARTITION BY ps.product_id ORDER BY ps.sale_date) AS cumulative_sales
    FROM ProductSales ps
),
PriceElasticity AS (
    SELECT 
        product_id,
        product_name,
        sale_date,
        effective_price,
        cumulative_sales,
        LAG(effective_price) OVER (PARTITION BY product_id ORDER BY sale_date) AS prev_price,
        LAG(cumulative_sales) OVER (PARTITION BY product_id ORDER BY sale_date) AS prev_sales
    FROM PriceImpact
),
ElasticityCalculations AS (
    SELECT 
        product_id,
        product_name,
        sale_date,
        CASE 
            WHEN prev_price IS NOT NULL AND prev_price != 0 THEN 
                ((effective_price - prev_price) / prev_price) * 100
            ELSE NULL
        END AS price_change_percentage,
        CASE 
            WHEN prev_sales IS NOT NULL AND prev_sales != 0 THEN 
                ((cumulative_sales - prev_sales) / prev_sales) * 100
            ELSE NULL
        END AS sales_change_percentage,
        CASE 
            WHEN prev_price IS NOT NULL AND prev_price != 0 AND prev_sales IS NOT NULL AND prev_sales != 0 THEN 
                (((cumulative_sales - prev_sales) / prev_sales) /
                 ((effective_price - prev_price) / prev_price))
            ELSE NULL
        END AS price_elasticity
    FROM PriceElasticity
),
FilteredElasticity AS (
    SELECT 
        product_id,
        product_name,
        sale_date,
        price_change_percentage,
        sales_change_percentage,
        price_elasticity
    FROM ElasticityCalculations
    WHERE 
        ABS(price_change_percentage) > 1 AND 
        ABS(sales_change_percentage) > 1
),
CumulativeElasticity AS (
    SELECT 
        product_id,
        product_name,
        AVG(
            CASE 
                WHEN price_elasticity BETWEEN -10 AND 10 THEN price_elasticity
                ELSE NULL
            END
        ) AS avg_price_elasticity
    FROM FilteredElasticity
    GROUP BY product_id, product_name
)
SELECT 
    product_id,
    product_name,
    avg_price_elasticity
FROM CumulativeElasticity
ORDER BY avg_price_elasticity DESC;


-- Dynamic Price Changing Analysis using simulation:
WITH SimulatedPrices AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.price,
        p.price * 1.1 AS increased_price,
        p.price * 0.9 AS decreased_price
    FROM Products_data p
),
ImpactAnalysis AS (
    SELECT 
        sp.product_id,
        sp.product_name,
        sp.increased_price,
        sp.decreased_price,
        s.sale_date,
        SUM(s.quantity_sold) AS original_sales,
        SUM(s.quantity_sold * CASE 
            WHEN sp.increased_price THEN 1.1
            ELSE 0.9 
        END) AS adjusted_sales
    FROM 
        SimulatedPrices sp
        JOIN Sales_data s ON sp.product_id = s.product_id
    GROUP BY sp.product_id, sp.product_name, sp.increased_price, sp.decreased_price, s.sale_date
)
SELECT 
    product_id,
    product_name,
    sale_date,
    original_sales,
    adjusted_sales
FROM ImpactAnalysis
order by product_id asc;


-- Impact of price change on revenue

SELECT 
    p.product_id,
    p.product_name,
    s.sale_date,
    SUM(s.total_amount) AS total_revenue,
    AVG(p.price) AS average_price
FROM
    Products_data p
        JOIN
    Sales_data s ON p.product_id = s.product_id
GROUP BY p.product_id , p.product_name , s.sale_date
HAVING SUM(s.total_amount) > 0
ORDER BY p.product_id , s.sale_date;

-- Impact of price_change on customer behaviour

WITH ProductPrices AS (
    SELECT 
        s.sale_id,
        s.customer_id,
        s.product_id,
        s.sale_date,
        s.quantity_sold,
        s.total_amount,
        p.price AS product_price_at_sale,  -- Original product price during the sale
        (p.price * (1 + (s.discount_applied / 100))) AS price_after_discount -- Price after discount
    FROM Sales_data s
    JOIN Products_data p ON s.product_id = p.product_id
    ),
PriceImpact AS (
    SELECT 
        pp.customer_id,
        pp.product_id,
        pp.sale_date,
        pp.quantity_sold,
        pp.product_price_at_sale,
        pp.price_after_discount,
        CASE 
            WHEN pp.price_after_discount > pp.product_price_at_sale THEN 'Price Increased'
            WHEN pp.price_after_discount < pp.product_price_at_sale THEN 'Price Decreased'
            ELSE 'No Change'
        END AS price_change_type
    FROM ProductPrices pp
)
SELECT * 
FROM PriceImpact;
SELECT 
    pi.customer_id,
    pi.price_change_type,
    COUNT(pi.sale_date) AS purchase_frequency,
    SUM(pi.quantity_sold) AS total_quantity_sold,
    AVG(pi.price_after_discount) AS avg_price_per_purchase,
    SUM(pi.quantity_sold * pi.price_after_discount) AS total_spent
FROM
    PriceImpact pi
GROUP BY pi.customer_id , pi.price_change_type
ORDER BY pi.customer_id , price_change_type; 

-- ● Customer Purchase Patterns: Analyze purchase patterns using time-series data and window functions to find high-frequency buying behavior.

WITH CustomerPurchases AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        COUNT(s.sale_id) AS purchase_count,
        AVG(s.total_amount) AS avg_spent_per_purchase,
        MIN(s.sale_date) AS first_purchase_date,
        MAX(s.sale_date) AS last_purchase_date
    FROM 
        Customers_data c
        JOIN Sales_data s ON c.customer_id = s.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
),
BehaviorChange AS (
    SELECT 
        cp.customer_id,
        cp.customer_name,
        cp.purchase_count,
        cp.avg_spent_per_purchase,
        CASE 
            WHEN cp.last_purchase_date - cp.first_purchase_date < 30 THEN 'Frequent Buyer'
            ELSE 'Occasional Buyer'
        END AS customer_behavior
    FROM CustomerPurchases cp
)
SELECT 
    *
FROM BehaviorChange;


-- ● Predictive Analytics: Use past data to predict which customers are most likely to churn and recommend strategies to retain them.

WITH CustomerChurn AS (
    SELECT 
        customer_id,
        MAX(sale_date) AS last_purchase_date,
        DATEDIFF(CURRENT_DATE, MAX(sale_date)) AS days_since_last_purchase,
        CASE 
            WHEN DATEDIFF(CURRENT_DATE, MAX(sale_date)) > 90 THEN 'Churned'
            ELSE 'Active'
        END AS churn_status
    FROM Sales_data
    GROUP BY customer_id
),
CustomerBehavior AS (
    SELECT 
        s.customer_id,
        COUNT(s.sale_id) AS total_purchases,
        SUM(s.quantity_sold) AS total_quantity,
        SUM(s.total_amount) AS total_spent,
        AVG(s.discount_applied) AS avg_discount_used,
        MAX(s.sale_date) AS last_purchase_date
    FROM Sales_data s
    GROUP BY s.customer_id
)
SELECT 
    cb.customer_id,
    cb.total_purchases,
    cb.total_quantity,
    cb.total_spent,
    cb.avg_discount_used,
    cc.churn_status
FROM CustomerBehavior cb
JOIN CustomerChurn cc ON cb.customer_id = cc.customer_id;

-- Recommend Retention Strategies
/*Based on the churn prediction, you can suggest specific retention strategies for customers who are likely to churn:

Target Discounts or Offers: If a customer is at risk of churn, offering them discounts or special deals can increase their likelihood of returning.
Engagement Campaigns: Use email marketing or push notifications to re-engage customers who haven’t bought in a while.
Loyalty Programs: Reward frequent customers or offer loyalty points for their next purchase.
For example:

If a customer has high spending but hasn’t bought recently, offer them a personalized discount to encourage a return purchase.
If a customer’s total spend is low, but they frequently purchase, offer them product bundles to increase the average order value.*/
