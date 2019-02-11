#standardSQL


-- # Challenge: For products with over 1000 units that have been added to cart or ordered that are not frisbees: 
-- How many distinct times was the product part of an order (either complete or incomplete order)? 
-- How many total units of the product were part of orders (either complete or incomplete)? 
-- Which product had the highest conversion rate?


SELECT
COUNT(*) AS product_views,
COUNT(productQuantity) AS potential_orders,
SUM(productQuantity) AS quantity_product_added,
v2ProductName,
COUNT(productQuantity) / COUNT(*) AS conversion_rate

FROM 
`data-to-insights.ecommerce.all_sessions` 
WHERE LOWER(v2ProductName) NOT LIKE '%frisbee%'
GROUP BY v2ProductName
HAVING quantity_product_added > 1000
ORDER BY conversion_rate DESC
LIMIT 10;



# Challenge 2: Write a query that shows the eCommerceAction_type 
# and the distinct count of fullVisitorId associated with each type. 

SELECT 
COUNT(DISTINCT fullVisitorId) AS number_of_unique_visitors,
eCommerceAction_type,
CASE eCommerceAction_type
WHEN '0' THEN 'Unknown'
WHEN '1' THEN 'Click through of product lists'
WHEN '2' THEN 'Product detail views'
WHEN '3' THEN 'Add product(s) to cart'
WHEN '4' THEN 'Remove product(s) from cart'
WHEN '5' THEN 'Check out'
WHEN '6' THEN 'Completed purchase'
WHEN '7' THEN 'Refund of purchase'
WHEN '8' THEN 'Checkout options'
ELSE NULL
END AS eCommerceAction_type_label

FROM 
`data-to-insights.ecommerce.all_sessions` 
GROUP BY eCommerceAction_type
ORDER BY eCommerceAction_type

# 35% add to cart and then checkout


-- The action type. 
-- Click through of product lists = 1, 
-- Product detail views = 2, 
-- Add product(s) to cart = 3, 
-- Remove product(s) from cart = 4, 
-- Check out = 5, 
-- Completed purchase = 6, 
-- Refund of purchase = 7, 
-- Checkout options = 8, 
-- Unknown = 0.



-- # Challenge 3: Write a query using aggregation functions that returns 
-- the unique session ids of those visitors who
-- have added a product to their cart but never completed checkout (abandoned their shopping cart). 
-- high quality sessions 


SELECT
CONCAT(fullVisitorId, CAST(visitId AS STRING)) AS unique_session_id, # combine to get a unique session
sessionQualityDim,
SUM(productRevenue) AS transactions_revenue,
MAX(CAST(eCommerceAction_type AS INT64)) AS checkout_progress

FROM 
`data-to-insights.ecommerce.all_sessions` 
WHERE sessionQualityDim > 60 # high quality session
GROUP BY unique_session_id, sessionQualityDim
HAVING 
checkout_progress = 3 AND # 3 = added to cart 
(transactions_revenue IS NULL OR transactions_revenue = 0)
