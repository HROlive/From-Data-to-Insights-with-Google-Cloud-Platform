# Create an empty BigQuery dataset and copies over a subset of the public raw ecommerce
# dataset to your own project dataset for you to explore and clean in Cloud Dataprep.

#standardSQL
 CREATE OR REPLACE TABLE ecommerce.all_sessions_raw_dataprep
 OPTIONS(
   description="Raw data from analyst team to ingest into Cloud Dataprep"
 ) AS
 SELECT * FROM `data-to-insights.ecommerce.all_sessions_raw`
 WHERE date = '20170801'; # limiting to one day of data 56k rows for this lab
 
# Connect BigQuery data to Cloud Dataprep

-- Create Flow -  Flow Name, type Ecommerce Analytics Pipeline - Flow Description, type 
-- Revenue reporting table for Apparel - Create - Add Datasets - Add Datasets to Flow - 
-- Import Datasets - BigQuery - ecommerce - ecommerce.all_sessions_raw_dataprep - 
-- Create dataset - Import & Add to Flow - Add new Recipe

# Explore ecommerce data fields with a UI

# Load and explore a sample of the dataset within Cloud Dataprep

# How many columns are in the dataset?
-- Answer: 32 columns

# When your pipeline is run, it will operate over the entire source dataset. How many rows does
# the sample contain?
-- Answer: About 12 thousands rows

# What is the most common value in the channelGrouping column?
-- Answer: Referral

# What are the top three countries from which sessions are originated?
-- Answer: US, India, United Kingdom

# What does the grey bar under totalTransactionRevenue represent?
-- Answer: Missing values

# What is the average timeOnSite in seconds, average pageviews, and average sessionQualityDim
# for the data sample? (Hint: Use Column Details.)
-- Answers:Average Time On Site: 942 seconds (or 15.7 minutes), Average Pageviews: 20.44 pages, 
-- Average Session Quality Dimension: 38.36

# Looking at the histogram for sessionQualityDim, are the data values evenly distributed?
-- Answer: No, they are skewed to lower values (low quality sessions), which is expected.

# What is the date range for the dataset sample?
-- Answer: 8/1/2017 (one day of data)

# Why is there a red bar under the productSKU column?
-- Answer: The red bar indicates mismatched values. Cloud Dataprep automatically identified the productSKU
.. column type as an integer. Cloud Dataprep also detected some non-integer values and therefore flagged 
-- those as mismatched. In fact, the productSKU is not always an integer (for example, a correct value might
-- be "GGOEGOCD078399"). So in this case, Cloud Dataprep incorrectly identified the column type: it should
-- be a string, not an integer.

# Looking at v2ProductName, what are the most popular products?
-- Answer: Nest products

# Looking at v2ProductCategory, what are some of the most popular products? How many categories were sampled?
-- Answer: Nest, (not set), and Apparel are the most popular out of approximately 25 categories.

# True or False: The most common productVariant is COLOR.
-- Answer: False. It's (not set) because most products do not have variants (80%+)

# What are the two categories of type?
-- Answer: PAGE and EVENT

# What is the average productQuantity?
-- Answer: 3.45 (your answer may vary)

# How many distinct SKUs are in the dataset?
-- Answer: Over 600+

# What are some of the most popular product names by row count? The most popular categories? 
-- Answer: Cam Outdoor Security Camera - USA, Cam Indoor Security Camera - USA, Learning 
-- Thermostat 3rd Gen-USA - Stainless Steel

# What is the dominant currency code for transactions?
-- Answer: USD

# Are there valid values for itemQuantity or item Revenue?
-- Answer: No, they are all NULL values.

# What percentage of transaction IDs have a valid value? What does this represent for our ecommerce dataset?
-- Answer: About 4.6% of transaction IDs have a valid value, which represents the average conversion rate of
-- the website (4.6% of visitors transact).

# How many eCommerceAction_types are there, and what is the most popular eCommerceAction_type?
-- Six types have data in our sample.

0 or NULL is the most popular.

# Clean the data

# Delete unused columns

# Deduplicate rows

# Filter out sessions without revenue

# Filter out sessions for just Type = ‘PAGE'

# Filter for apparel products

# Enrich the data

# Create a new column for a unique session ID

# Create a case statement for the ecommerce action type

# Run and schedule Cloud Dataprep jobs to BigQuery
