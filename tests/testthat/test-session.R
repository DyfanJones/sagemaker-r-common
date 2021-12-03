# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/tests/unit/test_session.py

lg = lgr::get_logger("R6sagemaker")

STATIC_HPs = list("feature_dim"="784")
SAMPLE_PARAM_RANGES = list(list("Name"="mini_batch_size", "MinValue"="10", "MaxValue"="100"))
ENV_INPUT = list("env_key1"="env_val1", "env_key2"="env_val2", "env_key3"="env_val3")
REGION = "us-west-2"
STS_ENDPOINT = "sts.us-west-2.amazonaws.com"
ROLE = "SageMakerRole"

paws_session = Mock$new(
  name = "PawsSession",
  region_name = REGION
)

# Set up mock class for paws functionality
sts = Mock$new(region_name = REGION)
iam = Mock$new(region_name = REGION)
s3_client = Mock$new(region_name = REGION)
lambda_client = Mock$new(region_name = REGION)
cloudwatchlogs = Mock$new(region_name = REGION)

sagemaker_client = Mock$new(region_name = REGION)
sagemaker_client$.call_args("create_processing_job")
sagemaker_client$.call_args("delete_endpoint")
sagemaker_client$.call_args("delete_endpoint_config")
sagemaker_client$.call_args("delete_model")
sagemaker_client$.call_args("create_training_job")
sagemaker_client$.call_args("create_hyper_parameter_tuning_job")
sagemaker_client$.call_args("stop_hyper_parameter_tuning_job")
sagemaker_client$.call_args("create_transform_job")

sagemakerruntime_client = Mock$new(region_name = REGION)
athena_client = Mock$new(region_name = REGION)

paws_session$.call_args("client", side_effect = function(obj, ...){
  switch(obj,
    "sts" = sts,
    "iam" = iam,
    "cloudwatchlogs" = cloudwatchlogs,
    "sagemaker" = sagemaker_client,
    "sagemakerruntime"= sagemakerruntime_client,
    "s3"=s3_client,
    "athena" = athena_client
  )
})

test_that("test process", {
  session = Session$new(paws_session)

  process_request_args = list(
    "inputs"=list(
      list(
        "InputName"="input-1",
        "S3Input"=list(
          "S3Uri"="mocked_s3_uri_from_upload_data",
          "LocalPath"="/container/path/",
          "S3DataType"="Archive",
          "S3InputMode"="File",
          "S3DataDistributionType"="FullyReplicated",
          "S3CompressionType"="None"
        )
      ),
      list(
        "InputName"="my_dataset",
        "S3Input"=list(
          "S3Uri"="s3://path/to/my/dataset/census.csv",
          "LocalPath"="/container/path/",
          "S3DataType"="Archive",
          "S3InputMode"="File",
          "S3DataDistributionType"="FullyReplicated",
          "S3CompressionType"="None"
        )
      ),
      list(
        "InputName"="source",
        "S3Input"=list(
          "S3Uri"="mocked_s3_uri_from_upload_data",
          "LocalPath"="/code/source",
          "S3DataType"="Archive",
          "S3InputMode"="File",
          "S3DataDistributionType"="FullyReplicated",
          "S3CompressionType"="None"
        )
      )
    ),
    "output_config"=list(
      "Outputs"=list(
        list(
          "OutputName"="output-1",
          "S3Output"=list(
            "S3Uri"="s3://mybucket/current_job_name/output",
            "LocalPath"="/data/output",
            "S3UploadMode"="Continuous"
          )
        ),
        list(
          "OutputName"="my_output",
          "S3Output"=list(
            "S3Uri"="s3://uri/",
            "LocalPath"="/container/path/",
            "S3UploadMode"="Continuous"
          )
        )
      ),
      "KmsKeyId"="arn:aws:kms:us-west-2:012345678901:key/kms-key"
    ),
    "job_name"="current_job_name",
    "resources"=list(
      "ClusterConfig"=list(
        "InstanceType"="ml.m4.xlarge",
        "InstanceCount"=1,
        "VolumeSizeInGB"=100
      )
    ),
    "stopping_condition"=list("MaxRuntimeInSeconds"=3600),
    "app_specification"=list(
      "ImageUri"="520713654638.dkr.ecr.us-west-2.amazonaws.com/sagemaker-scikit-learn:0.20.0-cpu-py3",
      "ContainerArguments"=list("--drop-columns", "'SelfEmployed'"),
      "ContainerEntrypoint"=list("python3", "/code/source/sklearn_transformer.py")
    ),
    "environment"=list("my_env_variable"=20),
    "network_config"=list(
      "EnableInterContainerTrafficEncryption"=TRUE,
      "EnableNetworkIsolation"=TRUE,
      "VpcConfig"=list(
        "SecurityGroupIds"=list("my_security_group_id"),
        "Subnets"=list("my_subnet_id")
      )
    ),
    "role_arn"=ROLE,
    "tags"=list(list("Name"="my-tag", "Value"="my-tag-value")),
    "experiment_config"=list("ExperimentName"="AnExperiment")
  )

  do.call(session$process, process_request_args)

  expected_request = list(
    "ProcessingJobName"="current_job_name",
    "ProcessingResources"=list(
      "ClusterConfig"=list(
        "InstanceType"="ml.m4.xlarge",
        "InstanceCount"=1,
        "VolumeSizeInGB"=100
      )
    ),
    "AppSpecification"=list(
      "ImageUri"="520713654638.dkr.ecr.us-west-2.amazonaws.com/sagemaker-scikit-learn:0.20.0-cpu-py3",
      "ContainerArguments"=list("--drop-columns", "'SelfEmployed'"),
      "ContainerEntrypoint"=list("python3", "/code/source/sklearn_transformer.py")
    ),
    "RoleArn"=ROLE,
    "ProcessingInputs"=list(
      list(
        "InputName"="input-1",
        "S3Input"=list(
          "S3Uri"="mocked_s3_uri_from_upload_data",
          "LocalPath"="/container/path/",
          "S3DataType"="Archive",
          "S3InputMode"="File",
          "S3DataDistributionType"="FullyReplicated",
          "S3CompressionType"="None"
        )
      ),
      list(
        "InputName"="my_dataset",
        "S3Input"=list(
          "S3Uri"="s3://path/to/my/dataset/census.csv",
          "LocalPath"="/container/path/",
          "S3DataType"="Archive",
          "S3InputMode"="File",
          "S3DataDistributionType"="FullyReplicated",
          "S3CompressionType"="None"
        )
      ),
      list(
        "InputName"="source",
        "S3Input"=list(
          "S3Uri"="mocked_s3_uri_from_upload_data",
          "LocalPath"="/code/source",
          "S3DataType"="Archive",
          "S3InputMode"="File",
          "S3DataDistributionType"="FullyReplicated",
          "S3CompressionType"="None"
        )
      )
    ),
    "ProcessingOutputConfig"=list(
      "Outputs"=list(
        list(
          "OutputName"="output-1",
          "S3Output"=list(
            "S3Uri"="s3://mybucket/current_job_name/output",
            "LocalPath"="/data/output",
            "S3UploadMode"="Continuous"
          )
        ),
        list(
          "OutputName"="my_output",
          "S3Output"=list(
            "S3Uri"="s3://uri/",
            "LocalPath"="/container/path/",
            "S3UploadMode"="Continuous"
          )
        )
      ),
      "KmsKeyId"="arn:aws:kms:us-west-2:012345678901:key/kms-key"
    ),
    "Environment"=list("my_env_variable"=20),
    "NetworkConfig"=list(
      "EnableInterContainerTrafficEncryption"=TRUE,
      "EnableNetworkIsolation"=TRUE,
      "VpcConfig"=list(
        "SecurityGroupIds"=list("my_security_group_id"),
        "Subnets"=list("my_subnet_id")
      )
    ),
    "StoppingCondition"=list("MaxRuntimeInSeconds"=3600),
    "Tags"=list(list("Name"="my-tag", "Value"="my-tag-value")),
    "ExperimentConfig"=list("ExperimentName"="AnExperiment")
  )

  expect_equal(session$sagemaker$create_processing_job(..return_value = T), expected_request)
})

test_that("test get execution role", {
  session = Mock$new("Session")
  session$.call_args("get_caller_identity_arn", side_effect = function() "arn:aws:iam::369233609183:role/SageMakerRole")

  actual = get_execution_role(session)

  expect_equal(actual, "arn:aws:iam::369233609183:role/SageMakerRole")
})

test_that("test get execution role works with service role", {
  session = Mock$new("Session")
  session$.call_args("get_caller_identity_arn",
    side_effect = function() "arn:aws:iam::369233609183:role/service-role/AmazonSageMaker-ExecutionRole-20171129T072388"
  )
  actual = get_execution_role(session)

  expect_equal(actual,
    "arn:aws:iam::369233609183:role/service-role/AmazonSageMaker-ExecutionRole-20171129T072388"
  )
})

test_that("test get execution role throws exception if arn is not role", {
  session = Mock$new("Session")
  session$.call_args("get_caller_identity_arn", side_effect = function() "arn:aws:iam::369233609183:user/marcos"
  )
  expect_error(
    get_execution_role(session),
    "The current AWS identity is not a role",
    class = "ValueError"
  )
})

test_that("test get execution role throws exception if arn is not role with role in name", {
  session = Mock$new("Session")
  session$.call_args("get_caller_identity_arn", side_effect = function() "arn:aws:iam::369233609183:user/marcos-role"
  )
  expect_error(
    get_execution_role(session),
    "The current AWS identity is not a role",
    class = "ValueError"
  )
})

test_that("test delete endpoint", {
  sess = Session$new(paws_session)
  sess$delete_endpoint("my_endpoint")

  expect_equal(
    paws_session$client("sagemaker")$delete_endpoint(..return_value = T),
    list(EndpointName="my_endpoint")
  )
})

test_that("test delete endpoint config", {
  sess = Session$new(paws_session)
  sess$delete_endpoint_config("my_endpoint_config")

  expect_equal(
    paws_session$client("sagemaker")$delete_endpoint_config(..return_value = T),
    list(EndpointConfigName="my_endpoint_config")
  )
})

test_that("test delete model", {
  sess = Session$new(paws_session)
  sess$delete_model("my_model")

  expect_equal(
    paws_session$client("sagemaker")$delete_model(..return_value = T),
    list(ModelName="my_model")
  )
})

test_that("test training input all defaults", {
  prefix = "pre"
  actual = TrainingInput$new(s3_data=prefix)
  expected = list(
    "DataSource"=list(
      "S3DataSource"=list(
        "S3DataType"="S3Prefix",
        "S3Uri"=prefix,
        "S3DataDistributionType"="FullyReplicated"
      )
    )
  )

  expect_equal(actual$config, expected)
})

test_that("test training input all arguments", {
  prefix = "pre"
  distribution = "FullyReplicated"
  compression = "Gzip"
  content_type = "text/csv"
  record_wrapping = "RecordIO"
  s3_data_type = "Manifestfile"
  input_mode = "Pipe"
  actual = TrainingInput$new(
    s3_data=prefix,
    distribution=distribution,
    compression=compression,
    input_mode=input_mode,
    content_type=content_type,
    record_wrapping=record_wrapping,
    s3_data_type=s3_data_type
  )
  expected = list(
    "DataSource"=list(
      "S3DataSource"=list(
        "S3DataType"=s3_data_type,
        "S3Uri"=prefix,
        "S3DataDistributionType"=distribution
      )
    ),
    "CompressionType"=compression,
    "ContentType"=content_type,
    "RecordWrapperType"=record_wrapping,
    "InputMode"=input_mode
  )

  expect_equal(actual$config, expected)
})

IMAGE = "myimage"
S3_INPUT_URI = "s3://mybucket/data"
S3_OUTPUT = "s3://sagemaker-123/output/jobname"
ROLE = "SageMakerRole"
EXPANDED_ROLE = "arn:aws:iam::111111111111:role/ExpandedRole"
INSTANCE_COUNT = 1
INSTANCE_TYPE = "ml.c4.xlarge"
ACCELERATOR_TYPE = "ml.eia.medium"
MAX_SIZE = 30
MAX_TIME = 3 * 60 * 60
JOB_NAME = "jobname"
TAGS = list(list("Name"="some-tag", "Value"="value-for-tag"))
VPC_CONFIG = list("Subnets"=list("foo"), "SecurityGroupIds"=list("bar"))
METRIC_DEFINITONS = list(list("Name"="validation-rmse", "Regex"="validation-rmse=(\\d+)"))
EXPERIMENT_CONFIG = list(
  "ExperimentName"="dummyExp",
  "TrialName"="dummyT",
  "TrialComponentDisplayName"="dummyTC"
)
MODEL_CLIENT_CONFIG = list("InvocationsMaxRetries"=2, "InvocationsTimeoutInSeconds"=60)

DEFAULT_EXPECTED_TRAIN_JOB_ARGS = list(
  "AlgorithmSpecification"=list("TrainingInputMode"="File", "TrainingImage"=IMAGE),
  "OutputDataConfig"=list("S3OutputPath"=S3_OUTPUT),
  "TrainingJobName"=JOB_NAME,
  "StoppingCondition"=list("MaxRuntimeInSeconds"=MAX_TIME),
  "ResourceConfig"=list(
    "InstanceCount"=INSTANCE_COUNT,
    "InstanceType"=INSTANCE_TYPE,
    "VolumeSizeInGB"=MAX_SIZE
  ),
  "RoleArn"=EXPANDED_ROLE,
  "InputDataConfig"=list(
    list(
      "ChannelName"="training",
      "DataSource"=list(
        "S3DataSource"=list(
          "S3DataDistributionType"="FullyReplicated",
          "S3DataType"="S3Prefix",
          "S3Uri"=S3_INPUT_URI
        )
      )
    )
  ),
  "VpcConfig"=VPC_CONFIG,
  "ExperimentConfig"=EXPERIMENT_CONFIG
)

COMPLETED_DESCRIBE_JOB_RESULT = DEFAULT_EXPECTED_TRAIN_JOB_ARGS
COMPLETED_DESCRIBE_JOB_RESULT = modifyList(
  COMPLETED_DESCRIBE_JOB_RESULT,
  list("TrainingJobArn"=paste0("arn:aws:sagemaker:us-west-2:336:training-job/",JOB_NAME))
)
COMPLETED_DESCRIBE_JOB_RESULT = modifyList(COMPLETED_DESCRIBE_JOB_RESULT,list("TrainingJobStatus"="Completed"))
COMPLETED_DESCRIBE_JOB_RESULT = modifyList(COMPLETED_DESCRIBE_JOB_RESULT,
  list("ModelArtifacts"=list("S3ModelArtifacts"=paste0(S3_OUTPUT, "/model/model.tar.gz")))
)
# TrainingStartTime and TrainingEndTime are for billable seconds calculation
COMPLETED_DESCRIBE_JOB_RESULT = modifyList(COMPLETED_DESCRIBE_JOB_RESULT,
  list("TrainingStartTime"= as.POSIXct("2018-02-17 07:15:00.103000", tz = "UTC"))
)
COMPLETED_DESCRIBE_JOB_RESULT = modifyList(COMPLETED_DESCRIBE_JOB_RESULT,
  list("TrainingEndTime"= as.POSIXct("2018-02-17 07:19:34.953000", tz = "UTC"))
)

STOPPED_DESCRIBE_JOB_RESULT = COMPLETED_DESCRIBE_JOB_RESULT
STOPPED_DESCRIBE_JOB_RESULT = modifyList(STOPPED_DESCRIBE_JOB_RESULT,
  list("TrainingJobStatus"="Stopped")
)
IN_PROGRESS_DESCRIBE_JOB_RESULT = DEFAULT_EXPECTED_TRAIN_JOB_ARGS
IN_PROGRESS_DESCRIBE_JOB_RESULT = modifyList(IN_PROGRESS_DESCRIBE_JOB_RESULT,
  list("TrainingJobStatus"="InProgress")
)


COMPLETED_DESCRIBE_TRANSFORM_JOB_RESULT = list(
  "TransformJobStatus"="Completed",
  "ModelName"="some-model",
  "TransformJobName"=JOB_NAME,
  "TransformResources"=list("InstanceCount"=INSTANCE_COUNT, "InstanceType"=INSTANCE_TYPE),
  "TransformEndTime"=as.POSIXct("2018-02-17 07:19:34.953000", tz = "UTC"),
  "TransformStartTime"=as.POSIXct("2018-02-17 07:15:00.103000", tz = "UTC"),
  "TransformOutput"=list("AssembleWith"="None", "KmsKeyId"="", "S3OutputPath"=S3_OUTPUT),
  "TransformInput"=list(
    "CompressionType"="None",
    "ContentType"="text/csv",
    "DataSource"=list("S3DataType"="S3Prefix", "S3Uri"=S3_INPUT_URI),
    "SplitType"="Line"
  )
)

STOPPED_DESCRIBE_TRANSFORM_JOB_RESULT = COMPLETED_DESCRIBE_TRANSFORM_JOB_RESULT
STOPPED_DESCRIBE_TRANSFORM_JOB_RESULT = modifyList(STOPPED_DESCRIBE_TRANSFORM_JOB_RESULT, list("TransformJobStatus"="Stopped"))

IN_PROGRESS_DESCRIBE_TRANSFORM_JOB_RESULT = COMPLETED_DESCRIBE_TRANSFORM_JOB_RESULT
IN_PROGRESS_DESCRIBE_TRANSFORM_JOB_RESULT = modifyList(IN_PROGRESS_DESCRIBE_TRANSFORM_JOB_RESULT, list("TransformJobStatus"="InProgress"))

sts = Mock$new(region_name = REGION, endpoint_url=STS_ENDPOINT)
sts$.call_args("get_caller_identity", return_value = list(Account="123"))

paws_session$client = function(obj, ...){
  switch(obj,
    "sts" = sts,
    "iam" = iam,
    "cloudwatchlogs" = cloudwatchlogs,
    "sagemaker" = sagemaker_client,
    "sagemakerruntime"= sagemakerruntime_client,
    "s3"=s3_client,
    "athena" = athena_client
  )
}


test_that("test train pack to request", {
  sagemaker_session = Session$new(paws_session)
  in_config = list(
    list(
      "ChannelName"="training",
      "DataSource"=list(
        "S3DataSource"=list(
          "S3DataDistributionType"="FullyReplicated",
          "S3DataType"="S3Prefix",
          "S3Uri"=S3_INPUT_URI
        )
      )
    )
  )
  out_config = list("S3OutputPath"=S3_OUTPUT)

  resource_config = list(
    "InstanceCount"=INSTANCE_COUNT,
    "InstanceType"=INSTANCE_TYPE,
    "VolumeSizeInGB"=MAX_SIZE
  )
  stop_cond = list("MaxRuntimeInSeconds"=MAX_TIME)

  sagemaker_session$train(
    image_uri=IMAGE,
    input_mode="File",
    input_config=in_config,
    role=EXPANDED_ROLE,
    job_name=JOB_NAME,
    output_config=out_config,
    resource_config=resource_config,
    hyperparameters=NULL,
    stop_condition=stop_cond,
    tags=NULL,
    vpc_config=VPC_CONFIG,
    metric_definitions=NULL,
    experiment_config=EXPERIMENT_CONFIG,
    enable_sagemaker_metrics=NULL
  )

  expect_equal(
    sagemaker_session$sagemaker$create_training_job(..return_value = T),
    DEFAULT_EXPECTED_TRAIN_JOB_ARGS
  )
})

SAMPLE_STOPPING_CONDITION = list("MaxRuntimeInSeconds"=MAX_TIME)

RESOURCE_CONFIG = list(
  "InstanceCount"=INSTANCE_COUNT,
  "InstanceType"=INSTANCE_TYPE,
  "VolumeSizeInGB"=MAX_SIZE
)

SAMPLE_INPUT = list(
  list(
    "DataSource"=list(
      "S3DataSource"=list(
        "S3DataDistributionType"="FullyReplicated",
        "S3DataType"="S3Prefix",
        "S3Uri"=S3_INPUT_URI
      )
    ),
    "ChannelName"="training"
  )
)

SAMPLE_OUTPUT=list("S3OutputPath"=S3_OUTPUT)

SAMPLE_OBJECTIVE = list("Type"="Maximize", "MetricName"="val-score")
SAMPLE_OBJECTIVE_2 = list("Type"="Maximize", "MetricName"="value-score")

SAMPLE_METRIC_DEF = list(list("Name"="train:progress", "Regex"="regex-1"))
SAMPLE_METRIC_DEF_2 = list(list("Name"="value-score", "Regex"="regex-2"))

STATIC_HPs = list("feature_dim"="784")
STATIC_HPs_2 = list("gamma"="0.1")

SAMPLE_PARAM_RANGES = list(list("Name"="mini_batch_size", "MinValue"="10", "MaxValue"="100"))
SAMPLE_PARAM_RANGES_2 = list(list("Name"="kernel", "Values"=list("rbf", "sigmoid")))

SAMPLE_TUNING_JOB_REQUEST = list(
  "HyperParameterTuningJobName"="dummy-tuning-1",
  "HyperParameterTuningJobConfig"=list(
    "Strategy"="Bayesian",
    "ResourceLimits"=list("MaxNumberOfTrainingJobs"=100, "MaxParallelTrainingJobs"=5),
    "TrainingJobEarlyStoppingType"="Off",
    "HyperParameterTuningJobObjective"=SAMPLE_OBJECTIVE,
    "ParameterRanges"=SAMPLE_PARAM_RANGES
  ),
  "TrainingJobDefinition"=list(
    "StaticHyperParameters"=STATIC_HPs,
    "RoleArn"=EXPANDED_ROLE,
    "OutputDataConfig"=SAMPLE_OUTPUT,
    "ResourceConfig"=RESOURCE_CONFIG,
    "StoppingCondition"=SAMPLE_STOPPING_CONDITION,
    "AlgorithmSpecification"=list(
      "TrainingInputMode"="File",
      "MetricDefinitions"=SAMPLE_METRIC_DEF,
      "TrainingImage"="dummy-image-1"
    ),
    "InputDataConfig"=SAMPLE_INPUT
  )
)

SAMPLE_MULTI_ALGO_TUNING_JOB_REQUEST = list(
  "HyperParameterTuningJobName"="dummy-tuning-1",
  "HyperParameterTuningJobConfig"=list(
    "Strategy"="Bayesian",
    "ResourceLimits"=list("MaxNumberOfTrainingJobs"=100, "MaxParallelTrainingJobs"=5),
    "TrainingJobEarlyStoppingType"="Off"
  ),
  "TrainingJobDefinitions"=list(
    list(
      "StaticHyperParameters"=STATIC_HPs,
      "RoleArn"=EXPANDED_ROLE,
      "OutputDataConfig"=SAMPLE_OUTPUT,
      "ResourceConfig"=RESOURCE_CONFIG,
      "StoppingCondition"=SAMPLE_STOPPING_CONDITION,
      "AlgorithmSpecification"=list(
        "TrainingInputMode"="File",
        "MetricDefinitions"=SAMPLE_METRIC_DEF,
        "TrainingImage"="dummy-image-1"
      ),
      "InputDataConfig"=SAMPLE_INPUT,
      "DefinitionName"="estimator_1",
      "TuningObjective"=SAMPLE_OBJECTIVE,
      "HyperParameterRanges"=SAMPLE_PARAM_RANGES
    ),
    list(
      "StaticHyperParameters"=STATIC_HPs_2,
      "RoleArn"=EXPANDED_ROLE,
      "OutputDataConfig"=SAMPLE_OUTPUT,
      "ResourceConfig"=RESOURCE_CONFIG,
      "StoppingCondition"=SAMPLE_STOPPING_CONDITION,
      "AlgorithmSpecification"=list(
        "TrainingInputMode"="File",
        "MetricDefinitions"=SAMPLE_METRIC_DEF_2,
        "TrainingImage"="dummy-image-2"
      ),
      "InputDataConfig"=SAMPLE_INPUT,
      "DefinitionName"="estimator_2",
      "TuningObjective"=SAMPLE_OBJECTIVE_2,
      "HyperParameterRanges"=SAMPLE_PARAM_RANGES_2
    )
  )
)

# Possibly move to R6sagemaker.mlcore testing
# test_that("test tune warm start", {
#   sagemaker_session = Session$new(paws_session)
#
#   sagemaker_session$tune(
#     job_name="dummy-tuning-1",
#     strategy="Bayesian",
#     objective_type="Maximize",
#     objective_metric_name="val-score",
#     max_jobs=100,
#     max_parallel_jobs=5,
#     parameter_ranges=SAMPLE_PARAM_RANGES,
#     static_hyperparameters=STATIC_HPs,
#     image_uri="dummy-image-1",
#     input_mode="File",
#     metric_definitions=SAMPLE_METRIC_DEF,
#     role=EXPANDED_ROLE,
#     input_config=SAMPLE_INPUT,
#     output_config=SAMPLE_OUTPUT,
#     resource_config=RESOURCE_CONFIG,
#     stop_condition=SAMPLE_STOPPING_CONDITION,
#     tags=None,
#     warm_start_config=WarmStartConfig$new(
#       warm_start_type=WarmStartTypes(warm_start_type), parents=parents
#     )$to_input_req()
#   )
# })

test_that("test create tuning job without training config or list", {
  sagemaker_session = Session$new(paws_session)

  expect_error(
    sagemaker_session$create_tuning_job(
      job_name="dummy-tuning-1",
      tuning_config=list(
        "strategy"="Bayesian",
        "objective_type"="Maximize",
        "objective_metric_name"="val-score",
        "max_jobs"=100,
        "max_parallel_jobs"=5,
        "parameter_ranges"=SAMPLE_PARAM_RANGES
        )
      ),
    "Either training_config or training_config_list should be provided.",
    class="ValueError"
  )
})

test_that("test create tuning job with both training config and list", {
  sagemaker_session = Session$new(paws_session)

  expect_error(
    sagemaker_session$create_tuning_job(
      job_name="dummy-tuning-1",
      tuning_config=list(
        "strategy"="Bayesian",
        "objective_type"="Maximize",
        "objective_metric_name"="val-score",
        "max_jobs"=100,
        "max_parallel_jobs"=5,
        "parameter_ranges"=SAMPLE_PARAM_RANGES
      ),
      training_config=list("static_hyperparameters"=STATIC_HPs, "image_uri"="dummy-image-1"),
      training_config_list=list(
        list(
          "static_hyperparameters"=STATIC_HPs,
          "image_uri"="dummy-image-1",
          "estimator_name"="estimator_1"
        ),
        list(
          "static_hyperparameters"=STATIC_HPs_2,
          "image_uri"="dummy-image-2",
          "estimator_name"="estimator_2"
        )
      )
    ),
    "Only one of training_config and training_config_list should be provided.",
    class = "ValueError"
  )
})

test_that("test create tuning job", {
  sagemaker_session = Session$new(paws_session)

  sagemaker_session$create_tuning_job(
    job_name="dummy-tuning-1",
    tuning_config=list(
      "strategy"="Bayesian",
      "objective_type"="Maximize",
      "objective_metric_name"="val-score",
      "max_jobs"=100,
      "max_parallel_jobs"=5,
      "parameter_ranges"=SAMPLE_PARAM_RANGES
    ),
    training_config=list(
      "static_hyperparameters"=STATIC_HPs,
      "image_uri"="dummy-image-1",
      "input_mode"="File",
      "metric_definitions"=SAMPLE_METRIC_DEF,
      "role"=EXPANDED_ROLE,
      "input_config"=SAMPLE_INPUT,
      "output_config"=SAMPLE_OUTPUT,
      "resource_config"=RESOURCE_CONFIG,
      "stop_condition"=SAMPLE_STOPPING_CONDITION
    ),
    tags=NULL,
    warm_start_config=NULL
  )

  expect_equal(
    sagemaker_session$sagemaker$create_hyper_parameter_tuning_job(..return_value = T),
    SAMPLE_TUNING_JOB_REQUEST
  )
})

test_that("test create tuning job multi algo", {
  sagemaker_session = Session$new(paws_session)

  sagemaker_session$create_tuning_job(
    job_name="dummy-tuning-1",
    tuning_config=list("strategy"="Bayesian", "max_jobs"=100, "max_parallel_jobs"=5),
    training_config_list=list(
      list(
        "static_hyperparameters"=STATIC_HPs,
        "image_uri"="dummy-image-1",
        "input_mode"="File",
        "metric_definitions"=SAMPLE_METRIC_DEF,
        "role"=EXPANDED_ROLE,
        "input_config"=SAMPLE_INPUT,
        "output_config"=SAMPLE_OUTPUT,
        "resource_config"=RESOURCE_CONFIG,
        "stop_condition"=SAMPLE_STOPPING_CONDITION,
        "estimator_name"="estimator_1",
        "objective_type"="Maximize",
        "objective_metric_name"="val-score",
        "parameter_ranges"=SAMPLE_PARAM_RANGES
      ),
      list(
        "static_hyperparameters"=STATIC_HPs_2,
        "image_uri"="dummy-image-2",
        "input_mode"="File",
        "metric_definitions"=SAMPLE_METRIC_DEF_2,
        "role"=EXPANDED_ROLE,
        "input_config"=SAMPLE_INPUT,
        "output_config"=SAMPLE_OUTPUT,
        "resource_config"=RESOURCE_CONFIG,
        "stop_condition"=SAMPLE_STOPPING_CONDITION,
        "estimator_name"="estimator_2",
        "objective_type"="Maximize",
        "objective_metric_name"="value-score",
        "parameter_ranges"=SAMPLE_PARAM_RANGES_2
      )
    ),
    tags=NULL,
    warm_start_config=NULL
  )

  expect_equal(
    sagemaker_session$sagemaker$create_hyper_parameter_tuning_job(..return_value = T),
    SAMPLE_MULTI_ALGO_TUNING_JOB_REQUEST
  )
})


test_that("test tune", {
  sagemaker_session = Session$new(paws_session)

  sagemaker_session$tune(
    job_name="dummy-tuning-1",
    strategy="Bayesian",
    objective_type="Maximize",
    objective_metric_name="val-score",
    max_jobs=100,
    max_parallel_jobs=5,
    parameter_ranges=SAMPLE_PARAM_RANGES,
    static_hyperparameters=STATIC_HPs,
    image_uri="dummy-image-1",
    input_mode="File",
    metric_definitions=SAMPLE_METRIC_DEF,
    role=EXPANDED_ROLE,
    input_config=SAMPLE_INPUT,
    output_config=SAMPLE_OUTPUT,
    resource_config=RESOURCE_CONFIG,
    stop_condition=SAMPLE_STOPPING_CONDITION,
    tags=NULL,
    warm_start_config=NULL
  )

  expect_equal(
    sagemaker_session$sagemaker$create_hyper_parameter_tuning_job(..return_value = T),
    SAMPLE_TUNING_JOB_REQUEST
  )
})

test_that("test tune with encryption flag", {
  sagemaker_session = Session$new(paws_session)

  SAMPLE_TUNING_JOB_REQUEST_ENCRYPT = SAMPLE_TUNING_JOB_REQUEST
  SAMPLE_TUNING_JOB_REQUEST_ENCRYPT[["TrainingJobDefinition"]][["EnableInterContainerTrafficEncryption"]] = TRUE

  sagemaker_session$tune(
    job_name="dummy-tuning-1",
    strategy="Bayesian",
    objective_type="Maximize",
    objective_metric_name="val-score",
    max_jobs=100,
    max_parallel_jobs=5,
    parameter_ranges=SAMPLE_PARAM_RANGES,
    static_hyperparameters=STATIC_HPs,
    image_uri="dummy-image-1",
    input_mode="File",
    metric_definitions=SAMPLE_METRIC_DEF,
    role=EXPANDED_ROLE,
    input_config=SAMPLE_INPUT,
    output_config=SAMPLE_OUTPUT,
    resource_config=RESOURCE_CONFIG,
    stop_condition=SAMPLE_STOPPING_CONDITION,
    tags=NULL,
    warm_start_config=NULL,
    encrypt_inter_container_traffic=TRUE
  )

  expect_equal(
    sagemaker_session$sagemaker$create_hyper_parameter_tuning_job(..return_value = T),
    SAMPLE_TUNING_JOB_REQUEST_ENCRYPT
  )
})

test_that("test tune with spot and checkpoints", {
  sagemaker_session = Session$new(paws_session)

  SAMPLE_TUNING_JOB_REQUEST_CHECKPOINT = SAMPLE_TUNING_JOB_REQUEST
  SAMPLE_TUNING_JOB_REQUEST_CHECKPOINT[["TrainingJobDefinition"]][["EnableManagedSpotTraining"]] = TRUE
  SAMPLE_TUNING_JOB_REQUEST_CHECKPOINT[["TrainingJobDefinition"]][["CheckpointConfig"]][["S3Uri"]] = "s3://mybucket/checkpoints/"
  SAMPLE_TUNING_JOB_REQUEST_CHECKPOINT[["TrainingJobDefinition"]][["CheckpointConfig"]][["LocalPath"]] = "/tmp/checkpoints"

  sagemaker_session$tune(
    job_name="dummy-tuning-1",
    strategy="Bayesian",
    objective_type="Maximize",
    objective_metric_name="val-score",
    max_jobs=100,
    max_parallel_jobs=5,
    parameter_ranges=SAMPLE_PARAM_RANGES,
    static_hyperparameters=STATIC_HPs,
    image_uri="dummy-image-1",
    input_mode="File",
    metric_definitions=SAMPLE_METRIC_DEF,
    role=EXPANDED_ROLE,
    input_config=SAMPLE_INPUT,
    output_config=SAMPLE_OUTPUT,
    resource_config=RESOURCE_CONFIG,
    stop_condition=SAMPLE_STOPPING_CONDITION,
    tags=NULL,
    warm_start_config=NULL,
    use_spot_instances=TRUE,
    checkpoint_s3_uri="s3://mybucket/checkpoints/",
    checkpoint_local_path="/tmp/checkpoints"
  )

  expect_equal(
    sagemaker_session$sagemaker$create_hyper_parameter_tuning_job(..return_value = T),
    SAMPLE_TUNING_JOB_REQUEST_CHECKPOINT
  )
})

test_that("test stop tuning job", {
  sm = Session$new(paws_session)

  sm$stop_tuning_job(JOB_NAME)

  expect_equal(
    sm$sagemaker$stop_hyper_parameter_tuning_job(..return_value = T),
    list(HyperParameterTuningJobName=JOB_NAME)
  )
})

test_that("test stop tuning job client error already stopped", {
  sm = Session$new(paws_session)

  sm$sagemaker$.call_args("stop_hyper_parameter_tuning_job", side_effect = function(...){
    stop(structure(
      list(
        message = "Operation",
        error_response = list(Code="ValidationException")
        ),
      class = c("error", "condition")
      )
    )
  })

  sm$stop_tuning_job(JOB_NAME)

  expect_equal(
    sm$sagemaker$stop_hyper_parameter_tuning_job(..return_value=T),
    list(HyperParameterTuningJobName=JOB_NAME)
  )

  expect_equal(
    lg$last_event$msg,
    "Tuning job: jobname is alread stopped or not running."
  )
})

test_that("test stop tuning job client error", {
  sm = Session$new(paws_session)
  sm$sagemaker$.call_args("stop_hyper_parameter_tuning_job", side_effect = function(...){
    stop(structure(
      list(
        message = "Mock Message"
      ),
      class = c("error", "condition")
      )
    )
  })

  expect_error(
    sm$stop_tuning_job(JOB_NAME),
    "Mock Message"
  )

  expect_equal(
    sm$sagemaker$stop_hyper_parameter_tuning_job(..return_value = T),
    list(HyperParameterTuningJobName=JOB_NAME)
  )
})

test_that("test train pack to request with optional params", {
  sagemaker_session = Session$new(paws_session)

  in_config = list(
    list(
      "ChannelName"="training",
      "DataSource"=list(
        "S3DataSource"=list(
          "S3DataDistributionType"="FullyReplicated",
          "S3DataType"="S3Prefix",
          "S3Uri"=S3_INPUT_URI
        )
      )
    )
  )

  out_config = list("S3OutputPath"=S3_OUTPUT)

  resource_config = list(
    "InstanceCount"=INSTANCE_COUNT,
    "InstanceType"=INSTANCE_TYPE,
    "VolumeSizeInGB"=MAX_SIZE
  )

  stop_cond = list("MaxRuntimeInSeconds"=MAX_TIME)
  RETRY_STRATEGY = list("MaximumRetryAttempts"=2)
  hyperparameters = list("foo"="bar")

  sagemaker_session$train(
    image_uri=IMAGE,
    input_mode="File",
    input_config=in_config,
    role=EXPANDED_ROLE,
    job_name=JOB_NAME,
    output_config=out_config,
    resource_config=resource_config,
    vpc_config=VPC_CONFIG,
    hyperparameters=hyperparameters,
    stop_condition=stop_cond,
    tags=TAGS,
    metric_definitions=METRIC_DEFINITONS,
    encrypt_inter_container_traffic=TRUE,
    use_spot_instances=TRUE,
    checkpoint_s3_uri="s3://mybucket/checkpoints/",
    checkpoint_local_path="/tmp/checkpoints",
    enable_sagemaker_metrics=TRUE,
    environment=ENV_INPUT,
    retry_strategy=RETRY_STRATEGY
  )


  actual_train_args = sagemaker_session$sagemaker$create_training_job(..return_value = T)

  expect_equal(actual_train_args[["VpcConfig"]], VPC_CONFIG)
  expect_equal(actual_train_args[["HyperParameters"]], hyperparameters)
  expect_equal(actual_train_args[["Tags"]], TAGS)
  expect_equal(actual_train_args[["AlgorithmSpecification"]][["MetricDefinitions"]], METRIC_DEFINITONS)
  expect_true(actual_train_args[["AlgorithmSpecification"]][["EnableSageMakerMetricsTimeSeries"]])
  expect_true(actual_train_args[["EnableInterContainerTrafficEncryption"]])
  expect_true(actual_train_args[["EnableManagedSpotTraining"]])
  expect_equal(actual_train_args[["CheckpointConfig"]][["S3Uri"]], "s3://mybucket/checkpoints/")
  expect_equal(actual_train_args[["CheckpointConfig"]][["LocalPath"]], "/tmp/checkpoints")
  # Environment and RetryStrategy currently not supported in paws sdk
  # expect_equal(actual_train_args[["Environment"]], ENV_INPUT)
  # expect_equal(actual_train_args[["RetryStrategy"]], RETRY_STRATEGY)
})

test_that("test transform pack to request", {
  model_name = "my-model"

  sagemaker_session = Session$new(paws_session)

  in_config = list(
    "CompressionType"="None",
    "ContentType"="text/csv",
    "SplitType"="None",
    "DataSource"=list("S3DataSource"=list("S3DataType"="S3Prefix", "S3Uri"=S3_INPUT_URI))
  )

  out_config = list("S3OutputPath"=S3_OUTPUT)

  resource_config = list("InstanceCount"=INSTANCE_COUNT, "InstanceType"=INSTANCE_TYPE)

  data_processing = list("OutputFilter"="$", "InputFilter"="$", "JoinSource"="Input")

  sagemaker_session$transform(
    job_name=JOB_NAME,
    model_name=model_name,
    strategy=NULL,
    max_concurrent_transforms=NULL,
    max_payload=NULL,
    env=NULL,
    input_config=in_config,
    output_config=out_config,
    resource_config=resource_config,
    experiment_config=NULL,
    model_client_config=NULL,
    tags=NULL,
    data_processing=data_processing
  )


  actual_train_args = sagemaker_session$sagemaker$create_transform_job(..return_value = T)

  expected_args = list(
    "TransformJobName"=JOB_NAME,
    "ModelName"=model_name,
    "TransformInput"=in_config,
    "TransformOutput"=out_config,
    "TransformResources"=resource_config,
    "DataProcessing"=data_processing
  )

  expect_equal(actual_train_args, expected_args)
})

test_that("test transform pack to request with optional params", {
  strategy = "strategy"
  max_concurrent_transforms = 1
  max_payload = 0
  env = list("FOO"="BAR")

  sagemaker_session = Session$new(paws_session)

  sagemaker_session$transform(
    job_name=JOB_NAME,
    model_name="my-model",
    strategy=strategy,
    max_concurrent_transforms=max_concurrent_transforms,
    env=env,
    max_payload=max_payload,
    input_config=list(),
    output_config=list(),
    resource_config=list(),
    experiment_config=EXPERIMENT_CONFIG,
    model_client_config=MODEL_CLIENT_CONFIG,
    tags=TAGS,
    data_processing=NULL
  )

  actual_train_args = sagemaker_session$sagemaker$create_transform_job(..return_value = T)

  expect_equal(actual_train_args$BatchStrategy, strategy)
  expect_equal(actual_train_args$MaxConcurrentTransforms, max_concurrent_transforms)
  expect_equal(actual_train_args$MaxPayloadInMB, max_payload)
  expect_equal(actual_train_args$Environment, env)
  expect_equal(actual_train_args$Tags, TAGS)
  expect_equal(actual_train_args$ExperimentConfig, EXPERIMENT_CONFIG)
  expect_equal(actual_train_args$ModelClientConfig, MODEL_CLIENT_CONFIG)
})

DEFAULT_LOG_STREAMS = list("logStreams"=list(list("logStreamName"=paste0(JOB_NAME ,"/xxxxxxxxx"))))
LIFECYCLE_LOG_STREAMS = list(
  list("Error"= list("Code"="ResourceNotFoundException")),
  DEFAULT_LOG_STREAMS,
  DEFAULT_LOG_STREAMS,
  DEFAULT_LOG_STREAMS,
  DEFAULT_LOG_STREAMS,
  DEFAULT_LOG_STREAMS,
  DEFAULT_LOG_STREAMS
)

DEFAULT_LOG_EVENTS = list(
  list("nextForwardToken"=NULL, "events"=list(list("timestamp"=1, "message"="hi there #1"))),
  list("nextForwardToken"=NULL, "events"=list())
)
STREAM_LOG_EVENTS = list(
  list("nextForwardToken"=NULL, "events"=list(list("timestamp"=1, "message"="hi there #1"))),
  list("nextForwardToken"=NULL, "events"=list()),
  list(
    "nextForwardToken"=NULL,
    "events"=list(
      list("timestamp"=1, "message"="hi there #1"),
      list("timestamp"=2, "message"="hi there #2")
    )
  ),
  list("nextForwardToken"=NULL, "events"=list()),
  list(
    "nextForwardToken"=NULL,
    "events"=list(
      list("timestamp"=2, "message"="hi there #2"),
      list("timestamp"=2, "message"="hi there #2a"),
      list("timestamp"=3, "message"="hi there #3")
    )
  ),
  list("nextForwardToken"=NULL, "events"=list())
)

sagemaker_session_complete <-function(){
  paws_sess = Mock$new(
    name = "PawsSession",
    region_name = REGION
  )

  # Set up mock class for paws functionality
  cl = Mock$new(region_name = REGION)
  cl$.call_args("describe_log_streams", return_value=DEFAULT_LOG_STREAMS)
  cl$.call_args("get_log_events", return_value=DEFAULT_LOG_EVENTS)

  sm = Mock$new(region_name = REGION)
  sm$.call_args("describe_training_job", return_value = COMPLETED_DESCRIBE_JOB_RESULT)
  sm$.call_args("describe_transform_job", return_value = COMPLETED_DESCRIBE_TRANSFORM_JOB_RESULT)

  paws_sess$.call_args("client", side_effect = function(obj, ...){
    switch(obj,
           "sts" = sts,
           "iam" = iam,
           "cloudwatchlogs" = cl,
           "sagemaker" = sm,
           "sagemakerruntime"= sagemakerruntime_client,
           "s3"=s3_client,
           "athena" = athena_client
    )
  })
  return(paws_sess)
}

sagemaker_session_stopped <- function(){
  paws_sess = Mock$new(
    name = "PawsSession",
    region_name = REGION
  )

  # Set up mock class for paws functionality
  cl = Mock$new(region_name = REGION)
  cl$.call_args("describe_log_streams", return_value=DEFAULT_LOG_STREAMS)
  cl$.call_args("get_log_events", return_value=DEFAULT_LOG_EVENTS)

  sm = Mock$new(region_name = REGION)
  sm$.call_args("describe_training_job", return_value = STOPPED_DESCRIBE_JOB_RESULT)
  sm$.call_args("describe_transform_job", return_value = STOPPED_DESCRIBE_TRANSFORM_JOB_RESULT)

  paws_sess$.call_args("client", side_effect = function(obj, ...){
    switch(obj,
           "sts" = sts,
           "iam" = iam,
           "cloudwatchlogs" = cl,
           "sagemaker" = sm,
           "sagemakerruntime"= sagemakerruntime_client,
           "s3"=s3_client,
           "athena" = athena_client
    )
  })
  return(paws_sess)
}

sagemaker_session_ready_lifecycle <- function(){
  paws_sess = Mock$new(
    name = "PawsSession",
    region_name = REGION
  )
  # Set up mock class for paws functionality
  cl = Mock$new(region_name = REGION)
  cl$.call_args("describe_log_streams", return_value=DEFAULT_LOG_STREAMS)
  cl$.call_args("get_log_events", return_value=STREAM_LOG_EVENTS)

  sm = Mock$new(region_name = REGION)
  sm$.call_args("describe_training_job", side_effect = iter(
      list(
        IN_PROGRESS_DESCRIBE_JOB_RESULT,
        IN_PROGRESS_DESCRIBE_JOB_RESULT,
        COMPLETED_DESCRIBE_JOB_RESULT
      )
    )
  )

  sm$.call_args("describe_transform_job", side_effect = iter(
      list(
        IN_PROGRESS_DESCRIBE_TRANSFORM_JOB_RESULT,
        IN_PROGRESS_DESCRIBE_TRANSFORM_JOB_RESULT,
        COMPLETED_DESCRIBE_TRANSFORM_JOB_RESULT
      )
    )
  )

  paws_sess$.call_args("client", side_effect = function(obj, ...){
    switch(obj,
           "sts" = sts,
           "iam" = iam,
           "cloudwatchlogs" = cl,
           "sagemaker" = sm,
           "sagemakerruntime"= sagemakerruntime_client,
           "s3"=s3_client,
           "athena" = athena_client
    )
  })
  return(paws_sess)
}

sagemaker_session_full_lifecycle <- function(){
  paws_sess = Mock$new(
    name = "PawsSession",
    region_name = REGION
  )

  # Set up mock class for paws functionality
  cl = Mock$new(region_name = REGION)
  cl$.call_args("describe_log_streams", return_value=DEFAULT_LOG_STREAMS)
  cl$.call_args("get_log_events", return_value=STREAM_LOG_EVENTS)

  sm = Mock$new(region_name = REGION)
  sm$.call_args("describe_training_job", side_effect = iter(
      list(
        IN_PROGRESS_DESCRIBE_JOB_RESULT,
        IN_PROGRESS_DESCRIBE_JOB_RESULT,
        COMPLETED_DESCRIBE_JOB_RESULT
      )
    )
  )

  sm$.call_args("describe_transform_job", side_effect = iter(
      list(
        IN_PROGRESS_DESCRIBE_TRANSFORM_JOB_RESULT,
        IN_PROGRESS_DESCRIBE_TRANSFORM_JOB_RESULT,
        COMPLETED_DESCRIBE_TRANSFORM_JOB_RESULT
      )
    )
  )

  paws_sess$.call_args("client", side_effect = function(obj, ...){
    switch(obj,
           "sts" = sts,
           "iam" = iam,
           "cloudwatchlogs" = cl,
           "sagemaker" = sm,
           "sagemakerruntime"= sagemakerruntime_client,
           "s3"=s3_client,
           "athena" = athena_client
    )
  })
  return(paws_sess)
}

test_that("test logs for job no wait", {
  ims = Session$new(sagemaker_session_complete())
  ims$logs_for_job(JOB_NAME)
  expect_equal(
    ims$sagemaker$describe_training_job(..return_value = T),
    list(
      TrainingJobName=JOB_NAME
    )
  )
})

test_that("test logs for job no wait stopped job", {
  ims = Session$new(sagemaker_session_stopped())
  ims$logs_for_job(JOB_NAME)
  expect_equal(
    ims$sagemaker$describe_training_job(..return_value = T),
    list(
      TrainingJobName=JOB_NAME
    )
  )
})

test_that("test logs for job wait on completed", {
  ims = Session$new(sagemaker_session_complete())
  ims$logs_for_job(JOB_NAME, wait=TRUE, poll=0)
  expect_equal(
    ims$sagemaker$describe_training_job(..return_value = T),
    list(
      TrainingJobName=JOB_NAME
    )
  )
})

test_that("test logs for job wait on stopped", {
  ims = Session$new(sagemaker_session_stopped())
  ims$logs_for_job(JOB_NAME, wait=TRUE, poll=0)
  expect_equal(
    ims$sagemaker$describe_training_job(..return_value = T),
    list(
      TrainingJobName=JOB_NAME
    )
  )
})

test_that("test logs for job no wait on running", {
  ims = Session$new(sagemaker_session_ready_lifecycle())
  ims$logs_for_job(JOB_NAME)
  expect_equal(
    ims$sagemaker$describe_training_job(..return_value = T),
    list(
      TrainingJobName=JOB_NAME
    )
  )
})

test_that("test logs for job full lifecycle", {
  ims = Session$new(sagemaker_session_ready_lifecycle())

  # stub Sys.time within logs_for_job method
  assign("Sys.time", iter(list(0, 30, 60, 90, 120, 150, 180)), envir = environment(ims$logs_for_job))

  ims$logs_for_job(JOB_NAME, wait=TRUE, poll = 0)
  expect_equal(
    ims$sagemaker$describe_training_job(..return_value = T),
    list(
      TrainingJobName=JOB_NAME
    )
  )
})

