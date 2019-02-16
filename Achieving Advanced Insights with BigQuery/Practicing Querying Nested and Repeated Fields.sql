# Working with Nested and Repeated Fields

# Find the top 10 nonprofits that spent the most on legal expenses in the table.
# Hint: `UNNEST( )` typically follows the `FROM` much like a JOIN and should enclose a STRUCT.

#standardSQL
# Expenses by Category for each EIN
SELECT
  ein,
  expense
FROM `data-to-insights.irs_990.irs_990_repeated` n
CROSS JOIN UNNEST(n.expense_struct) AS expense
WHERE expense.type = 'Legal'
ORDER BY expense.amount DESC
LIMIT 10

# Is there any way to simplify your previous query?

-- Yes, the `CROSS JOIN` and `UNNEST( )` can be shorthanded as shown below. The `CROSS JOIN` becomes
-- a comma and the `UNNEST( )` is optional as BigQuery assumes we want to unnest the n.expense_struct.

#standardSQL
# Expenses by Category for each EIN
SELECT
  ein,
  expense
FROM `data-to-insights.irs_990.irs_990_repeated` n, n.expense_struct AS expense
WHERE expense.type = 'Legal'
ORDER BY expense.amount DESC
LIMIT 10
