# Fixing and Troubleshooting Query Performance

# The below query is running slowly, what can you do to correct it?

#standardSQL
# count all paper filings for 2015
SELECT * FROM `bigquery-public-data.irs_990.irs_990_2015`
WHERE UPPER(elf) LIKE '%P%' #Paper Filers in 2015
ORDER BY ein 

# 86,831 as per pagination count, 23s

-- We can remove ORDER BY when there is no limit, use Aggregation Functions and
-- examine data to confirm P is always uppercase.

#standardSQL
SELECT COUNT(*) AS paper_filers FROM `bigquery-public-data.irs_990.irs_990_2015`
WHERE elf = 'P' #Paper Filers in 2015

# 86,831 at 2s

# This new below query is running slowly (run the query to get a benchmark - cancel
# after 30 seconds if it does not complete). Correct the query (hint: remember the 
# correct JOIN field condition for our schema)

#standardSQL
  # get all Organization names who filed in 2015
SELECT
  tax.ein,
  name
FROM
  `bigquery-public-data.irs_990.irs_990_2015` tax
JOIN
  `bigquery-public-data.irs_990.irs_990_ein` org
ON
  tax.tax_pd = org.tax_period

# 86,831 as per pagination count, 23s

-- Incorrect usage of JOIN key resulted in CROSS JOIN

#standardSQL
  # get all Organization names who filed in 2015
SELECT
  tax.ein,
  name
FROM
  `bigquery-public-data.irs_990.irs_990_2015` tax
JOIN
  `bigquery-public-data.irs_990.irs_990_ein` org
USING(ein)

# Correct result: 294,374 at 13s
