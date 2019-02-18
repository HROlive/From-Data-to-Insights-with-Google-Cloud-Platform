# Explore ecommerce data

# Scenario: Your data analyst team exported the Google Analytics logs for an ecommerce
# website into BigQuery and created a new table of all the raw ecommerce visitor session
# data for you to explore. Using this data, you'll try to answer a few questions.

# Question: Out of the total visitors who visited our website, what % made a purchase?

#standardSQL
WITH visitors AS(
SELECT 
COUNT(DISTINCT fullVisitorId) AS total_visitors
FROM `data-to-insights.ecommerce.web_analytics`
),

purchasers AS(
SELECT 
COUNT(DISTINCT fullVisitorId) AS total_purchasers
FROM `data-to-insights.ecommerce.web_analytics`
WHERE totals.transactions IS NOT NULL
)

SELECT 
  total_visitors, 
  total_purchasers, 
  total_purchasers / total_visitors AS conversion_rate
FROM visitors, purchasers

-- Answer: 2.698%

# Question: What are the top 5 selling products?

#standardSQL
SELECT 
  p.v2ProductName,
  p.v2ProductCategory,
  SUM(p.productQuantity) AS units_sold,
  ROUND(SUM(p.localProductRevenue/1000000),2) AS revenue
FROM `data-to-insights.ecommerce.web_analytics`,
UNNEST(hits) AS h,
UNNEST(h.product) AS p
GROUP BY 1, 2
ORDER BY revenue DESC
LIMIT 5;

-- Answer: Nest® Learning Thermostat 3rd Gen-USA - Stainless Steel, Nest® Cam Outdoor
-- Security Camera - USA, Nest® Cam Indoor Security Camera - USA, Nest® Protect Smoke
-- + CO White Wired Alarm-USA, Nest® Protect Smoke + CO White Battery Alarm-USA

# Question: How many visitors bought on subsequent visits to our website?

#standardSQL
# visitors who bought on a return visit (could have bought on first as well
WITH all_visitor_stats AS (
SELECT
  fullvisitorid, # 741,721 unique visitors
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit 
  FROM `data-to-insights.ecommerce.web_analytics` 
  GROUP BY fullvisitorid
)
  
SELECT 
  COUNT(DISTINCT fullvisitorid) AS total_visitors,
  will_buy_on_return_visit
FROM all_visitor_stats
GROUP BY will_buy_on_return_visit

-- Answer: Analyzing the results, we can see that (11873 / 729848) = 1.6% of total visitors
-- will return and purchase from the website. This includes the subset of visitors who bought
-- on their very first session and then came back and bought again.

# Question: What are some of the reasons a typical ecommerce customer will browse but not buy until a later visit?

-- Answer: Although there is no one right answer, one popular reason is comparison shopping between
-- different ecommerce sites before ultimately making a purchase decision. This is very common for
-- luxury goods where significant upfront research and comparison is required by the customer before
-- deciding(car purchases) but also true to a lesser extent for the merchandise the site (t-shirts, 
-- accessories etc). In the world of online marketing, identifying and marketing to these future 
-- customers based on the characteristics of their first visit will increase conversion rates and
-- reduce the outflow to competitor sites.

# Identify an objective

# We will now create a Machine Learning model in BigQuery to predict whether or not a new user is 
# likely to purchase in the future. Identifying these high-value users can help your marketing team
# target them with special promotions and ad campaigns to ensure a conversion while they comparison
# shop between visits to our ecommerce site.

# Select features and create your training dataset

# Your team decides to test whether these two fields are good inputs for your classification model:
# - Totals.bounces (whether the visitor left the website immediately)
# - totals.timeOnSite (how long the visitor was on our website)

# Question: What are the risks of only using the above two fields?

# Answer: Machine learning is only as good as the training data that is fed into it. If there isn't
enough information for the model to determine and learn the relationship between your input features
# and your label (in our case, whether the visitor bought in the future) then you will not have an 
# accurate model. While training a model on just these two fields is a start, we will see if they're
# good enough to produce an accurate model.

#standardSQL
SELECT
  * EXCEPT(fullVisitorId)
FROM

  # features 
  (SELECT
    fullVisitorId,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site
  FROM
    `data-to-insights.ecommerce.web_analytics`
  WHERE
    totals.newVisits = 1)
  JOIN
  (SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
      `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid)
  USING (fullVisitorId)
ORDER BY time_on_site DESC
LIMIT 10;

# Question: Which two fields are known after a visitor's first session?

-- Answer: bounces and time_on_site are known after a visitor's first session.

# Question: Which field isn't known until later in the future?

-- Answer: will_buy_on_return_visit is not known after the first visit. Again, you're predicting for
-- a subset of users who returned to your website and purchased. Since you don't know the future at
-- prediction time, you cannot say with certainty whether a new visitor come back and purchase. 
-- The value of building a ML model is to get the probability of future purchase based on the data 
-- gleaned about their first session.

# Question: Looking at the initial data results, do you think time_on_site and bounces will be a good
# indicator of whether the user will return and purchase or not?

-- Answer: It's often too early to tell before training and evaluating the model, but at first glance
-- out of the top 10 time_on_site only 1 customer returned to buy which isn't very promising. Let's see
-- how well the model does.

# Select a BQML model type and specify options

#standardSQL

CREATE OR REPLACE MODEL `ecommerce.classification_model`
OPTIONS
(
model_type='logistic_reg', 
labels = ['will_buy_on_return_visit']
) 
AS

#standardSQL
SELECT
  * EXCEPT(fullVisitorId)
FROM

  # features 
  (SELECT
    fullVisitorId,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site
  FROM
    `data-to-insights.ecommerce.web_analytics`
  WHERE
    totals.newVisits = 1
    AND date BETWEEN '20160801' AND '20170430') # train on first 9 months
  JOIN
  (SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
      `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid)
  USING (fullVisitorId)
;

# Evaluate classification model performance

# Select your performance criteria

-- For classification problems in ML, you want to minimize the False Positive Rate (i.e. predict that the
-- user will return and purchase and they don't) and maximize the True Positive Rate (predict that the user
-- will return and purchase and they do).
-- This relationship is visualized with a ROC curve (Receiver Operating Characteristic) like the one shown 
-- here, where you try to maximize the area under the curve.
-- In BQML, roc_auc is simply a queryable field when evaluating your trained ML model.

#standardSQL
SELECT
  roc_auc,
  CASE 
    WHEN roc_auc > .9 THEN 'good'
    WHEN roc_auc > .8 THEN 'fair'
    WHEN roc_auc > .7 THEN 'decent'
    WHEN roc_auc > .6 THEN 'not great'
  ELSE 'poor' END AS model_quality
FROM
  ML.EVALUATE(MODEL ecommerce.classification_model,  (

SELECT
  * EXCEPT(fullVisitorId)
FROM

  # features 
  (SELECT
    fullVisitorId,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site
  FROM
    `data-to-insights.ecommerce.web_analytics`
  WHERE
    totals.newVisits = 1
    AND date BETWEEN '20170501' AND '20170630') # eval on 2 months
  JOIN
  (SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
      `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid)
  USING (fullVisitorId)
));

-- Answer: After evaluating our model we get a roc_auc of 0.72458, which shows the model has decent,
-- but not great, predictive power. Since the goal is to get the area under the curve as close to
-- 1.0 as possible there is room for improvement.

# Improve model performance with Feature Engineering

# As we hinted at earlier, there are many more features in the dataset that may help the model better 
# understand the relationship between a visitor's first session and the likelihood that they will 
# purchase on a subsequent visit.

# - Let's add these new features and create your second machine learning model which we will call classification_model_2:
# - How far the visitor got in the checkout process on their first visit
# - Where the visitor came from (traffic source: organic search, referring site etc..)
# - Device category (mobile, tablet, desktop)
# - Geographic information (country)

#standardSQL
CREATE OR REPLACE MODEL `ecommerce.classification_model_2`
OPTIONS
  (model_type='logistic_reg', labels = ['will_buy_on_return_visit']) AS

WITH all_visitor_stats AS (
SELECT
  fullvisitorid,
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit 
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid
)

# add in new features
SELECT * EXCEPT(unique_session_id) FROM (

  SELECT
      CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,

      # labels
      will_buy_on_return_visit,

      MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,

      # behavior on the site
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site,
      totals.pageviews,

      # where the visitor came from
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,

      # mobile or desktop
      device.deviceCategory, 

      # geographic
      IFNULL(geoNetwork.country, "") AS country

  FROM `data-to-insights.ecommerce.web_analytics`,
     UNNEST(hits) AS h

    JOIN all_visitor_stats USING(fullvisitorid)

  WHERE 1=1
    # only predict for new visits
    AND totals.newVisits = 1
    AND date BETWEEN '20160801' AND '20170430' # train 9 months

  GROUP BY
  unique_session_id,
  will_buy_on_return_visit,
  bounces,
  time_on_site,
  totals.pageviews,
  trafficSource.source,
  trafficSource.medium,
  channelGrouping,
  device.deviceCategory,
  country
);

# Evaluate classification model performance

# Note that we are still training on the same first 9 months of data even with this new model.
# It's important to have the same training dataset so we can be certain a better model output
# is attributable to better input features and not new or different training data.

#standardSQL
SELECT
  roc_auc,
  CASE 
    WHEN roc_auc > .9 THEN 'good'
    WHEN roc_auc > .8 THEN 'fair'
    WHEN roc_auc > .7 THEN 'decent'
    WHEN roc_auc > .6 THEN 'not great'
  ELSE 'poor' END AS model_quality
FROM
  ML.EVALUATE(MODEL ecommerce.classification_model_2,  (

WITH all_visitor_stats AS (
SELECT
  fullvisitorid,
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit 
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid
)

# add in new features
SELECT * EXCEPT(unique_session_id) FROM (

  SELECT
      CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,

      # labels
      will_buy_on_return_visit,

      MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,

      # behavior on the site
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site,
      totals.pageviews,

      # where the visitor came from
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,

      # mobile or desktop
      device.deviceCategory, 

      # geographic
      IFNULL(geoNetwork.country, "") AS country

  FROM `data-to-insights.ecommerce.web_analytics`,
     UNNEST(hits) AS h

    JOIN all_visitor_stats USING(fullvisitorid)

  WHERE 1=1
    # only predict for new visits
    AND totals.newVisits = 1
    AND date BETWEEN '20170501' AND '20170630' # eval 2 months

  GROUP BY
  unique_session_id,
  will_buy_on_return_visit,
  bounces,
  time_on_site,
  totals.pageviews,
  trafficSource.source,
  trafficSource.medium,
  channelGrouping,
  device.deviceCategory,
  country
)
));

-- Answer: With the new model we now get a roc_auc of 0.91 which is significantly better than the first model.

# Predict which new visitors will come back and purchase

# Write a query to predict which new visitors will come back and make a purchase.The prediction must use the
# improved classification model you trained above to predict the probability that a first-time visitor to the
# Google Merchandise Store will make a purchase in a later visit. The predictions are made on the last 1 month
# (out of 12 months) of the dataset.

#standardSQL
SELECT
*
FROM
  ml.PREDICT(MODEL `ecommerce.classification_model_2`,
   (

WITH all_visitor_stats AS (
SELECT
  fullvisitorid,
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit 
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid
)


  SELECT
      CONCAT(fullvisitorid, '-',CAST(visitId AS STRING)) AS unique_session_id,

      # labels
      will_buy_on_return_visit,

      MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,

      # behavior on the site
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site,
      totals.pageviews,

      # where the visitor came from
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,

      # mobile or desktop
      device.deviceCategory, 

      # geographic
      IFNULL(geoNetwork.country, "") AS country

  FROM `data-to-insights.ecommerce.web_analytics`,
     UNNEST(hits) AS h

    JOIN all_visitor_stats USING(fullvisitorid)

  WHERE
    # only predict for new visits
    totals.newVisits = 1
    AND date BETWEEN '20170701' AND '20170801' # test 1 month

  GROUP BY
  unique_session_id,
  will_buy_on_return_visit,
  bounces,
  time_on_site,
  totals.pageviews,
  trafficSource.source,
  trafficSource.medium,
  channelGrouping,
  device.deviceCategory,
  country
)

)
ORDER BY
  predicted_will_buy_on_return_visit DESC;
  
# What conclusions can you get from the results?

-- Of the top 6% of first-time visitors (sorted in decreasing order of predicted probability),
-- more than 6% make a purchase in a later visit.
-- These users represent nearly 50% of all first-time visitors who make a purchase in a later visit.
-- Overall, only 0.7% of first-time visitors make a purchase in a later visit.
-- Targeting the top 6% of first-time increases marketing ROI by 9x vs targeting them all.

# Additional information
# Tip: add warm_start = true to your model options if you are retraining new data on an existing model
# for faster training times. Note that you cannot change the feature columns (this would necessitate a
# new model).

# roc_auc is just one of the performance metrics available during model evaluation. Also available are
# accuracy, precision, and recall. Knowing which performance metric to rely on is highly dependent on 
# what your overall objective or goal is.
