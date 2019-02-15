# Practice Unioning and Joining Datasets

# Write a Query that will count the number of tax filings by calendar year for all IRS Form 990 filings

#standardSQL
SELECT
  COUNT(*) as number_of_filings,
  _TABLE_SUFFIX AS year_filed
FROM `bigquery-public-data.irs_990.irs_990_*`
GROUP BY year_filed 
ORDER BY year_filed DESC

# Modify the query you just wrote to only include the IRS tables with the following format: 
# `irs_990_YYYY` (i.e. filter out pf, ez, ein).

#standardSQL
SELECT
  COUNT(*) as number_of_filings,
  CONCAT("2",_TABLE_SUFFIX) AS year_filed
FROM `bigquery-public-data.irs_990.irs_990_2*`
GROUP BY year_filed 
ORDER BY year_filed DESC

# Modify your query to only include tax filings from tables on or after 2013. Also include average `totrevenue`
# and average `totfuncexpns` as additional metrics.
# Hint: Consider using `_TABLE_SUFFIX` in a filter

#standardSQL
SELECT
  CONCAT("20",_TABLE_SUFFIX) AS year_filed,
  COUNT(ein) AS nonprofit_count,
  AVG(totrevenue) AS avg_revenue,
  AVG(totfuncexpns) AS avg_expenses
FROM `bigquery-public-data.irs_990.irs_990_20*`
WHERE _TABLE_SUFFIX >= '13'
GROUP BY year_filed
ORDER BY year_filed DESC

# Practice Joining Tables

# Find the Org Names of all EINs for 2015 with some revenue or expenses. You will need to join tax filing table
# data with the organization details table.

#standardSQL
SELECT
  tax.ein AS tax_ein,
  org.ein AS org_ein,
  org.name,
  tax.totrevenue,
  tax.totfuncexpns
FROM
  `bigquery-public-data.irs_990.irs_990_2015` AS tax
JOIN
  `bigquery-public-data.irs_990.irs_990_ein` AS org
ON
  tax.ein = org.ein
WHERE
  tax.totrevenue + tax.totfuncexpns > 0
LIMIT
  100;
  
# Practicing Working with NULLs

# Write a query to find where tax records exist for 2015 but no corresponding Org Name

#standardSQL
SELECT
  tax.ein AS tax_ein,
  org.ein AS org_ein,
  org.name,
  tax.totrevenue,
  tax.totfuncexpns
FROM
  `bigquery-public-data.irs_990.irs_990_2015` tax
FULL JOIN
  `bigquery-public-data.irs_990.irs_990_ein` org
ON
  tax.ein = org.ein
WHERE
  org.ein IS NULL
  
# How many tax filings occurred in 2015 but have no corresponding record in the Organization Details table?

-- Answer: 5,338
