#standardSQL
SELECT
  COUNT(*) AS num_duplicate_row,
  *
FROM `data-to-insights.ecommerce.all_sessions_raw` 
GROUP BY 
fullVisitorId, channelGrouping, time, country, city, totalTransactionRevenue, transactions, timeOnSite, pageviews, sessionQualityDim, date, visitId, type, productRefundAmount, productQuantity, productPrice, productRevenue, productSKU, v2ProductName, v2ProductCategory, productVariant, currencyCode, itemQuantity, itemRevenue, transactionRevenue, transactionId, pageTitle, searchKeyword, pagePathLevel1, eCommerceAction_type, eCommerceAction_step, eCommerceAction_option
HAVING num_duplicate_row > 1



#standardSQL
# schema: https://support.google.com/analytics/answer/3437719?hl=en
SELECT 
fullVisitorId, # the unique visitor ID  
visitId, # a visitor can have multiple visits
date, # session date stored as string YYYYMMDD
time, # time of the individual site hit  (can be 0 to many per visitor session)
v2ProductName, # not unique since a product can have variants like Color
productSKU, # unique for each product
type, # a visitor can visit Pages and/or can trigger Events (even at the same time)
eCommerceAction_type, # maps to ‘add to cart’, ‘completed checkout’
eCommerceAction_step, 
eCommerceAction_option,
transactionRevenue, # revenue of the order
transactionId, # unique identifier for revenue bearing transaction
COUNT(*) as row_count 
FROM 
`data-to-insights.ecommerce.all_sessions` 
GROUP BY 1,2,3 ,4, 5, 6, 7, 8, 9, 10,11,12
HAVING row_count > 1 # find duplicates 



# Write a query that shows total unique visitors
SELECT
COUNT(*) AS product_views,
COUNT(DISTINCT fullVisitorId) AS unique_visitors
FROM `data-to-insights.ecommerce.all_sessions` 


-- write a query that shows total unique 
-- visitors by channel grouping (organic, referring site)
SELECT
COUNT(*) AS product_views,
COUNT(DISTINCT fullVisitorId) AS unique_visitors,
channelGrouping
FROM `data-to-insights.ecommerce.all_sessions`
GROUP BY channelGrouping
ORDER BY unique_visitors DESC
LIMIT 3;



# What are all the unique product names listed alphabetically?

SELECT
v2ProductName
FROM `data-to-insights.ecommerce.all_sessions`
GROUP BY v2ProductName
ORDER BY v2ProductName;

# Which 5 products had the most views from unique visitors viewed each product?


SELECT
COUNT(*) AS product_view,
v2ProductName
FROM `data-to-insights.ecommerce.all_sessions`
WHERE type = 'PAGE'
GROUP BY v2ProductName
ORDER BY product_view DESC
LIMIT 5;

-- Expand your previous query to include the
-- total number of distinct products ordered as well as the total number of total units ordered

SELECT
COUNT(*) AS product_view,
SUM(productQuantity) AS quantity_product_ordered,
COUNT(productQuantity) AS potential_or_completed_orders,
v2ProductName
FROM `data-to-insights.ecommerce.all_sessions`
WHERE 
  type = 'PAGE'
 # AND eCommerceAction_type = '6'

GROUP BY v2ProductName
ORDER BY product_view DESC
LIMIT 5;


# Expand the query to include the ratio of product units to order:

SELECT
COUNT(*) AS product_view,
SUM(productQuantity) AS quantity_product_ordered,
COUNT(productQuantity) AS potential_or_completed_orders,
SUM(productQuantity) / COUNT(productQuantity) AS avg_per_order,
v2ProductName
FROM `data-to-insights.ecommerce.all_sessions`
WHERE 
  type = 'PAGE'
 # AND eCommerceAction_type = '6'

GROUP BY v2ProductName
ORDER BY product_view DESC
LIMIT 5;
