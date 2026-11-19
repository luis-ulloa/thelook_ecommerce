SELECT MIN(created_at), MAX(created_at) FROM bigquery-public-data.thelook_ecommerce.orders;

SELECT * FROM bigquery-public-data.thelook_ecommerce.orders
ORDER BY created_at DESC;

-- 1: Write a query that returns the first 10 rows from the orders table, 
-- but only show these columns: order_id, user_id, status, created_at, and num_of_item. 
-- Order the results by created_at ascending
SELECT 
  order_id,
  user_id,
  status,
  created_at,
  num_of_item
FROM `bigquery-public-data.thelook_ecommerce.orders`
ORDER BY created_at
LIMIT 10;

-- 2: Write a query that returns each distinct status value from the 
-- orders table along with a count of how many orders have that status. 
-- Name the count column order_count. Sort by order_count descending so 
-- the most common status appears first.
SELECT 
  status,
  COUNT(status) AS order_count
FROM `bigquery-public-data.thelook_ecommerce.orders`
GROUP BY status
ORDER BY order_count DESC;

-- 3a: Write a query that shows the number of orders placed per month. 
-- Use DATE_TRUNC to truncate created_at to the month level. Name that 
-- column order_month and the count column order_count. Only include 
-- orders with status Complete or Shipped. Sort by order_month ascending.
SELECT 
  EXTRACT(YEAR FROM created_at) AS order_year,
  COUNT(*)                      AS order_count
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE status IN ('Complete', 'Shipped')
GROUP BY EXTRACT(YEAR FROM created_at)
ORDER BY order_year;

-- 3b: count by year & month >> complete or shipped
SELECT 
  EXTRACT(YEAR FROM created_at)   AS order_year,
  EXTRACT(MONTH FROM created_at)  AS order_month,
  COUNT(*)                        AS order_count
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE LOWER(status) IN ('complete', 'shipped')
GROUP BY 
  EXTRACT(YEAR FROM created_at),
  EXTRACT(MONTH FROM created_at)
ORDER BY order_year, order_month;

-- 4: Write a query that returns total revenue per year. Join orders to 
-- order_items on order_id. Only include Complete or Shipped orders. Round 
-- revenue to 2 decimals and name it total_revenue. Sort by year ascending.
SELECT
  EXTRACT(YEAR FROM o.created_at) AS order_year,
  ROUND(SUM(oi.sale_price),2)     AS total_revenue
FROM bigquery-public-data.thelook_ecommerce.orders      AS o
JOIN bigquery-public-data.thelook_ecommerce.order_items AS oi
  ON o.order_id = oi.order_id 
WHERE LOWER(o.status) IN ('complete', 'shipped')
GROUP BY EXTRACT(YEAR FROM o.created_at)
ORDER BY order_year;

-- 5: Building on Challenge 4, now calculate revenue per order (Average Order Value) 
-- by year. Same filters. You’ll need to think carefully about what to divide by.
SELECT
  EXTRACT(YEAR FROM o.created_at)                 AS order_year,
  ROUND(SUM(oi.sale_price)/SUM(o.num_of_item),2)  AS revenue_per_order
FROM bigquery-public-data.thelook_ecommerce.orders      AS o
JOIN bigquery-public-data.thelook_ecommerce.order_items AS oi
  ON o.order_id = oi.order_id 
WHERE LOWER(o.status) IN ('complete', 'shipped')
GROUP BY EXTRACT(YEAR FROM o.created_at)
ORDER BY order_year;

SELECT
  EXTRACT(YEAR FROM o.created_at) AS order_year,
  ROUND(SUM(oi.sale_price)/COUNT(DISTINCT o.order_id),2) AS avg_order_value -- <<< correct metric
FROM bigquery-public-data.thelook_ecommerce.orders      AS o
JOIN bigquery-public-data.thelook_ecommerce.order_items AS oi
  ON o.order_id = oi.order_id 
WHERE LOWER(o.status) IN ('complete', 'shipped')
GROUP BY EXTRACT(YEAR FROM o.created_at)
ORDER BY order_year;

-- 6: Write a query that returns the top 10 states by number of unique customers. 
-- Use the users table only — no joins needed. Name the count column customer_count. 
-- Only count each user once. Sort descending by customer_count.
SELECT
  state,
  COUNT(DISTINCT id) AS customer_count
FROM bigquery-public-data.thelook_ecommerce.users
WHERE LOWER(country) IN ('united states', 'usa', 'us')
GROUP BY state
ORDER BY customer_count DESC
LIMIT 10;

SELECT
  state               AS province,
  COUNT(DISTINCT id)  AS customer_count
FROM bigquery-public-data.thelook_ecommerce.users
WHERE LOWER(country) = 'china'
GROUP BY state
ORDER BY customer_count DESC
LIMIT 10;

-- 7: Write a query showing total revenue and order count per country, joining 
-- orders, order_items, and users. Same status filter. Sort by total revenue descending.

SELECT
  CASE
    WHEN LOWER(u.country) IN ('spain', 'españa') THEN 'Spain'
    WHEN LOWER(u.country) IN ('germany', 'deutschland') THEN 'Germany'
    ELSE u.country
  END                         AS country,
  SUM(o.num_of_item)          AS order_count,
  ROUND(SUM(oi.sale_price),2) AS total_revenue
FROM bigquery-public-data.thelook_ecommerce.users       AS u
JOIN bigquery-public-data.thelook_ecommerce.orders      AS o 
  ON u.id = o.user_id
JOIN bigquery-public-data.thelook_ecommerce.order_items AS oi
  ON o.order_id = oi.order_id
WHERE LOWER(o.status) IN ('complete', 'shipped')
GROUP BY u.country
ORDER BY total_revenue DESC;

-- 8: Write a query that returns the top 10 products by total revenue, including:
-- p.name as product_name
-- p.category
-- p.brand
-- p.department
-- Count of times the product was sold as times_sold
-- Total revenue as total_revenue
-- Average sale price as avg_sale_price
-- Use the correct chain join. Only Complete or Shipped orders. Round all money 
-- to 2 decimals. Sort by total_revenue descending.

-- Thought process...
-- join from products to order_items on id = product_id
-- products table should be one instance of each product, then order_items
-- shows how many times those products from products have been ordered
SELECT
  p.name                                                AS product_name,
  p.category,
  p.brand,
  p.department,
  COUNT(oi.product_id)                                  AS times_sold,
  ROUND(SUM(oi.sale_price),2)                           AS total_revenue,
  ROUND(SUM(oi.sale_price)/COUNT(oi.product_id))        AS avg_sale_price
FROM bigquery-public-data.thelook_ecommerce.products    AS p
JOIN bigquery-public-data.thelook_ecommerce.order_items AS oi
  ON p.id = oi.product_id
WHERE LOWER(oi.status) IN ('shipped', 'complete')
GROUP BY 
  oi.product_id,
  p.name,
  p.category,
  p.brand,
  p.department
ORDER BY total_revenue DESC
LIMIT 10;         

-- 9: Write a query that shows return rate by product category, including:
-- category
-- total_sold — count of items with Complete or Shipped status
-- total_returned — count of items with Returned status
-- return_rate — returned divided by sold, expressed as a percentage, rounded to 2 decimals
-- Sort by return_rate descending

WITH rtns_n_sold AS (
  SELECT
  p.category                                                  AS cat,
  COUNT(CASE
         WHEN LOWER(oi.status) = 'complete'
         THEN oi.product_id
         ELSE NULL
        END)                                                  AS sold,
  COUNT(CASE
         WHEN LOWER(oi.status) = 'returned'
         THEN oi.product_id
         ELSE NULL
        END)                                                  AS rtns
  FROM bigquery-public-data.thelook_ecommerce.products        AS p
  JOIN bigquery-public-data.thelook_ecommerce.order_items     AS oi
    ON p.id = oi.product_id
  GROUP BY p.category
)
SELECT 
  rtns_n_sold.cat                                             AS product_category,
  rtns_n_sold.sold                                            AS orders_complete,
  rtns_n_sold.rtns                                            AS orders_returned,
  ROUND((rtns_n_sold.rtns/(rtns_n_sold.sold+rtns_n_sold.rtns))*100,2)
                                                              AS return_rate
FROM rtns_n_sold
ORDER BY return_rate DESC;

-- 10: Write a query that shows how many customers made their first purchase each year, 
-- and what their average lifetime spending is. Include:
-- first_purchase_year — the year of each customer’s first order
-- customer_count — how many customers had their first purchase that year
-- avg_lifetime_spend — average total spending per customer in that cohort, rounded to 2 decimals
-- Rules:
-- Use Complete or Shipped orders only
-- Join users, orders, and order_items using the correct chain
-- Each customer should be counted once, in the year of their first order

WITH first_purchases AS (
--get date of first purchase for each user
  SELECT
    u.id AS uid,
  EXTRACT(YEAR FROM MIN(DATE(o.created_at))) AS yr
  FROM bigquery-public-data.thelook_ecommerce.users u
  JOIN bigquery-public-data.thelook_ecommerce.orders o
    ON u.id = o.user_id
  WHERE LOWER(o.status) IN ('complete', 'shipped')
  GROUP BY u.id
),
valid_sales AS (
--aggregate all sales by each user
  SELECT
  u.id AS uid,
  SUM(sale_price) AS sales
  FROM bigquery-public-data.thelook_ecommerce.users u
  JOIN bigquery-public-data.thelook_ecommerce.orders o
    ON u.id = o.user_id
  JOIN bigquery-public-data.thelook_ecommerce.order_items oi
    ON o.order_id = oi.order_id
  WHERE LOWER(oi.status) IN ('complete', 'shipped')
  GROUP BY u.id
)
--aggregate customer counts by year of first purchase
--display results
SELECT 
  fp.yr AS first_purchase_year,
  COUNT(fp.uid) AS customer_count,
  ROUND(AVG(vs.sales),2) AS avg_lifetime_spend
  FROM first_purchases fp
  JOIN valid_sales vs
    ON fp.uid = vs.uid
GROUP BY fp.yr
ORDER BY fp.yr;

-- 11: Write a query that shows monthly revenue with a running total across 
-- the entire dataset. Include:
-- order_year
-- order_month
-- monthly_revenue — total revenue for that month, rounded to 2 decimals
-- running_total — cumulative revenue from the beginning of the dataset through that month, rounded to 2 decimals

-- Rules:
-- Complete or Shipped orders only
-- Use the correct chain join
-- Sort by year then month ascending

WITH sale_totals AS (
  --aggregate sale totals by year/month
  SELECT 
  EXTRACT(YEAR FROM DATE(o.created_at))   AS yr,
  EXTRACT(MONTH FROM DATE(o.created_at))  AS mo,
  ROUND(SUM(oi.sale_price),2)             AS sales
  FROM bigquery-public-data.thelook_ecommerce.orders o
  JOIN bigquery-public-data.thelook_ecommerce.order_items oi
    ON o.order_id = oi.order_id
  WHERE LOWER(oi.status) IN ('complete', 'shipped')
  GROUP BY
    EXTRACT(YEAR FROM DATE(o.created_at)),
    EXTRACT(MONTH FROM DATE(o.created_at))
)
--show running monthly totals
SELECT
  st.yr     AS year,
  st.mo     AS month,
  st.sales  AS monthly_revenue,
  ROUND(SUM(st.sales) OVER(ORDER BY st.yr, st.mo),2) AS running_total
FROM sale_totals st;

-- 12: Write a query that ranks products by total revenue within each category. Include:
-- category
-- product_name
-- brand
-- total_revenue — rounded to 2 decimals
-- category_rank — rank of each product within its category by revenue, with no gaps in ranking

-- Rules:
-- Complete or Shipped orders only
-- Only show products ranked 3 or lower within their category (top 3 per category)
-- Round all money to 2 decimals

WITH product_revenue AS (
  SELECT
    p.category,
    p.name,
    p.brand,
    ROUND(SUM(oi.sale_price),2) AS revenue
  FROM bigquery-public-data.thelook_ecommerce.orders o
  JOIN bigquery-public-data.thelook_ecommerce.order_items oi
    ON o.order_id = oi.order_id
  JOIN bigquery-public-data.thelook_ecommerce.products p
    ON oi.product_id = p.id
  WHERE LOWER(o.status) IN ('complete', 'shipped')
  GROUP BY p.category, p.name, p.brand
),
rankings AS (
  SELECT
    pr.category,
    COALESCE(pr.name, 'Unknown') AS product_name,
    COALESCE(pr.brand, 'Unknown') AS product_brand,
    pr.revenue,
    ROW_NUMBER() 
      OVER(PARTITION BY pr.category 
           ORDER BY pr.revenue DESC) AS ranking
  FROM product_revenue pr
)
SELECT 
  *
FROM rankings r
WHERE r.ranking <= 3;

-- 13: Write a query that shows annual revenue with YoY growth rate. Include:
-- order_year
-- annual_revenue — rounded to 2 decimals
-- prev_year_revenue — previous year’s revenue, rounded to 2 decimals
-- yoy_growth_pct — percentage change vs prior year, rounded to 2 decimals. 
-- NULL for the first year is expected and correct.

-- Rules:
-- Complete or Shipped orders only
-- Correct chain join

WITH current_yr_revenue AS (
--aggregate current year revenues
  SELECT
    EXTRACT(YEAR FROM DATE(o.created_at)) AS yr,
    ROUND(SUM(oi.sale_price),2) AS revenue
  FROM bigquery-public-data.thelook_ecommerce.orders o
  JOIN bigquery-public-data.thelook_ecommerce.order_items oi
    ON o.order_id = oi.order_id
  WHERE LOWER(oi.status) IN ('complete', 'shipped')
  GROUP BY EXTRACT(YEAR FROM DATE(o.created_at))
),
     last_yr_revenue AS (
--shift by a year to display last year revenues
  SELECT 
    cyr.yr,
    cyr.revenue,
    LAG(cyr.revenue) OVER(ORDER BY cyr.yr) AS last_yr
  FROM current_yr_revenue cyr
)
--calculate year over year growth and display results
SELECT
  lyr.yr      AS year,
  lyr.revenue AS current_revenue,
  lyr.last_yr AS previous_revenue,
  ROUND(((lyr.revenue - lyr.last_yr)/lyr.last_yr)*100,2) AS yoy_growth_pct
FROM last_yr_revenue lyr
ORDER BY year;
 
-- 14: Classify each customer into a spending tier and summarize the segments. 
-- Produce a final output with:
-- spending_tier — classified as:
-- 'High Value' — lifetime spend > $500
-- 'Mid Value' — lifetime spend between $200 and $500 inclusive
-- 'Low Value' — lifetime spend < $200
-- customer_count — number of customers in each tier
-- avg_lifetime_spend — average spend per customer in that tier, rounded to 2 decimals
-- total_revenue_contribution — total revenue from that tier, rounded to 2 decimals
-- pct_of_total_revenue — that tier’s share of total revenue as a percentage, rounded to 2 decimals

-- Rules:
-- Complete or Shipped orders only
-- Correct chain join
-- Sort by total_revenue_contribution descending

WITH rev_per_user AS (
  --aggregate revenue per user
  SELECT 
    u.id,
    SUM(oi.sale_price) AS spend
  FROM bigquery-public-data.thelook_ecommerce.orders o
  JOIN bigquery-public-data.thelook_ecommerce.order_items oi
    ON o.order_id = oi.order_id
  JOIN bigquery-public-data.thelook_ecommerce.users u
    ON o.user_id = u.id
  WHERE LOWER(o.status) IN ('complete', 'shipped')
  GROUP BY u.id
),
     tier_class AS (
  --classify users by spend level
  SELECT
    rpu.id,
    rpu.spend,
    CASE
      WHEN rpu.spend > 500 THEN 'High Value'
      WHEN rpu.spend BETWEEN 200 AND 500 THEN 'Mid Value'
      ELSE 'Low Value'
    END AS tier
  FROM rev_per_user rpu  
)
--group by tier, count users and calculate aggregates by tier
SELECT
  tc.tier                AS spending_tier,
  COUNT(tc.id)           AS customer_count,
  ROUND(AVG(tc.spend),2) AS avg_lifetime_spend,
  ROUND(SUM(tc.spend),2) AS total_revenue_contribution,
  ROUND(SUM(tc.spend) / SUM(SUM(tc.spend)) OVER()*100,2) AS pct_total_revenue
FROM tier_class tc
GROUP BY tc.tier
ORDER BY total_revenue_contribution DESC;
  
-- 15: Write a query that shows monthly revenue with a 3-month moving average. Include:
-- order_year
-- order_month
-- monthly_revenue — rounded to 2 decimals
-- moving_avg_3m — average of current month plus the 2 preceding months, rounded to 2 decimals

-- Rules:
-- Complete or Shipped orders only
-- Correct chain join
-- Sort by year then month ascending

WITH monthly_revenue AS (
  --aggregate monthly revenue and monthly average
  SELECT 
    EXTRACT(YEAR FROM DATE(o.created_at)) AS yr,
    EXTRACT(MONTH FROM DATE(o.created_at)) AS mo,
    ROUND(SUM(oi.sale_price),2) AS mo_rev
  FROM bigquery-public-data.thelook_ecommerce.orders o
  JOIN bigquery-public-data.thelook_ecommerce.order_items oi
    ON o.order_id = oi.order_id
  WHERE LOWER(oi.status) IN ('complete', 'shipped')
  GROUP BY 
    EXTRACT(YEAR FROM DATE(o.created_at)),
    EXTRACT(MONTH FROM DATE(o.created_at))
  ORDER BY yr, mo
)
--calculate 3-month moving avg and display results
SELECT
  mr.yr AS order_year,
  mr.mo AS order_month,
  mr.mo_rev AS monthly_revenue,
  ROUND(AVG(mr.mo_rev) OVER(ORDER BY mr.yr, mr.mo
                 ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2)
  AS moving_avg_3mo
FROM monthly_revenue mr;

-- 16: Write a query showing profit margin by product category. Include:
-- category
-- total_revenue — sum of sale_price from order_items, rounded to 2 decimals
-- total_cost — sum of cost from inventory_items, rounded to 2 decimals
-- total_profit — revenue minus cost, rounded to 2 decimals
-- margin_pct — profit as a percentage of revenue, rounded to 2 decimals
-- Sort by margin_pct descending

WITH revenue_n_cost AS (
  SELECT
    p.category,
    ROUND(SUM(oi.sale_price),2) AS rev,
    ROUND(SUM(ii.cost),2) AS cost
  FROM bigquery-public-data.thelook_ecommerce.order_items oi
  JOIN bigquery-public-data.thelook_ecommerce.products p
    ON oi.product_id = p.id
  JOIN bigquery-public-data.thelook_ecommerce.inventory_items ii
    ON oi.inventory_item_id = ii.id
  WHERE LOWER(oi.status) IN ('complete', 'shipped')
  GROUP BY p.category
)
SELECT
  rnc.category,
  rnc.rev AS total_revenue,
  rnc.cost AS total_cost,
  ROUND((rnc.rev - rnc.cost),2) AS total_profit,
  ROUND((rnc.rev - rnc.cost)/rnc.rev*100,2) AS margin_pct
FROM revenue_n_cost rnc
ORDER BY margin_pct DESC;

-- 17: Write a query that shows repeat purchase behavior. Include:
-- total_customers — total unique customers who placed at least one qualifying order
-- one_time_customers — customers who placed exactly one order
-- repeat_customers — customers who placed more than one order
-- repeat_rate_pct — percentage of customers who came back, rounded to 2 decimals
-- avg_orders_per_repeat_customer — average number of orders among repeat customers only, rounded to 2 decimals

-- Rules:
-- Complete or Shipped orders only — filter on oi.status
-- Correct chain join
-- Single row output — this is a scalar summary metric

WITH order_counts AS (
  SELECT 
  --order counts per customer
    u.id,
    COUNT(DISTINCT o.order_id) AS order_c --actual order count per customer/user
  FROM bigquery-public-data.thelook_ecommerce.users u
  JOIN bigquery-public-data.thelook_ecommerce.orders o
    ON u.id = o.user_id
  JOIN bigquery-public-data.thelook_ecommerce.order_items oi
    ON o.order_id = oi.order_id
  WHERE LOWER(oi.status) IN ('complete', 'shipped')
  GROUP BY u.id
),
customer_classification AS (
SELECT
  --customer classification based on order counts
    COUNT(oc.id) AS usrs, -- total customer count
    COUNT(CASE WHEN oc.order_c = 1 THEN TRUE END) AS ot, --one time customers
    COUNT(CASE WHEN oc.order_c > 1 THEN TRUE END) AS rc, --repeat customers
    SUM(CASE WHEN oc.order_c > 1 THEN oc.order_c END) AS rpoc --repeat customer order count
  FROM order_counts oc
)
SELECT
  cc.usrs       AS total_customers,
  cc.ot         AS one_time_customers,
  cc.rc         AS repeat_customers,
  ROUND((cc.rc/cc.usrs*100),2)  AS repeat_rate_pct,
  ROUND((cc.rpoc/cc.rc),2)      AS avg_orders_per_repeat_customer
FROM customer_classification cc;

-- 18: Write a query showing traffic source effectiveness. Include:
-- traffic_source
-- total_users — unique users who triggered at least one event
-- total_orders — unique orders placed by those users
-- total_revenue — rounded to 2 decimals
-- orders_per_user — rounded to 2 decimals
-- revenue_per_user — rounded to 2 decimals
-- Sort by total_revenue descending

-- Rules:
-- Complete or Shipped orders only — filter on oi.status
-- Correct chain join

WITH source_metrics AS (
  SELECT
    u.traffic_source            AS src,
    COUNT(DISTINCT u.id)        AS usr,
    COUNT(DISTINCT o.order_id)  AS ord,
    ROUND(SUM(oi.sale_price),2) AS rev
  FROM bigquery-public-data.thelook_ecommerce.users u
  JOIN bigquery-public-data.thelook_ecommerce.orders o
    ON u.id = o.user_id
  JOIN bigquery-public-data.thelook_ecommerce.order_items oi
    ON o.order_id = oi.order_id
  WHERE LOWER(oi.status) IN ('complete', 'shipped')
  GROUP BY u.traffic_source
)
SELECT
  sm.src                 AS traffic_source,
  sm.usr                 AS total_users,
  sm.ord                 AS total_orders,
  sm.rev                 AS total_revenue,
  ROUND(sm.ord/sm.usr,2) AS orders_per_user,
  ROUND(sm.rev/sm.usr,2) AS revenue_per_user
FROM source_metrics sm
ORDER BY total_revenue DESC;

-- 19a: Write a query showing revenue and customer metrics by country, including:
-- country — cleaned up with your CASE statement for España/Deutschland
-- total_customers — unique customers
-- total_orders — unique orders
-- total_revenue — rounded to 2 decimals
-- avg_order_value — rounded to 2 decimals
-- avg_revenue_per_customer — rounded to 2 decimals
-- pct_of_global_revenue — that country’s share of total revenue, rounded to 2 decimals
-- Sort by total_revenue descending

-- Rules:
-- Complete or Shipped orders only — filter on oi.status
-- Correct chain join
-- Clean country names

WITH country_cleanup AS (
  SELECT 
    CASE
      WHEN LOWER(u.country) IN ('spain', 'españa') THEN 'Spain'
      WHEN LOWER(u.country) IN ('germany', 'deutschland') THEN 'Germany'
      ELSE u.country
    END           AS country,
    u.id          AS users,
    o.order_id    AS orders,
    oi.sale_price AS sales
  FROM bigquery-public-data.thelook_ecommerce.users u
  JOIN bigquery-public-data.thelook_ecommerce.orders o
    ON u.id = o.user_id
  JOIN bigquery-public-data.thelook_ecommerce.order_items oi
    ON o.order_id = oi.order_id
  WHERE LOWER(oi.status) IN ('complete', 'shipped')
)
SELECT
  cc.country,
  COUNT(DISTINCT cc.users)  AS total_customers,
  COUNT(DISTINCT cc.orders) AS total_orders,
  ROUND(SUM(cc.sales),2)    AS total_revenue,
  ROUND(SUM(cc.sales)/COUNT(DISTINCT cc.orders),2)          AS avg_order_value,
  ROUND(SUM(cc.sales)/COUNT(DISTINCT cc.users),2)           AS avg_revenue_per_customer,
  ROUND((SUM(cc.sales) / SUM(SUM(cc.sales)) OVER())*100,2)  AS pct_of_global_revenue
FROM country_cleanup cc
GROUP BY cc.country
ORDER BY total_revenue DESC;

-- 19b: top 5 states within top 3 countries using a window function you’ve already used. Which one and why?

WITH country_cleanup_02 AS (
  SELECT 
    CASE
      WHEN LOWER(u.country) IN ('spain', 'españa') THEN 'Spain'
      WHEN LOWER(u.country) IN ('germany', 'deutschland') THEN 'Germany'
      ELSE u.country
    END           AS ctry, -- country
    u.state       AS ps,   -- political subdivision (state/province/etc)
    oi.sale_price AS rev   -- order sales
  FROM bigquery-public-data.thelook_ecommerce.users u
  JOIN bigquery-public-data.thelook_ecommerce.orders o
    ON u.id = o.user_id
  JOIN bigquery-public-data.thelook_ecommerce.order_items oi
    ON o.order_id = oi.order_id
  WHERE LOWER(oi.status) IN ('complete', 'shipped')
),
aggregate_by_entity AS (
  --aggregate revenue at the political subdivision level first
  SELECT 
    cc2.ctry      AS country,
    cc2.ps        AS entity,
    SUM(cc2.rev)  AS revenue
  FROM country_cleanup_02 cc2
  GROUP BY cc2.ctry, cc2.ps
),
aggregate_by_country AS (
  --then aggregate revenue in a new column at the country level
  SELECT
    abe.country AS country,
    abe.entity  AS entity,
    SUM(abe.revenue) OVER(PARTITION BY abe.country) AS country_sales,
    abe.revenue AS entity_revenue
  FROM aggregate_by_entity abe
),
rankings AS (
  --rank by country first, then political subdivision, by revenue in descending order
  SELECT
    abc.country,
    abc.entity,
    ROUND(abc.country_sales,2),
    ROUND(abc.entity_revenue,2) AS revenue,
    DENSE_RANK() OVER(ORDER BY abc.country_sales DESC) AS country_rank,
    ROW_NUMBER() OVER(PARTITION BY abc.country ORDER BY abc.entity_revenue DESC) AS entity_rank
  FROM aggregate_by_country abc
  ORDER BY country_rank, entity_rank
)
--filter out desired results: top three countries, top 5 states/provinces within each country
SELECT
  r.country,
  r.entity AS state_or_province,
  r.revenue,
  r.country_rank,
  r.entity_rank AS state_or_province_rank
FROM rankings r
WHERE r.country_rank <=3 AND r.entity_rank <=5;


-- 20a Dataset 1:::::::::::::::::::::::::::::::::::::::::::::::::::::::::

WITH valid_sales AS (
  -- extract year & month for each valid order
  -- aggregate monthly revenue, orders and item qty 
  SELECT 
  EXTRACT(YEAR FROM DATE(o.created_at))   AS yr,
  EXTRACT(MONTH FROM DATE(o.created_at))  AS mo,
  SUM(oi.sale_price)                      AS mo_rev,
  COUNT(DISTINCT o.order_id)              AS ord_ct,
  SUM(o.num_of_item)                      AS itm_ct
  FROM bigquery-public-data.thelook_ecommerce.orders o
  JOIN bigquery-public-data.thelook_ecommerce.order_items oi
    ON o.order_id = oi.order_id
  WHERE LOWER(oi.status) IN ('complete', 'shipped')
  GROUP BY
    EXTRACT(YEAR FROM DATE(o.created_at)),
    EXTRACT(MONTH FROM DATE(o.created_at))
),
monthly_metrics AS (
--computation of several desired monthly metrics 
--plus 3-month moving avg of monthly sales
  SELECT
    vs.yr,
    vs.mo,
    vs.mo_rev,
    --shift monthly revenue back by 1 month
    LAG(vs.mo_rev,1) OVER(ORDER BY vs.yr, vs.mo) AS pre_mo_rev,
    vs.ord_ct,
    vs.itm_ct,
    vs.mo_rev/vs.ord_ct AS rev_ord,
    vs.itm_ct/vs.ord_ct AS itm_ord,
    --3 month revenue moving average
    AVG(vs.mo_rev) OVER(ORDER BY vs.yr, vs.mo
                     ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
                     AS mvg_avg_3mo
  FROM valid_sales vs
)
--round up figures and display results
SELECT
  mm.yr                                            AS order_year,
  mm.mo                                            AS order_month,
  mm.ord_ct                                        AS order_count,
  mm.itm_ct                                        AS items_sold, 
  ROUND(mm.mo_rev,2)                               AS monthly_revenue,
  ROUND(mm.rev_ord,2)                              AS avg_order_value,
  ROUND(mm.itm_ord,2)                              AS avg_items_per_order,
  ROUND(mm.pre_mo_rev,2)                           AS prev_month_revenue,
  ROUND((mm.mo_rev - pre_mo_rev)*100/pre_mo_rev,2) AS mom_growth_pct,
  ROUND(mm.mvg_avg_3mo,2)                          AS moving_avg_3m  
FROM monthly_metrics mm
ORDER BY mm.yr, mm.mo;

-- 20b Dataset 2:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
WITH base_aggregations AS (
  -- aggregate needed fields by category based on status for further calculations
  SELECT 
    p.category,
    SUM(CASE 
          WHEN LOWER(oi.status) IN ('complete', 'shipped') THEN oi.sale_price 
        END) AS rev,
    -- This test aggregation must be greater because it includes returns. 
    -- Confirm results, then suppress -----------------------------------
    -- SUM(oi.sale_price) rev_with_returns,
    ---------------------------------------------------------------------
    SUM(CASE 
          WHEN LOWER(oi.status) IN ('complete', 'shipped') THEN p.cost
        END) AS cost,
    SUM(o.num_of_item) AS all_items,
    SUM(CASE 
          WHEN LOWER(oi.status) = 'returned' THEN o.num_of_item
        END) AS itms_returned
  FROM bigquery-public-data.thelook_ecommerce.orders o
  JOIN bigquery-public-data.thelook_ecommerce.order_items oi
    ON o.order_id = oi.order_id
  JOIN bigquery-public-data.thelook_ecommerce.products p
    ON oi.product_id = p.id
  WHERE LOWER(oi.status) IN ('complete', 'shipped', 'returned')
  GROUP BY p.category
)
SELECT
  --compute needed metrics, round up and display results
  ba.category                                   AS product_category,
  ROUND(ba.rev,2)                               AS total_revenue,
  ROUND(ba.cost,2)                              AS total_cost,
  ROUND((ba.rev - ba.cost)*100/ba.rev,2)        AS margin_pct,
  ROUND(ba.itms_returned*100/ba.all_items,2)    AS return_rate,
  RANK() OVER(ORDER BY ba.rev DESC)             AS revenue_rank
FROM base_aggregations ba;

-- 20c Dataset 3:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
WITH rev_per_user AS (
  --aggregate revenue per user and traffic source
  SELECT 
    u.traffic_source,
    u.id,
    SUM(oi.sale_price) AS spend
  FROM bigquery-public-data.thelook_ecommerce.users u
  JOIN bigquery-public-data.thelook_ecommerce.orders o
    ON u.id = o.user_id
  JOIN bigquery-public-data.thelook_ecommerce.order_items oi
    ON o.order_id = oi.order_id
  WHERE LOWER(oi.status) IN ('complete', 'shipped')
  GROUP BY u.traffic_source, u.id
),
tier_class AS (
  --classify users by spend level
  SELECT
    rpu.traffic_source,
    rpu.id,
    rpu.spend,
    CASE
      WHEN rpu.spend > 500 THEN 'High Value'
      WHEN rpu.spend BETWEEN 200 AND 500 THEN 'Mid Value'
      ELSE 'Low Value'
    END AS tier
  FROM rev_per_user rpu  
)
--group by traffic_source and tier, 
--count users and calculate aggregates by source/tier combo
SELECT
  tc.tier                AS spending_tier,
  tc.traffic_source      AS acquisition_channel,
  COUNT(tc.id)           AS customer_count,
  ROUND(AVG(tc.spend),2) AS avg_lifetime_spend,
  ROUND(SUM(tc.spend),2) AS segment_revenue,
  ROUND(SUM(tc.spend) / SUM(SUM(tc.spend)) OVER()*100,2) AS segment_rev_pct
FROM tier_class tc
GROUP BY tc.tier, tc.traffic_source
ORDER BY
  CASE
    WHEN spending_tier = 'Low Value'  THEN 1
    WHEN spending_tier = 'Mid Value'  THEN 2
    WHEN spending_tier = 'High Value' THEN 3
  END,
  customer_count DESC;

-- 20d Dataset 4:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
WITH country_cleanup AS (
  SELECT 
    CASE
      WHEN LOWER(u.country) IN ('spain', 'españa') THEN 'Spain'
      WHEN LOWER(u.country) IN ('germany', 'deutschland') THEN 'Germany'
      ELSE u.country
    END           AS ctry, -- country
    u.state       AS ps,   -- political subdivision (state/province/prefecture/etc)
    u.id          AS usr,  -- users
    oi.sale_price AS rev   -- order sales
  FROM bigquery-public-data.thelook_ecommerce.users u
  JOIN bigquery-public-data.thelook_ecommerce.orders o
    ON u.id = o.user_id
  JOIN bigquery-public-data.thelook_ecommerce.order_items oi
    ON o.order_id = oi.order_id
  WHERE LOWER(oi.status) IN ('complete', 'shipped')
),
aggregate_by_entity AS (
  --aggregate revenue and count users
  --at the political subdivision level
  SELECT 
    cc.ctry       AS country,
    cc.ps         AS entity,
    COUNT(cc.usr) AS users,
    SUM(cc.rev)   AS revenue
  FROM country_cleanup cc
  GROUP BY cc.ctry, cc.ps
),
calculate_metrics AS (
  --then aggregate revenue at country level
  --for other calculations
  SELECT
    abe.country,
    abe.entity,
    abe.users,
    abe.revenue,
    abe.revenue/abe.users AS rev_usr,
    (abe.revenue / SUM(abe.revenue) OVER(PARTITION BY abe.country))*100 AS pct_within_country_revenue
  FROM aggregate_by_entity abe
),
rankings AS (
  --rank political subdivisions 
  --by revenue in descending order
  SELECT
    cm.country,
    cm.entity,
    cm.users,
    cm.revenue,
    cm.rev_usr,
    cm.pct_within_country_revenue,
    ROW_NUMBER() OVER(PARTITION BY cm.country ORDER BY cm.revenue DESC) AS entity_rank
  FROM calculate_metrics cm
  ORDER BY cm.country, entity_rank
)
--display results
SELECT
  r.country,
  r.entity                              AS country_subdivision,
  ROUND(r.revenue,2)                    AS subdivision_revenue,
  ROUND(r.pct_within_country_revenue,2) AS pct_within_country,
  r.users                               AS active_users,
  ROUND(r.rev_usr)                      AS revenue_per_user,
  r.entity_rank                         AS subdivision_rev_rank
FROM rankings r;

-- 21 Dataset 5:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SELECT 
  DATE_TRUNC(o.created_at, WEEK) AS week_start,
  CASE 
    WHEN LOWER(u.country) = 'brasil' THEN 'Brazil'
    WHEN LOWER(u.country) = 'deutschland' THEN 'Germany'
    WHEN LOWER(u.country) = 'españa' THEN 'Spain'
    ELSE u.country
  END                               AS country, 
  u.state                           AS subdivision,
  p.category,
  oi.status,
  SUM(oi.sale_price)                AS rev,
  SUM(p.cost)                       AS cost,
  SUM(oi.sale_price) > SUM(p.cost)  AS flag,
  COUNT(o.user_id)                  AS users,
  SUM(o.num_of_item)                AS qty
FROM bigquery-public-data.thelook_ecommerce.users u
JOIN bigquery-public-data.thelook_ecommerce.orders o
  ON u.id = o.user_id
JOIN bigquery-public-data.thelook_ecommerce.order_items oi
  ON o.order_id = oi.order_id
JOIN bigquery-public-data.thelook_ecommerce.products p
  ON oi.product_id = p.id
GROUP BY 
  DATE_TRUNC(o.created_at, WEEK),
  u.country, u.state, p.category, oi.status
ORDER BY week_start, country, subdivision, p.category, oi.status;

-- CHECK TABLE SCHEMA :::::::::::::::::::::::::::::::::::::::::::::::::::::::
SELECT
    column_name,
    data_type
FROM `bigquery-public-data.thelook_ecommerce.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'products'
ORDER BY ordinal_position;

-- NOTES ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
-- o.created_at: when did the customer buy?
-- oi.created_at: when did the warehouse act on it?
-- oi.status: what ultimately happened to this item?
-- u.traffic_source: original user acquisition channel, one per user, never updates
-- e.traffic_source: session channels, one per session, updates every visit (new row)


-- Reference and follow up: Claude chat session for these challenges:
-- https://claude.ai/share/0fe9f70d-9a65-435f-8941-0e9cd1d934cc


-- EOF