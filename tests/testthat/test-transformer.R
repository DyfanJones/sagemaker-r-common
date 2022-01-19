# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/tests/unit/test_transformer.py

MODEL_NAME = "model"
IMAGE_URI = "image-for-model"
JOB_NAME = "job"

INSTANCE_COUNT = 1
INSTANCE_TYPE = "ml.m4.xlarge"
KMS_KEY_ID = "kms-key-id"

S3_DATA_TYPE = "S3Prefix"
S3_BUCKET = "bucket"
DATA = sprintf("s3://%s/input-data", S3_BUCKET)
OUTPUT_PATH = sprintf("s3://%s/output", S3_BUCKET)
DEFAULT_REGION = "us-west-2"
DEFAULT_CONFIG = list("local"=list("local_code"=TRUE, "region_name"=DEFAULT_REGION))

TIMESTAMP = "2018-07-12"

INIT_PARAMS = list(
  "model_name"=MODEL_NAME,
  "instance_count"=INSTANCE_COUNT,
  "instance_type"=INSTANCE_TYPE,
  "base_transform_job_name"=JOB_NAME
)

MODEL_DESC_PRIMARY_CONTAINER = list("PrimaryContainer"=list("Image"=IMAGE_URI))

MODEL_DESC_CONTAINERS_ONLY = list("Containers"= list(list("Image"=IMAGE_URI)))

tf = function(sagemaker_session) {
  Transformer$new(
    MODEL_NAME,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sagemaker_session,
    volume_kms_key=KMS_KEY_ID
  )
}

sagemaker_session = function(region=DEFAULT_REGION){
  paws_mock = Mock$new(
    name = "PawsSession",
    region_name = region
  )

  sms = Mock$new(
    name="Session",
    paws_session=paws_mock,
    paws_region_name=region,
    config=NULL,
    local_mode=FALSE,
    s3=NULL
  )

  sagemaker = Mock$new()
  sagemaker$.call_args("describe_model")

  s3_client = Mock$new()

  sms$.call_args("delete_model")
  sms$.call_args("logs_for_transform_job")
  sms$.call_args("transform")
  sms$sagemaker = sagemaker
  sms$s3 = s3_client
  return(sms)
}

sagemaker_local_session = function(region=DEFAULT_REGION, config=DEFAULT_CONFIG){
  paws_mock = Mock$new(
    name = "PawsSession",
    region_name = region
  )
  sms = Mock$new(
    name="LocalSession",
    paws_session=paws_mock,
    paws_region_name=region,
    config=config,
    local_mode=TRUE,
    s3=NULL
  )
  sagemaker = Mock$new()

  s3_client = Mock$new()

  sms$sagemaker = sagemaker
  sms$s3 = s3_client
  return(sms)
}


test_that("test_delete_model", {
  sms = sagemaker_session()
  transformer = Transformer$new(
    MODEL_NAME, INSTANCE_COUNT, INSTANCE_TYPE, sagemaker_session=sms
  )
  transformer$delete_model()
  expect_equal(sms$delete_model(..return_value = T), list(MODEL_NAME))
})

test_that("test_transformer_fails_without_model", {
  sms = sagemaker_local_session()
  transformer = Transformer$new(
    model_name="remote-model",
    sagemaker_session=sms,
    instance_type="local",
    instance_count=1
  )
  expect_error(
    transformer$transform("empty-data"),
    paste("Failed to fetch model information for remote-model.",
    "Please ensure that the model exists.",
    "Local instance types require locally created models."),
    class = "ValueError"
  )
})

test_that("test_transformer_init", {
  sms = sagemaker_session()
  transformer = Transformer$new(
    MODEL_NAME, INSTANCE_COUNT, INSTANCE_TYPE, sagemaker_session=sms
  )
  expect_equal(transformer$model_name, MODEL_NAME)
  expect_equal(transformer$instance_count, INSTANCE_COUNT)
  expect_equal(transformer$instance_type, INSTANCE_TYPE)
  expect_equal(transformer$sagemaker_session, sms)

  expect_null(transformer$.current_job_name)
  expect_null(transformer$latest_transform_job)
  expect_false(transformer$.reset_output_path)
})

test_that("test_transformer_init_optional_params", {
  strategy = "MultiRecord"
  assemble_with = "Line"
  accept = "text/csv"
  max_concurrent_transforms = 100
  max_payload = 100
  tags = list("Key"="foo", "Value"="bar")
  env = list("FOO"="BAR")
  sms = sagemaker_session()
  transformer = Transformer$new(
    MODEL_NAME,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    strategy=strategy,
    assemble_with=assemble_with,
    output_path=OUTPUT_PATH,
    output_kms_key=KMS_KEY_ID,
    accept=accept,
    max_concurrent_transforms=max_concurrent_transforms,
    max_payload=max_payload,
    tags=tags,
    env=env,
    base_transform_job_name=JOB_NAME,
    sagemaker_session=sms,
    volume_kms_key=KMS_KEY_ID
  )

  expect_equal(transformer$model_name, MODEL_NAME)
  expect_equal(transformer$strategy, strategy)
  expect_equal(transformer$env, env)
  expect_equal(transformer$output_path, OUTPUT_PATH)
  expect_equal(transformer$output_kms_key, KMS_KEY_ID)
  expect_equal(transformer$accept, accept)
  expect_equal(transformer$assemble_with, assemble_with)
  expect_equal(transformer$instance_count, INSTANCE_COUNT)
  expect_equal(transformer$instance_type, INSTANCE_TYPE)
  expect_equal(transformer$volume_kms_key, KMS_KEY_ID)
  expect_equal(transformer$max_concurrent_transforms, max_concurrent_transforms)
  expect_equal(transformer$max_payload, max_payload)
  expect_equal(transformer$tags, tags)
  expect_equal(transformer$base_transform_job_name, JOB_NAME)
})

test_that("test_transform_with_all_params", {
  content_type = "text/csv"
  compression = "Gzip"
  split = "Line"
  input_filter = "$.feature"
  output_filter = "$['sagemaker_output', 'id']"
  join_source = "Input"
  experiment_config = list(
    "ExperimentName"="exp",
    "TrialName"="t",
    "TrialComponentDisplayName"="tc"
  )
  model_client_config = list("InvocationsTimeoutInSeconds"=60, "InvocationsMaxRetries"=2)
  sms = sagemaker_session()
  transformer = tf(sms)
  mock_start_new = mock_fun("dummy")
  mock_r6_private(transformer, ".start_new", mock_start_new)

  transformer$transform(
    DATA,
    S3_DATA_TYPE,
    content_type=content_type,
    compression_type=compression,
    split_type=split,
    job_name=JOB_NAME,
    input_filter=input_filter,
    output_filter=output_filter,
    join_source=join_source,
    experiment_config=experiment_config,
    model_client_config=model_client_config
  )
  expect_equal(transformer$.current_job_name, JOB_NAME)
  expect_equal(transformer$output_path, OUTPUT_PATH)
  expect_equal(mock_start_new(..return_value = T), list(
    DATA,
    S3_DATA_TYPE,
    content_type,
    compression,
    split,
    input_filter,
    output_filter,
    join_source,
    experiment_config,
    model_client_config
  ))
})

test_that("test_transform_with_base_job_name_provided", {
  base_name = "base-job-name"
  full_name = sprintf("%s-%s", base_name, TIMESTAMP)
  sms = sagemaker_session()
  transformer = tf(sms)

  transformer$base_transform_job_name = base_name
  mock_name_from_base = mock_fun(full_name)
  with_mock(
    `sagemaker.core::name_from_base` = mock_name_from_base,
    {
      transformer$transform(DATA)
      expect_equal(mock_name_from_base(..return_value = T), list(base_name))
      expect_equal(transformer$.current_job_name, full_name)
    }
  )
})

test_that("test_transform_with_base_name", {
  full_name = sprintf("%s-%s", IMAGE_URI, TIMESTAMP)
  sms = sagemaker_session()
  transformer = tf(sms)
  mock_name_from_base = mock_fun(full_name)
  mock_start_new = mock_fun("dummy")
  mock_retrieve_base_name = mock_fun(IMAGE_URI)
  mock_r6_private(transformer, ".start_new", mock_start_new)
  mock_r6_private(transformer, ".retrieve_base_name", mock_retrieve_base_name)
  with_mock(
    `sagemaker.core::name_from_base` = mock_name_from_base,
    {
      transformer$transform(DATA)
      expect_equal(mock_name_from_base(..return_value = T), list(IMAGE_URI))
      expect_equal(mock_retrieve_base_name(..count = T), 1)
      expect_equal(transformer$.current_job_name, full_name)
    }
  )
})

test_that("test_transform_with_job_name_based_on_containers", {
  sms = sagemaker_session()
  sms$sagemaker$.call_args("describe_model", c(MODEL_DESC_PRIMARY_CONTAINER, MODEL_DESC_CONTAINERS_ONLY))
  transformer = tf(sms)
  full_name = sprintf("%s-%s", IMAGE_URI, TIMESTAMP)
  mock_name_from_base = mock_fun(full_name)
  mock_start_new = mock_fun("dummy")
  mock_r6_private(transformer, ".start_new", mock_start_new)
  with_mock(
    `sagemaker.core::name_from_base` = mock_name_from_base,
    {
      transformer$transform(DATA)
      expect_equal(mock_name_from_base(..return_value = T), list(IMAGE_URI))
      expect_equal(transformer$.current_job_name, full_name)
    }
  )
})

test_that("test_transform_with_job_name_based_on_model_name", {
  sms = sagemaker_session()
  sms$sagemaker$.call_args("describe_model",
    list(list("PrimaryContainer"=list()), list("Containers"=list(list())), list())
  )
  transformer = tf(sms)
  full_name = sprintf("%s-%s", MODEL_NAME, TIMESTAMP)
  mock_name_from_base = mock_fun(full_name)
  mock_start_new = mock_fun("dummy")
  mock_r6_private(transformer, ".start_new", mock_start_new)
  with_mock(
    `sagemaker.core::name_from_base` = mock_name_from_base,
    {
      transformer$transform(DATA)
      expect_equal(sms$sagemaker$describe_model(..return_value = T), list(
        ModelName=MODEL_NAME
      ))
      expect_equal(mock_name_from_base(..return_value = T), list(MODEL_NAME))
      expect_equal(transformer$.current_job_name, full_name)
    }
  )
})

test_that("test_transform_with_generated_output_path", {
  sms = sagemaker_session()
  transformer = tf(sms)
  transformer$output_path = NULL
  sms$.call_args("default_bucket", S3_BUCKET)
  transformer$transform(DATA, job_name=JOB_NAME)
  expect_equal(transformer$output_path, sprintf("s3://%s/%s",S3_BUCKET, JOB_NAME))
})

test_that("test_transform_with_invalid_s3_uri", {
  sms = sagemaker_session()
  transformer = tf(sms)
  expect_error(
    transformer$transform("not-an-s3-uri"),
    "Invalid S3 URI",
    class = "ValueError"
  )
})

test_that("test_retrieve_image_uri", {
  sage_mock = sagemaker_session()
  sage_mock$sagemaker$.call_args("describe_model", list("PrimaryContainer"=list("Image"=IMAGE_URI)))
  transformer = tf(sage_mock)

  expect_equal(transformer$.__enclos_env__$private$.retrieve_image_uri(), IMAGE_URI)
})

test_that("ensure_last_transform_job", {
  sms = sagemaker_session()
  transformer = tf(sms)
  transformer$latest_transform_job = "latest_transform_job"
  transformer$wait()
  expect_equal(sms$logs_for_transform_job(..count = T), 1)
})

test_that("test_ensure_last_transform_job_exists", {
  sms = sagemaker_session()
  transformer = tf(sms)
  transformer$latest_transform_job = "some-transform-job"
  expect_null(transformer$.__enclos_env__$private$.ensure_last_transform_job())
})

test_that("test_ensure_last_transform_job_none", {
  sms = sagemaker_session()
  transformer = tf(sms)
  expect_error(
    transformer$.__enclos_env__$private$.ensure_last_transform_job(),
    "No transform job available",
    class = "ValueError"
  )
})

test_that("test_attach", {
  sms1 = sagemaker_session()
  sms2 = sagemaker_session()
  sms2$sagemaker$.call_args("describe_transform_job")
  transformer = tf(sms1)
  mock_prepare_init_params_from_job_desc = mock_fun(INIT_PARAMS)
  mock_r6_private(transformer,
    ".prepare_init_params_from_job_description",
    mock_prepare_init_params_from_job_desc
  )
  attached = transformer$attach(JOB_NAME, sms2)
  expect_equal(mock_prepare_init_params_from_job_desc(..count = T), 1)
  expect_equal(attached$latest_transform_job, JOB_NAME)
  expect_equal(attached$model_name, MODEL_NAME)
  expect_equal(attached$instance_count, INSTANCE_COUNT)
  expect_equal(attached$instance_type, INSTANCE_TYPE)
})

test_that("test_prepare_init_params_from_job_description_missing_keys", {
  job_details = list(
    "ModelName"=MODEL_NAME,
    "TransformResources"=list("InstanceCount"=INSTANCE_COUNT, "InstanceType"=INSTANCE_TYPE),
    "TransformOutput"=list("S3OutputPath"=NULL),
    "TransformJobName"=JOB_NAME
  )
  sms = sagemaker_session()
  transformer = tf(sms)
  init_params = transformer$.__enclos_env__$private$.prepare_init_params_from_job_description(job_details)
  expect_equal(init_params[["model_name"]], MODEL_NAME)
  expect_equal(init_params[["instance_count"]], INSTANCE_COUNT)
  expect_equal(init_params[["instance_type"]], INSTANCE_TYPE)
})

test_that("test_prepare_init_params_from_job_description_all_keys", {
  job_details = list(
    "ModelName"=MODEL_NAME,
    "TransformResources"=list(
      "InstanceCount"=INSTANCE_COUNT,
      "InstanceType"=INSTANCE_TYPE,
      "VolumeKmsKeyId"=KMS_KEY_ID
    ),
    "BatchStrategy"=NULL,
    "TransformOutput"=list(
      "AssembleWith"=NULL,
      "S3OutputPath"=NULL,
      "KmsKeyId"=NULL,
      "Accept"=NULL
    ),
    "MaxConcurrentTransforms"=NULL,
    "MaxPayloadInMB"=NULL,
    "TransformJobName"=JOB_NAME
  )
  sms = sagemaker_session()
  transformer = tf(sms)
  init_params = transformer$.__enclos_env__$private$.prepare_init_params_from_job_description(job_details)
  expect_equal(init_params[["model_name"]], MODEL_NAME)
  expect_equal(init_params[["instance_count"]], INSTANCE_COUNT)
  expect_equal(init_params[["instance_type"]], INSTANCE_TYPE)
  expect_equal(init_params[["volume_kms_key"]], KMS_KEY_ID)
})

test_that("test_start_new", {
  input_config = "input"
  output_config = "output"
  resource_config = "resource"
  strategy = "MultiRecord"
  max_concurrent_transforms = 100
  max_payload = 100
  tags = list("Key"="foo", "Value"="bar")
  env = list("FOO"="BAR")

  sms = sagemaker_session()
  transformer = Transformer$new(
    MODEL_NAME,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    strategy=strategy,
    output_path=OUTPUT_PATH,
    max_concurrent_transforms=max_concurrent_transforms,
    max_payload=max_payload,
    tags=tags,
    env=env,
    sagemaker_session=sms
  )
  transformer$.current_job_name=JOB_NAME

  mock_load_config = mock_fun(list(
    "input_config"=input_config,
    "output_config"=output_config,
    "resource_config"=resource_config
  ))
  mock_prepare_data_processing = mock_fun("dummy")
  mock_r6_private(transformer, ".load_config", mock_load_config)
  mock_r6_private(transformer, ".prepare_data_processing", mock_prepare_data_processing)

  content_type = "text/csv"
  compression_type = "Gzip"
  split_type = "Line"
  io_filter = "$"
  join_source = "Input"
  model_client_config = list("InvocationsTimeoutInSeconds"=60, "InvocationsMaxRetries"=2)

  job = transformer$.__enclos_env__$private$.start_new(
    data=DATA,
    data_type=S3_DATA_TYPE,
    content_type=content_type,
    compression_type=compression_type,
    split_type=split_type,
    input_filter=io_filter,
    output_filter=io_filter,
    join_source=join_source,
    experiment_config=list("ExperimentName"="exp"),
    model_client_config=model_client_config
  )

  expect_equal(job, JOB_NAME)
  expect_equal(mock_load_config(..return_value = T) ,list(
    DATA, S3_DATA_TYPE, content_type, compression_type, split_type
  ))
  expect_equal(mock_prepare_data_processing(..return_value = T),list(
    io_filter, io_filter, join_source
  ))

  expect_equal(sms$transform(..return_value = T), list(
    input_config=input_config,
    output_config=output_config,
    resource_config=resource_config,
    job_name=JOB_NAME,
    model_name=MODEL_NAME,
    strategy=strategy,
    max_concurrent_transforms=max_concurrent_transforms,
    max_payload=max_payload,
    env=env,
    experiment_config=list("ExperimentName"="exp"),
    model_client_config=model_client_config,
    tags=tags,
    data_processing = "dummy"
  ))
})

test_that("test_load_config", {
  expected_config = list(
    "input_config"=list(
      "DataSource"=list("S3DataSource"=list("S3DataType"=S3_DATA_TYPE, "S3Uri"=DATA))
    ),
    "output_config"=list("S3OutputPath"=OUTPUT_PATH),
    "resource_config"=list(
      "InstanceCount"=INSTANCE_COUNT,
      "InstanceType"=INSTANCE_TYPE,
      "VolumeKmsKeyId"=KMS_KEY_ID
    )
  )

  sms = sagemaker_session()
  transformer = tf(sms)
  actual_config = transformer$.__enclos_env__$private$.load_config(
    DATA, S3_DATA_TYPE, NULL, NULL, NULL
  )
  expect_equal(actual_config, expected_config)
})

test_that("test_format_inputs_to_input_config", {
  expected_config = list("DataSource"=list("S3DataSource"=list("S3DataType"=S3_DATA_TYPE, "S3Uri"=DATA)))
  sms = sagemaker_session()
  transformer = tf(sms)
  actual_config = transformer$.__enclos_env__$private$.format_inputs_to_input_config(
    DATA, S3_DATA_TYPE, NULL, NULL, NULL
  )
  expect_equal(actual_config, expected_config)
})

test_that("test_format_inputs_to_input_config_with_optional_params", {
  compression = "Gzip"
  content_type = "text/csv"
  split = "Line"

  expected_config = list(
    "DataSource"=list("S3DataSource"=list("S3DataType"=S3_DATA_TYPE, "S3Uri"=DATA)),
    "ContentType"=content_type,
    "CompressionType"=compression,
    "SplitType"=split
  )

  sms = sagemaker_session()
  transformer = tf(sms)
  actual_config = transformer$.__enclos_env__$private$.format_inputs_to_input_config(
    DATA, S3_DATA_TYPE, content_type, compression, split
  )
  expect_equal(actual_config, expected_config)
})

test_that("test_prepare_output_config", {
  sms = sagemaker_session()
  transformer = tf(sms)
  config = transformer$.__enclos_env__$private$.prepare_output_config(
    OUTPUT_PATH, NULL, NULL, NULL
  )
  expect_equal(config, list("S3OutputPath"=OUTPUT_PATH))
})

test_that("test_prepare_output_config_with_optional_params", {
  kms_key = "key"
  assemble_with = "Line"
  accept = "text/csv"

  expected_config = list(
    "S3OutputPath"=OUTPUT_PATH,
    "KmsKeyId"=kms_key,
    "AssembleWith"=assemble_with,
    "Accept"=accept
  )

  sms = sagemaker_session()
  transformer = tf(sms)
  actual_config = transformer$.__enclos_env__$private$.prepare_output_config(
    OUTPUT_PATH, kms_key, assemble_with, accept
  )
  expect_equal(actual_config, expected_config)
})

test_that("test_prepare_resource_config", {
  sms = sagemaker_session()
  transformer = tf(sms)
  config = transformer$.__enclos_env__$private$.prepare_resource_config(
    INSTANCE_COUNT, INSTANCE_TYPE, KMS_KEY_ID
  )
  expect_equal(config, list(
    "InstanceCount"=INSTANCE_COUNT,
    "InstanceType"=INSTANCE_TYPE,
    "VolumeKmsKeyId"=KMS_KEY_ID
  ))
})

test_that("test_data_processing_config", {
  sms = sagemaker_session()
  transformer = tf(sms)

  actual_config = transformer$.__enclos_env__$private$.prepare_data_processing("$", NULL, NULL)
  expect_equal(actual_config, list("InputFilter"="$"))

  actual_config = transformer$.__enclos_env__$private$.prepare_data_processing(NULL, "$", NULL)
  expect_equal(actual_config, list("OutputFilter"="$"))

  actual_config = transformer$.__enclos_env__$private$.prepare_data_processing(NULL, NULL, "Input")
  expect_equal(actual_config, list("JoinSource"="Input"))

  actual_config = transformer$.__enclos_env__$private$.prepare_data_processing("$[0]", "$[1]", "Input")
  expect_equal(actual_config, list("InputFilter"="$[0]", "OutputFilter"="$[1]", "JoinSource"="Input"))

  actual_config = transformer$.__enclos_env__$private$.prepare_data_processing(NULL, NULL, NULL)
  expect_null(actual_config)
})

test_that("test_transform_job_wait", {
  sms = sagemaker_session()
  transformer = tf(sms)
  transformer$latest_transform_job = JOB_NAME
  transformer$wait()

  expect_equal(sms$logs_for_transform_job(..count = T), 1)
})

test_that("test_restart_output_path", {
  sms = sagemaker_session()
  sms$.call_args("default_bucket", S3_BUCKET)
  transformer = tf(sms)
  transformer$output_path = NULL

  mock_start_new = mock_fun("dummy")
  mock_r6_private(transformer, ".start_new", mock_start_new)
  transformer$transform(DATA, job_name="job-1")
  expect_equal(transformer$output_path, sprintf("s3://%s/%s",S3_BUCKET, "job-1"))

  transformer$transform(DATA, job_name="job-2")
  expect_equal(transformer$output_path, sprintf("s3://%s/%s",S3_BUCKET, "job-2"))
})

test_that("test_stop_transform_job", {
  sms = sagemaker_session()
  sms$.call_args("stop_transform_job")
  transformer = tf(sms)
  transformer$latest_transform_job = JOB_NAME
  transformer$stop_transform_job()

  expect_equal(sms$stop_transform_job(..return_value = T), list(name = JOB_NAME))
})

test_that("test_stop_transform_job_no_transform_job", {
  sms = sagemaker_session()
  sms$.call_args("stop_transform_job")
  transformer = tf(sms)

  expect_error(
    transformer$stop_transform_job(),
    "No transform job available",
    class = "ValueError"
  )
})
