# Visually explore Google BigQuery data tables inside of Google Data Studio by
# looking for relationships and insights between fields in your dataset.

# Create a Blank Report

-- Blank template - Create new data source - Connectors, BigQuery - My Projects - Custom Query

#standardSQL
SELECT * FROM 
`data-to-insights.irs_990.irs_990_2015_reporting`

-- Connect - Add to report

# Create a Bar Chart to Compare Revenue and Expenses

# Are there any insights you can glean from the relationship between total revenue and total
# functional expenses by looking at the bar chart?

-- Answer: Generally for these Non-Profits, Revenue matches Expenses for the year.

# Create a Data Table to show Employee Counts

# Create a Scatter Chart to show financial ratios

# What is the relationship between the liabilities and net assets of Non-Profit Organizations
# bellow the mean-line?

-- Answer: Non-Profit Organizations below an imaginary diagonal line mean they have fewer 
-- liabilities relative to net assets.
