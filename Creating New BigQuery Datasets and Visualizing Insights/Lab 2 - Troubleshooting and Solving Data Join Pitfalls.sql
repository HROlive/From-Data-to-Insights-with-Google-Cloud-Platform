# Identifying a key field in our ecommerce dataset

# Identifying Duplicate Records

# How many products are on the website?

#standardSQL
SELECT DISTINCT 
productSKU, 
v2ProductName
FROM `data-to-insights.ecommerce.all_sessions_raw`

-- Answer: 2,273 products and SKUs

# Does that mean we have 2,273 unique product SKUs?

#standardSQL
# find the number of unique SKUs
SELECT 
DISTINCT 
productSKU
FROM `data-to-insights.ecommerce.all_sessions_raw`

-- Answer: We have 1,909 distinct SKUs which does not match 2,273 as we expected.

# Do some product names have more than one SKU?

#standardSQL
SELECT 
DISTINCT 
COUNT(DISTINCT productSKU) AS SKU_count,
STRING_AGG(DISTINCT productSKU LIMIT 5) AS SKU,
v2ProductName
FROM `data-to-insights.ecommerce.all_sessions_raw` 
WHERE productSKU IS NOT NULL
GROUP BY v2ProductName
HAVING SKU_count > 1
ORDER BY SKU_count DESC

-- Answer: Yes, for example, Waze Women's Typography Short Sleeve Tee has 12 different SKUs.

# Why would one product have more than one SKU from a business perspective?

-- Answer: One product name (e.g. T-Shirt) can have multiple product variants like color, size, etc.
-- It is expected that one product have many SKUs.

# Are there single SKU values with more than one product name associated? 
# What do you notice about those product names?

#standardSQL
SELECT 
DISTINCT 
COUNT(DISTINCT v2ProductName) AS product_count,
STRING_AGG(DISTINCT v2ProductName LIMIT 5) AS product_name,
productSKU
FROM `data-to-insights.ecommerce.all_sessions_raw` 
WHERE v2ProductName IS NOT NULL
GROUP BY productSKU
HAVING product_count > 1
ORDER BY product_count DESC

-- Answer: Yes, it looks like there are quite a few SKUs that have more than one product name.
-- Several of the product names appear to be closely related with a few misspellings (e.g. 
-- Micro Wireless Earbud vs Micro Wireless Earbuds).

# Let's see why this could be an issue

-- A SKU is designed to uniquely identify one product and will be the basis of our join 
-- condition when we join against other tables. Having a non-unique key can cause serious
-- data issues.

# Write a query to identify all the product names for the SKU 'GGOEGPJC019099'
# What are the differences in name for this product?

#standardSQL
# multiple records for this SKU
SELECT DISTINCT 
v2ProductName,
productSKU
FROM `data-to-insights.ecommerce.all_sessions_raw`
WHERE productSKU = 'GGOEGPJC019099'

-- Answer: Looking at the query results, there is a special character in one name and a slightly
-- different name for another: 7&quot; Dog Frisbee, 7" Dog Frisbee, Google 7-inch Dog Flying Disc Blue

# Joining website data against our product inventory list

# Is the SKU unique in the product inventory dataset?

#standardSQL
SELECT * FROM `data-to-insights.ecommerce.products` 
WHERE SKU = 'GGOEGPJC019099'

-- Answer: Yes, just one record is returned.

# How many dog frisbees do we have in inventory?

-- Answer: 154

# What happens when we join the website table and the product inventory table on SKU? Do we now have 
# inventory stock levels for the product?

#standardSQL
SELECT DISTINCT 
website.v2ProductName,
website.productSKU,
inventory.stockLevel
FROM `data-to-insights.ecommerce.all_sessions_raw` AS website
JOIN `data-to-insights.ecommerce.products` AS inventory
ON website.productSKU = inventory.SKU
WHERE productSKU = 'GGOEGPJC019099'

-- Answer: Yes but the stockLevel is showing three times (one for each record)

# Run a query that will show the total stock level for each item in inventory. Is the dog frisbee properly
# showing a stock level of 154?

#standardSQL
SELECT 
  productSKU, 
  SUM(stockLevel) AS total_inventory
FROM (
  SELECT DISTINCT 
  website.v2ProductName,
  website.productSKU,
  inventory.stockLevel
  FROM `data-to-insights.ecommerce.all_sessions_raw` AS website
  JOIN `data-to-insights.ecommerce.products` AS inventory
  ON website.productSKU = inventory.SKU
  WHERE productSKU = 'GGOEGPJC019099'
)
GROUP BY productSKU

-- Answer: No. It is 154 x 3 = 462

# Write a query to return the count of distinct productSKU from `data-to-insights.ecommerce.all_sessions_raw`

#standardSQL
SELECT 
COUNT(DISTINCT website.productSKU) AS distinct_sku_count 
FROM `data-to-insights.ecommerce.all_sessions_raw` AS website

-- Answer: 1,909 distinct SKUs from the website dataset

# Join against our product inventory dataset again. How many records were returned? All 1,909 distinct SKUs?

#standardSQL
SELECT DISTINCT 
website.productSKU 
FROM `data-to-insights.ecommerce.all_sessions_raw` AS website
JOIN `data-to-insights.ecommerce.products` AS inventory
ON website.productSKU = inventory.SKU

Answer: No, just 1,090 records. We lost 819 SKUs after joining the datasets.

# Write a query that uses a different join type to include all records from the website table regardless of
# whether there is a match on a product inventory SKU record.

#standardSQL
SELECT DISTINCT 
website.productSKU AS website_SKU,
inventory.SKU AS inventory_SKU
FROM `data-to-insights.ecommerce.all_sessions_raw` AS website
LEFT JOIN `data-to-insights.ecommerce.products` AS inventory
ON website.productSKU = inventory.SKU

# Write a query to filter on NULL values from the inventory table. How many products are missing?

#standardSQL
SELECT DISTINCT 
website.productSKU AS website_SKU,
inventory.SKU AS inventory_SKU
FROM `data-to-insights.ecommerce.all_sessions_raw` AS website
LEFT JOIN `data-to-insights.ecommerce.products` AS inventory
ON website.productSKU = inventory.SKU
WHERE inventory.SKU IS NULL

-- Answer: 819 products are missing (SKU IS NULL) from our product inventory dataset.

# Are there any products are in the product inventory dataset but missing from the website? 
# Write a query using a different join type to investigate.

#standardSQL
SELECT DISTINCT 
website.productSKU AS website_SKU,
inventory.SKU AS inventory_SKU
FROM `data-to-insights.ecommerce.all_sessions_raw` AS website
RIGHT JOIN `data-to-insights.ecommerce.products` AS inventory
ON website.productSKU = inventory.SKU
WHERE website.productSKU IS NULL

-- Answer: Yes. There are two product SKUs missing from the website dataset

# What if you wanted one query that listed all products missing from either the website or inventory?
# Write a query using a different join type.

#standardSQL
SELECT DISTINCT 
website.productSKU AS website_SKU,
inventory.SKU AS inventory_SKU
FROM `data-to-insights.ecommerce.all_sessions_raw` AS website
FULL JOIN `data-to-insights.ecommerce.products` AS inventory
ON website.productSKU = inventory.SKU
WHERE website.productSKU IS NULL OR inventory.SKU IS NULL

-- Answer: We have our 819 + 2 = 821 product SKUs

# Create a new table(using a CROSS JOIN) with a site-wide discount perfect that we want applied across
# products in the Clearance category.How many products are in clearance?

#standardSQL
CREATE OR REPLACE TABLE ecommerce.site_wide_promotion AS
SELECT .05 AS discount;

SELECT DISTINCT
productSKU,
v2ProductCategory,
discount
FROM `data-to-insights.ecommerce.all_sessions_raw` AS website
CROSS JOIN ecommerce.site_wide_promotion
WHERE v2ProductCategory LIKE '%Clearance%'

-- Answer: 82

# What will happen when we apply the discount again across all 82 clearance products?
# How many products are returned?

#standardSQL
# now what happens:
SELECT DISTINCT
productSKU,
v2ProductCategory,
discount
FROM `data-to-insights.ecommerce.all_sessions_raw` AS website
CROSS JOIN ecommerce.site_wide_promotion
WHERE v2ProductCategory LIKE '%Clearance%'

# Deduplicating Rows with ARRAY_AGG()

# Start with the query to show all product names per SKU.

#standardSQL
SELECT 
DISTINCT 
COUNT(DISTINCT v2ProductName) AS product_count,
STRING_AGG(DISTINCT v2ProductName LIMIT 5) AS product_name,
productSKU
FROM `data-to-insights.ecommerce.all_sessions_raw` 
WHERE v2ProductName IS NOT NULL
GROUP BY productSKU
HAVING product_count > 1
ORDER BY product_count DESC

# Since most of the product names are extremely similar (and we want to map a single SKU to a single product)
# write a query to only choose one of the product_names.

#standardSQL
# take the one name associated with a SKU
WITH product_query AS (
  SELECT 
  DISTINCT 
  v2ProductName,
  productSKU
  FROM `data-to-insights.ecommerce.all_sessions_raw` 
  WHERE v2ProductName IS NOT NULL 
)

SELECT k.* FROM (
  # aggregate the products into an array and 
  # only take 1 result
  SELECT ARRAY_AGG(x LIMIT 1)[OFFSET(0)] k 
  FROM product_query x 
  GROUP BY productSKU # this is the field we want deduplicated
);
