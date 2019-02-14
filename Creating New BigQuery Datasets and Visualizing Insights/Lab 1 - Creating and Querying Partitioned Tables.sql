# 1 - Creating Tables with Date Partitions

# View data processed from non-partitioned table

#standardSQL
SELECT DISTINCT 
  fullVisitorId, 
  date 
FROM `data-to-insights.ecommerce.all_sessions_raw`
WHERE date = '20180708'
LIMIT 5

-- Answer: 635 MB

# Create a new Partitioned Table based on date and view data processed with a Partitioned Table

#standardSQL
CREATE OR REPLACE TABLE ecommerce.partition_by_day
PARTITION BY date_formatted
OPTIONS(
  description="a table partitioned by date"
) AS
SELECT DISTINCT 
PARSE_DATE("%Y%m%d", date) AS date_formatted,
fullvisitorId
FROM `data-to-insights.ecommerce.all_sessions_raw`
 
#standardSQL
SELECT *
FROM ecommerce.partition_by_day
WHERE date_formatted = '2018-07-08'

-- Answer: This query will process 0 B when run because the query engine knows which partitions already
--         exist and knows no partition exists for 2018-07-08 (the ecommerce dataset ranges from
--         2016-08-01 to 2017-08-01).

# Creating an auto-expiring partitioned table from NOAA Daily Weather BigQuery Public Dataset that:
# - Queries on current year weather data
# - Filters to only include days that have had some precipitation (rain, snow, etc.)
# - Only stores each partition of data for 90 days from that partition's date (rolling window)

#standardSQL
SELECT
  DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS date,
  (SELECT ANY_VALUE(name) FROM `bigquery-public-data.noaa_gsod.stations` AS stations
   WHERE stations.usaf = stn) AS station_name,  -- Stations may have multiple names
  prcp
FROM `bigquery-public-data.noaa_gsod.gsod*` AS weather
WHERE prcp < 99.9  -- Filter unknown values
  AND prcp > 0      -- Filter stations/days with no precipitation
  AND _TABLE_SUFFIX = CAST( EXTRACT(YEAR FROM CURRENT_DATE()) AS STRING)
LIMIT 100

# Create a partitioned table with the below specifications:
# - Table name ecommerce.days_with_rain
# - Use the date field as your PARTITION BY
# - For OPTIONS, specify partition_expiration_days = 90
# - Add the table description = "weather stations with precipitation, partitioned by day"

#standardSQL
CREATE OR REPLACE TABLE ecommerce.days_with_rain
PARTITION BY date
OPTIONS (
  partition_expiration_days=90,
  description="weather stations with precipitation, partitioned by day"
) AS
SELECT
  DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS date,
  (SELECT ANY_VALUE(name) FROM `bigquery-public-data.noaa_gsod.stations` AS stations
   WHERE stations.usaf = stn) AS station_name,  -- Stations may have multiple names
  prcp
FROM `bigquery-public-data.noaa_gsod.gsod*` AS weather
WHERE prcp < 99.9  -- Filter unknown values
  AND prcp > 0      -- Filter stations/days with no precipitation
  AND _TABLE_SUFFIX = CAST( EXTRACT(YEAR FROM CURRENT_DATE()) AS STRING)
   
# Confirm data partition expiration is working

#standardSQL
# avg monthly precipitation
SELECT 
  AVG(prcp) AS average,
  station_name,
  date,
  DATE_DIFF(CURRENT_DATE(), date, DAY) AS partition_age,
EXTRACT(MONTH FROM date) AS month
FROM ecommerce.days_with_rain
WHERE station_name = 'WAKAYAMA' #Japan
GROUP BY station_name, date, month, partition_age
ORDER BY date;

-- Answer: The oldest partition_age is below is at or below 90 days, so we can confirm
--         that the data partion is working
