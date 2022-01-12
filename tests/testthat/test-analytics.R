# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/tests/unit/test_analytics.py

BUCKET_NAME = "mybucket"
REGION = "us-west-2"

sagemaker_session = function(
  describe_training_result=NULL,
  list_training_results=NULL,
  metric_stats_results=NULL,
  describe_tuning_result=NULL
  ){

  cwm_mock = Mock$new()
  cwm_mock$.call_args("get_metric_statistics")
  cwm_mock$.call_args("get_metric_statistics", side_effect = cw_request_side_effect)

  paws_mock = Mock$new(name = "PawsSession", region_name = REGION)
  paws_mock$.call_args("client", side_effect = function(service_name, ...){
    switch(service_name,
      "cloudwatch" = cwm_mock,
    )
  })

  sms = Mock$new(
    name="Session",
    paws_session=paws_mock,
    paws_region_name=REGION,
    config=NULL,
    local_mode=FALSE
  )

  sagemaker = Mock$new()
  sagemaker$.call_args("describe_hyper_parameter_tuning_job", describe_tuning_result)
  sagemaker$.call_args("describe_training_job", describe_training_result)
  sagemaker$.call_args("list_training_jobs_for_hyper_parameter_tuning_job", list_training_results)

  s3_client = Mock$new()

  sms$sagemaker = sagemaker
  sms$s3 = s3_client

  sms$.call_args("default_bucket", BUCKET_NAME)
  return(sms)
}

cw_request_side_effect = function(
  Namespace, MetricName, Dimensions, StartTime, EndTime, Period, Statistics
  ){
  if(.is_valid_request(Namespace, MetricName, Dimensions, StartTime, EndTime, Period, Statistics))
    return(.metric_stats_results())
}

.is_valid_request = function(Namespace, MetricName, Dimensions, StartTime, EndTime, Period, Statistics){
  could_watch_request = list(
    "Namespace"=Namespace,
    "MetricName"=MetricName,
    "Dimensions"=Dimensions,
    "StartTime"=StartTime,
    "EndTime"=EndTime,
    "Period"=Period,
    "Statistics"=Statistics
  )
  return(identical(could_watch_request, cw_request()))
}

cw_request = function(){
  describe_training_result = .describe_training_result()
  return(list(
    "Namespace"="/aws/sagemaker/TrainingJobs",
    "MetricName"="train:acc",
    "Dimensions"=list(list("Name"="TrainingJobName", "Value"="my-training-job")),
    "StartTime"=describe_training_result[["TrainingStartTime"]],
    "EndTime"=describe_training_result[["TrainingEndTime"]] + 60,
    "Period"=60,
    "Statistics"=list("Average")
  ))
}

.describe_training_result = function(){
  return (list(
    "TrainingStartTime"=as.POSIXct('2018-05-16 01:02:03', tz = "UTC"),
    "TrainingEndTime"=as.POSIXct('2018-05-16 05:06:07', tz = "UTC")
  ))
}

.metric_stats_results = function(){
  return(list(
    "Datapoints"=list(
      list("Average"=77.1, "Timestamp"=as.POSIXct("2018-05-16 01:03:03", tz = "UTC")),
      list("Average"=87.1, "Timestamp"=as.POSIXct("2018-05-16 01:08:03", tz = "UTC")),
      list("Average"=97.1, "Timestamp"=as.POSIXct("2018-05-16 02:03:03", tz = "UTC"))
      )
    )
  )
}

test_that("test_tuner_name", {
  sms = sagemaker_session()
  tuner = HyperparameterTuningJobAnalytics$new("my-tuning-job", sagemaker_session=sms)
  expect_equal(tuner$name, "my-tuning-job")
})

test_that("test_tuner_dataframe", {

  true_false = list(TRUE, FALSE, TRUE, FALSE, TRUE)
  has_training_job_definition_name = mock_fun(side_effect = do.call(iter, true_false))

  training_job_definition_name = "training_def_1"
  mock_summary = function(name="job-name", value=0.9){
    summary = list(
      "TrainingJobName"=name,
      "TrainingJobStatus"="Completed",
      "FinalHyperParameterTuningJobObjectiveMetric"=list("Name"="awesomeness", "Value"=value),
      "TrainingStartTime"=as.POSIXct("2018-05-18 01:02:03", tz = "UTC"),
      "TrainingEndTime"=as.POSIXct("2018-05-18 05:06:07", tz = "UTC"),
      "TunedHyperParameters"=list("learning_rate"=0.1, "layers"=137)
    )
    if (has_training_job_definition_name())
      summary[["TrainingJobDefinitionName"]] = training_job_definition_name
    return(summary)
  }

  sms = sagemaker_session(
    list_training_results=list(
      "TrainingJobSummaries"=list(
        mock_summary(),
        mock_summary(),
        mock_summary(),
        mock_summary(),
        mock_summary()
      )
  ))
  tuner = HyperparameterTuningJobAnalytics$new("my-tuning-job", sagemaker_session=sms)
  df = tuner$dataframe()
  expect_equal(
    sms$sagemaker$list_training_jobs_for_hyper_parameter_tuning_job(..count = T), 1
  )

  # Clear the cache, check that it calls the service again.
  tuner$clear_cache()
  df = tuner$dataframe()
  expect_equal(
    sms$sagemaker$list_training_jobs_for_hyper_parameter_tuning_job(..count = T), 2
  )
  df = tuner$dataframe(force_refresh = T)
  expect_equal(
    sms$sagemaker$list_training_jobs_for_hyper_parameter_tuning_job(..count = T), 3
  )

  # check that the hyperparameter is in the dataframe
  expect_equal(length(df$layers), 5)
  expect_equal(min(df$layers), 137)

  # Check that the training time calculation is returning something sane.
  expect_true(min(df$TrainingElapsedTimeSeconds) > 5)
  expect_true(max(df$TrainingElapsedTimeSeconds) < 86400)

  expect_equal(
    df$TrainingJobDefinitionName[as.logical(true_false)],
    rep(training_job_definition_name,sum(as.logical(true_false)))
  )

  # Export to CSV and check that file exists
  tmp_name = tempfile()
  expect_true(!file.exists(tmp_name))
  tuner$export_csv(tmp_name)
  expect_true(file.exists(tmp_name))
  unlink(tmp_name)
})

test_that("test_description", {
  sms = sagemaker_session(
    describe_tuning_result=list(
      "HyperParameterTuningJobConfig"=list(
        "ParameterRanges"=list(
          "CategoricalParameterRanges"=list(),
          "ContinuousParameterRanges"=list(
            list("MaxValue"="1", "MinValue"="0", "Name"="eta"),
            list("MaxValue"="10", "MinValue"="0", "Name"="gamma")
          ),
          "IntegerParameterRanges"=list(
            list("MaxValue"="30", "MinValue"="5", "Name"="num_layers"),
            list("MaxValue"="100", "MinValue"="50", "Name"="iterations")
          )
        )
      ),
      "TrainingJobDefinition"=list(
        "AlgorithmSpecification"=list(
          "TrainingImage"="training_image",
          "TrainingInputMode"="File"
        )
      )
    )
  )

  tuner = HyperparameterTuningJobAnalytics$new("my-tuning-job", sagemaker_session=sms)

  d = tuner$description()

  expect_equal(sms$sagemaker$describe_hyper_parameter_tuning_job(..count = T), 1)
  expect_true(!is.null(d))
  expect_true(!is.null(d[["HyperParameterTuningJobConfig"]]))

  tuner$clear_cache()
  d = tuner$description()
  expect_equal(sms$sagemaker$describe_hyper_parameter_tuning_job(..count = T), 2)
  d = tuner$description()
  expect_equal(sms$sagemaker$describe_hyper_parameter_tuning_job(..count = T), 2)
  d = tuner$description(force_refresh = T)
  expect_equal(sms$sagemaker$describe_hyper_parameter_tuning_job(..count = T), 3)

  r = tuner$tuning_ranges
  expect_equal(length(r), 4)
})

test_that("test_tuning_ranges_multi_training_job_definitions", {
  sms = sagemaker_session(
    describe_tuning_result=list(
      "HyperParameterTuningJobConfig"=list(),
      "TrainingJobDefinitions"=list(
        list(
          "DefinitionName"="estimator_1",
          "HyperParameterRanges"=list(
            "CategoricalParameterRanges"=list(),
            "ContinuousParameterRanges"=list(
              list("MaxValue"="1", "MinValue"="0", "Name"="eta"),
              list("MaxValue"="10", "MinValue"="0", "Name"="gamma")
            ),
            "IntegerParameterRanges"=list(
              list("MaxValue"="30", "MinValue"="5", "Name"="num_layers"),
              list("MaxValue"="100", "MinValue"="50", "Name"="iterations")
            )
          ),
          "AlgorithmSpecification"=list(
            "TrainingImage"="training_image_1",
            "TrainingInputMode"="File"
          )
        ),
        list(
          "DefinitionName"="estimator_2",
          "HyperParameterRanges"=list(
            "CategoricalParameterRanges"=list(
              list("Values"=list("TF", "MXNet"), "Name"="framework")
            ),
            "ContinuousParameterRanges"=list(
              list("MaxValue"="1.0", "MinValue"="0.2", "Name"="gamma")
            ),
            "IntegerParameterRanges"=list()
          ),
          "AlgorithmSpecification"=list(
            "TrainingImage"="training_image_2",
            "TrainingInputMode"="File"
          )
        )
      )
    )
  )
  expected_result = list(
    "estimator_1"=list(
      "eta"=list("MaxValue"="1", "MinValue"="0", "Name"="eta"),
      "gamma"=list("MaxValue"="10", "MinValue"="0", "Name"="gamma"),
      "num_layers"=list("MaxValue"="30", "MinValue"="5", "Name"="num_layers"),
      "iterations"=list("MaxValue"="100", "MinValue"="50", "Name"="iterations")
    ),
    "estimator_2"=list(
      "framework"=list("Values"=list("TF", "MXNet"), "Name"="framework"),
      "gamma"=list("MaxValue"="1.0", "MinValue"="0.2", "Name"="gamma")
    )
  )
  tuner = HyperparameterTuningJobAnalytics$new("my-tuning-job", sagemaker_session=sms)
  expect_equal(tuner$tuning_ranges, expected_result)
})

test_that("test_trainer_name", {
  describe_training_result = list(
    "TrainingStartTime"=as.POSIXct("2018-05-16 01:02:03", tz ="UTC"),
    "TrainingEndTime"= as.POSIXct("2018-05-16 05:06:07", tz = "UTC")
  )
  sms = sagemaker_session(describe_training_result)
  trainer = TrainingJobAnalytics$new("my-training-job", list("metric"), sagemaker_session=sms)
  expect_equal(trainer$name, "my-training-job")
})

test_that("test_trainer_dataframe", {
  session = sagemaker_session(
    describe_training_result=.describe_training_result(),
    metric_stats_results=.metric_stats_results()
  )
  trainer = TrainingJobAnalytics$new("my-training-job", "train:acc", sagemaker_session=session)

  df = trainer$dataframe()
  expect_true(!is.null(df))
  expect_equal(nrow(df), 3)
  expect_equal(min(df$value), 77.1)
  expect_equal(max(df$value), 97.1)

  # Export to CSV and check that file exists
  tmp_name = tempfile()
  expect_false(file.exists(tmp_name))
  trainer$export_csv(tmp_name)
  expect_true(file.exists(tmp_name))
  unlink(tmp_name)
})

test_that("test_start_time_end_time_and_period_specified", {
  describe_training_result = list(
    "TrainingStartTime"=ISOdate(2018, 5, 16, 1, 2, 3, tz = "UTC"),
    "TrainingEndTime"=ISOdate(2018, 5, 16, 5, 6, 7, tz = "UTC")
  )
  session = sagemaker_session(describe_training_result)
  start_time = ISOdate(2018, 5, 16, 1, 3, 4, tz = "UTC")
  end_time = ISOdate(2018, 5, 16, 5, 1, 1, tz = "UTC")
  period = 300
  trainer = TrainingJobAnalytics$new(
    "my-training-job",
    "metric",
    sagemaker_session=session,
    start_time=start_time,
    end_time=end_time,
    period=period
  )

  expect_equal(trainer$.time_interval[["start_time"]], start_time)
  expect_equal(trainer$.time_interval[["end_time"]], end_time)
  expect_equal(trainer$.period, period)
})
