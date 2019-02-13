# Question 1: Find the number unique visitors who reached the checkout confirmation page in the rev_transactions table.

#standardSQL
SELECT
COUNT(DISTINCT fullVisitorId) AS visitor_count,
hits_page_pageTitle
FROM
`data-to-insights.ecommerce.rev_transactions`
WHERE hits_page_pageTitle = "Checkout Confirmation"
GROUP BY hits_page_pageTitle

# Question 2: Which cities that have the most transactions with our ecommerce site?

#standardSQL
SELECT
geoNetwork_city, 
SUM(totals_transactions) AS totals_transactions, 
COUNT(DISTINCT fullVisitorId) AS distinct_visitors
FROM
`data-to-insights.ecommerce.rev_transactions`
GROUP BY geoNetwork_city
ORDER BY distinct_visitors DESC

# Update your query and create a new calculated field to return the average number of products per order by city.

#standardSQL
SELECT
geoNetwork_city, 
SUM(totals_transactions) AS total_products_ordered, 
COUNT( DISTINCT fullVisitorId) AS distinct_visitors,
SUM(totals_transactions) / COUNT( DISTINCT fullVisitorId) AS avg_products_ordered
FROM
`data-to-insights.ecommerce.rev_transactions`
GROUP BY geoNetwork_city
ORDER BY avg_products_ordered DESC

# Filter your aggregated results to only return cities with more than 20 avg_products_ordered.

#standardSQL
SELECT
geoNetwork_city, 
SUM(totals_transactions) AS total_products_ordered, 
COUNT( DISTINCT fullVisitorId) AS distinct_visitors,
SUM(totals_transactions) / COUNT( DISTINCT fullVisitorId) AS avg_products_ordered
FROM
`data-to-insights.ecommerce.rev_transactions`
GROUP BY geoNetwork_city
HAVING avg_products_ordered > 20
ORDER BY avg_products_ordered DESC

# Question 3: Find total number of products in each product category, filtering with NULL values.

#standardSQL
SELECT 
COUNT(DISTINCT hits_product_v2ProductName) as number_of_products, 
hits_product_v2ProductCategory
FROM `data-to-insights.ecommerce.rev_transactions`
WHERE hits_product_v2ProductName IS NOT NULL
GROUP BY hits_product_v2ProductCategory
ORDER BY number_of_products DESC
LIMIT 5
