# In this lab, you will explore millions of New York City yellow taxi cab trips available
# in a BigQuery Public Dataset. Then you will create a machine learning model inside of 
# BigQuery to predict the fare of the cab ride given your model inputs. Lastly, you will 
# evaluate the performance of your model and make predictions.

# Explore NYC taxi cab data

# Question: How many trips did Yellow taxis take each month in 2015?

#standardSQL
SELECT
  TIMESTAMP_TRUNC(pickup_datetime,
    MONTH) month,
  COUNT(*) trips
FROM
  `bigquery-public-data.new_york.tlc_yellow_trips_2015`
GROUP BY
  1
ORDER BY
  1
  
-- Answer:
-- 1	 2015-01-01 00:00:00 UTC	12748986
-- 2	 2015-02-01 00:00:00 UTC	12450521
-- 3	 2015-03-01 00:00:00 UTC	13351609
-- 4	 2015-04-01 00:00:00 UTC	13071789
-- 5	 2015-05-01 00:00:00 UTC	13158262
-- 6	 2015-06-01 00:00:00 UTC	12324935
-- 7	 2015-07-01 00:00:00 UTC	11562783
-- 8	 2015-08-01 00:00:00 UTC	11130304
-- 9	 2015-09-01 00:00:00 UTC	11225063
-- 10	 2015-10-01 00:00:00 UTC	12315488
-- 11	 2015-11-01 00:00:00 UTC	11312676
-- 12	 2015-12-01 00:00:00 UTC	11460573

# Question: What was the average speed of Yellow taxi trips in 2015?

#standardSQL
SELECT
  EXTRACT(HOUR
  FROM
    pickup_datetime) hour,
  ROUND(AVG(trip_distance / TIMESTAMP_DIFF(dropoff_datetime,
        pickup_datetime,
        SECOND))*3600, 1) speed
FROM
  `bigquery-public-data.new_york.tlc_yellow_trips_2015`
WHERE
  trip_distance > 0
  AND fare_amount/trip_distance BETWEEN 2
  AND 10
  AND dropoff_datetime > pickup_datetime
GROUP BY
  1
ORDER BY
  1
  
-- Answer: During the day, the average speed is around 11-12 MPH; but at 5:00 AM the
-- average speed almost doubles to 21 MPH. Intuitively this makes sense since there is
-- likely less traffic on the road at 5:00 AM.
  
# Identify an objective

# You will now create a machine learning model in BigQuery to predict the price of a cab
# ride in New York City given the historical dataset of trips and trip data. Predicting 
# the fare before the ride could be very useful for trip planning for both the rider and
# the taxi agency.

# Select features and create your training dataset

# Your team decides to test whether these below fields are good inputs to your fare forecasting model:

# - Tolls Amount
# - Fare Amount
# - Hour of Day
# - Pick up address
# - Drop off address
# - Number of passengers

#standardSQL
WITH params AS (
    SELECT
    1 AS TRAIN,
    2 AS EVAL
    ),

  daynames AS
    (SELECT ['Sun', 'Mon', 'Tues', 'Wed', 'Thurs', 'Fri', 'Sat'] AS daysofweek),

  taxitrips AS (
  SELECT
    (tolls_amount + fare_amount) AS total_fare,
    daysofweek[ORDINAL(EXTRACT(DAYOFWEEK FROM pickup_datetime))] AS dayofweek,
    EXTRACT(HOUR FROM pickup_datetime) AS hourofday,
    pickup_longitude AS pickuplon,
    pickup_latitude AS pickuplat,
    dropoff_longitude AS dropofflon,
    dropoff_latitude AS dropofflat,
    passenger_count AS passengers
  FROM
    `nyc-tlc.yellow.trips`, daynames, params
  WHERE
    trip_distance > 0 AND fare_amount > 0
    AND MOD(ABS(FARM_FINGERPRINT(CAST(pickup_datetime AS STRING))),1000) = params.TRAIN
  )

  SELECT *
  FROM taxitrips
  
Note a few things about the query:

The main part of the query is at the bottom: (SELECT * from taxitrips).
taxitrips does the bulk of the extraction for the NYC dataset, with the SELECT containing your training features and label.
The WHERE removes data that you don't want to train on.
The WHERE also includes a sampling clause to pick up only 1/1000th of the data.
We define a variable called TRAIN so that you can quickly build an independent EVAL set.

# What is the label (correct answer)?

-- Answer: total_fare is the label (what we will be predicting). You created this field out of tolls_amount
-- and fare_amount, so you could ignore customer tips as part of the model as they are discretionary.

In the Create Dataset dialog:

For Dataset ID, type taxi.

# Select a BQML model type and specify options

Enter the following query to create a model and specify model options, replacing -- paste the previous training
dataset query here with the training dataset query you created earlier (omitting the #standardSQL line):

#standardSQL
CREATE or REPLACE MODEL taxi.taxifare_model
OPTIONS
  (model_type='linear_reg', labels=['total_fare']) AS
-- paste the previous training dataset query here

# Evaluate classification model performance

# Select your performance criteria

For linear regression models you want to use a loss metric like Root Mean Squared Error. You want to keep training and improving the model until it has the lowest RMSE.

In BQML, mean_squared_error is a queryable field when evaluating your trained ML model. Add a SQRT() to get RMSE.

Now that training is complete, you can evaluate how well the model performs with this query using ML.EVALUATE:

#standardSQL
SELECT
  SQRT(mean_squared_error) AS rmse
FROM
  ML.EVALUATE(MODEL taxi.taxifare_model,
  (

  WITH params AS (
    SELECT
    1 AS TRAIN,
    2 AS EVAL
    ),

  daynames AS
    (SELECT ['Sun', 'Mon', 'Tues', 'Wed', 'Thurs', 'Fri', 'Sat'] AS daysofweek),

  taxitrips AS (
  SELECT
    (tolls_amount + fare_amount) AS total_fare,
    daysofweek[ORDINAL(EXTRACT(DAYOFWEEK FROM pickup_datetime))] AS dayofweek,
    EXTRACT(HOUR FROM pickup_datetime) AS hourofday,
    pickup_longitude AS pickuplon,
    pickup_latitude AS pickuplat,
    dropoff_longitude AS dropofflon,
    dropoff_latitude AS dropofflat,
    passenger_count AS passengers
  FROM
    `nyc-tlc.yellow.trips`, daynames, params
  WHERE
    trip_distance > 0 AND fare_amount > 0
    AND MOD(ABS(FARM_FINGERPRINT(CAST(pickup_datetime AS STRING))),1000) = params.EVAL
  )

  SELECT *
  FROM taxitrips

  ))
  
You are now evaluating the model against a different set of taxi cab trips with your params.EVAL filter.

After the model runs, review your model results (your model RMSE value will vary slightly).

After evaluating your model you get a RMSE of $9.47. Knowing whether or not this loss metric is acceptable to productionalize your model is entirely dependent on your benchmark criteria, which is set before model training begins. Benchmarking is establishing a minimum level of model performance and accuracy that is acceptable.

# Compare training and evaluation loss

You want to make sure that you aren't overfitting your model to your data. Overfitting your model will make it perform worse on new, unseen data. You can compare the training loss to the evaluation loss with ML.TRAINING_INFO.

SELECT * FROM ML.TRAINING_INFO(model `taxi.taxifare_model`); 

This will select all the information from each iteration of the model training. It'll include the training iteration number, the training loss, and the evaluation loss. To compare training and evaluation loss, let's explore the difference in the loss curves visually. Click Explore in Data Studio. This will open Data Studio with the data from your query connected as an input source.

Once in Data Studio, click the Combo Chart icon.

Under Dimension, drag over iteration. Under Metric, drag over both loss and eval_loss. You should get a chart which features a line chart super imposed over a bar chart.

The training loss matches the evaluation loss nearly identically, which indicates that we are not overfitting the model. Excellent! Let's move on to prediction.

# Predict taxi fare amount

#standardSQL
SELECT
*
FROM
  ml.PREDICT(MODEL `taxi.taxifare_model`,
   (

 WITH params AS (
    SELECT
    1 AS TRAIN,
    2 AS EVAL
    ),

  daynames AS
    (SELECT ['Sun', 'Mon', 'Tues', 'Wed', 'Thurs', 'Fri', 'Sat'] AS daysofweek),

  taxitrips AS (
  SELECT
    (tolls_amount + fare_amount) AS total_fare,
    daysofweek[ORDINAL(EXTRACT(DAYOFWEEK FROM pickup_datetime))] AS dayofweek,
    EXTRACT(HOUR FROM pickup_datetime) AS hourofday,
    pickup_longitude AS pickuplon,
    pickup_latitude AS pickuplat,
    dropoff_longitude AS dropofflon,
    dropoff_latitude AS dropofflat,
    passenger_count AS passengers
  FROM
    `nyc-tlc.yellow.trips`, daynames, params
  WHERE
    trip_distance > 0 AND fare_amount > 0
    AND MOD(ABS(FARM_FINGERPRINT(CAST(pickup_datetime AS STRING))),1000) = params.EVAL
  )

  SELECT *
  FROM taxitrips

));

