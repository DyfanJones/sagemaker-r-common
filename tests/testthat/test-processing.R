# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/tests/unit/test_processing.py

BUCKET_NAME = "mybucket"
REGION = "us-west-2"
ROLE = "arn:aws:iam::012345678901:role/SageMakerRole"
ECR_HOSTNAME = "ecr.us-west-2.amazonaws.com"
CUSTOM_IMAGE_URI = "012345678901.dkr.ecr.us-west-2.amazonaws.com/my-custom-image-uri"
MOCKED_S3_URI = "s3://mocked_s3_uri_from_upload_data"
DEFAULT_REGION = "us-west-2"
DEFAULT_CONFIG = list("local"=list("local_code"=TRUE, "region_name"=DEFAULT_REGION))

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

  s3_client = Mock$new()

  sms$sagemaker = sagemaker
  sms$s3 = s3_client

  sms$.call_args("default_bucket", BUCKET_NAME)
  sms$.call_args("upload_data", MOCKED_S3_URI)
  sms$.call_args("download_data")
  sms$.call_args("expand_role", ROLE)
  sms$.call_args("process")
  sms$.call_args("logs_for_processing_job")
  sms$.call_args("describe_processing_job", .get_describe_response_inputs_and_ouputs())
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

.get_script_processor = function(sagemaker_session){
  return(ScriptProcessor$new(
    role=ROLE,
    image_uri=CUSTOM_IMAGE_URI,
    command="python3",
    instance_type="ml.m4.xlarge",
    instance_count=1,
    sagemaker_session=sagemaker_session)
  )
}

.get_expected_args = function(job_name, code_s3_uri="s3://mocked_s3_uri_from_upload_data"){
  return(list(
    "inputs"=list(
      list(
        "InputName"="code",
        "AppManaged"=FALSE,
        "S3Input"=list(
          "S3Uri"=code_s3_uri,
          "LocalPath"="/opt/ml/processing/input/code",
          "S3DataType"="S3Prefix",
          "S3InputMode"="File",
          "S3DataDistributionType"="FullyReplicated",
          "S3CompressionType"="None"
        )
      )
    ),
    "output_config"=list("Outputs"=list()),
    "experiment_config"=NULL,
    "job_name"=job_name,
    "resources"=list(
      "ClusterConfig"=list(
        "InstanceType"="ml.m4.xlarge",
        "InstanceCount"=1,
        "VolumeSizeInGB"=30
      )
    ),
    "stopping_condition"=NULL,
    "app_specification"=list(
      "ImageUri"=CUSTOM_IMAGE_URI,
      "ContainerEntrypoint"=list("python3", "/opt/ml/processing/input/code/processing_code.py")
    ),
    "environment"=NULL,
    "network_config"=NULL,
    "role_arn"=ROLE,
    "tags"=NULL
    )
  )
}

.get_expected_args_modular_code=function(job_name, code_s3_uri=sprintf("s3://%s",BUCKET_NAME)){
  return(list(
    "inputs"=list(
      list(
        "InputName"="code",
        "AppManaged"=FALSE,
        "S3Input"=list(
          "S3Uri"=sprintf("%s/%s/source/sourcedir.tar.gz", code_s3_uri, job_name),
          "LocalPath"="/opt/ml/processing/input/code/",
          "S3DataType"="S3Prefix",
          "S3InputMode"="File",
          "S3DataDistributionType"="FullyReplicated",
          "S3CompressionType"="None"
        )
      ),
      list(
        "InputName"="entrypoint",
        "AppManaged"=FALSE,
        "S3Input"=list(
          "S3Uri"=sprintf("%s/%s/source/runproc.sh",code_s3_uri, job_name),
          "LocalPath"="/opt/ml/processing/input/entrypoint",
          "S3DataType"="S3Prefix",
          "S3InputMode"="File",
          "S3DataDistributionType"="FullyReplicated",
          "S3CompressionType"="None"
        )
      )
    ),
    "output_config"=list("Outputs"=list()),
    "experiment_config"=NULL,
    "job_name"=job_name,
    "resources"=list(
      "ClusterConfig"=list(
        "InstanceType"="ml.m4.xlarge",
        "InstanceCount"=1,
        "VolumeSizeInGB"=30
      )
    ),
    "stopping_condition"=NULL,
    "app_specification"=list(
      "ImageUri"=CUSTOM_IMAGE_URI,
      "ContainerEntrypoint"=list(
        "/bin/bash",
        "/opt/ml/processing/input/entrypoint/runproc.sh"
      )
    ),
    "environment"=NULL,
    "network_config"=NULL,
    "role_arn"=ROLE,
    "tags"=NULL,
    "experiment_config"=NULL
    )
  )
}

.get_data_input = function(){
  data_input = list(
    "InputName"="input-1",
    "AppManaged"=FALSE,
    "S3Input"=list(
      "S3Uri"=MOCKED_S3_URI,
      "LocalPath"="/data/",
      "S3DataType"="S3Prefix",
      "S3InputMode"="File",
      "S3DataDistributionType"="FullyReplicated",
      "S3CompressionType"="None"
    )
  )
  return(data_input)
}

.get_expected_args_all_parameters = function(job_name){
  return(list(
    "inputs"=list(
      list(
        "InputName"="my_dataset",
        "AppManaged"=FALSE,
        "S3Input"=list(
          "S3Uri"="s3://path/to/my/dataset/census.csv",
          "LocalPath"="/container/path/",
          "S3DataType"="S3Prefix",
          "S3InputMode"="File",
          "S3DataDistributionType"="FullyReplicated",
          "S3CompressionType"="None"
        )
      ),
      list(
        "InputName"="s3_input",
        "AppManaged"=FALSE,
        "S3Input"=list(
          "S3Uri"="s3://path/to/my/dataset/census.csv",
          "LocalPath"="/container/path/",
          "S3DataType"="S3Prefix",
          "S3InputMode"="File",
          "S3DataDistributionType"="FullyReplicated",
          "S3CompressionType"="None"
        )
      ),
      list(
        "InputName"="redshift_dataset_definition",
        "AppManaged"=TRUE,
        "DatasetDefinition"=list(
          "DataDistributionType"="FullyReplicated",
          "InputMode"="File",
          "LocalPath"="/opt/ml/processing/input/dd",
          "RedshiftDatasetDefinition"=list(
            "ClusterId"="cluster_id",
            "Database"="database",
            "DbUser"="db_user",
            "QueryString"="query_string",
            "ClusterRoleArn"="cluster_role_arn",
            "OutputS3Uri"="output_s3_uri",
            "KmsKeyId"="kms_key_id",
            "OutputFormat"="CSV",
            "OutputCompression"="SNAPPY"
          )
        )
      ),
      list(
        "InputName"="athena_dataset_definition",
        "AppManaged"=TRUE,
        "DatasetDefinition"=list(
          "DataDistributionType"="FullyReplicated",
          "InputMode"="File",
          "LocalPath"="/opt/ml/processing/input/dd",
          "AthenaDatasetDefinition"=list(
            "Catalog"="catalog",
            "Database"="database",
            "QueryString"="query_string",
            "OutputS3Uri"="output_s3_uri",
            "WorkGroup"="workgroup",
            "KmsKeyId"="kms_key_id",
            "OutputFormat"="AVRO",
            "OutputCompression"="ZLIB"
          )
        )
      ),
      list(
        "InputName"="code",
        "AppManaged"=FALSE,
        "S3Input"=list(
          "S3Uri"=MOCKED_S3_URI,
          "LocalPath"="/opt/ml/processing/input/code",
          "S3DataType"="S3Prefix",
          "S3InputMode"="File",
          "S3DataDistributionType"="FullyReplicated",
          "S3CompressionType"="None"
        )
      )
    ),
    "output_config"=list(
      "Outputs"=list(
        list(
          "OutputName"="my_output",
          "AppManaged"=FALSE,
          "S3Output"=list(
            "S3Uri"="s3://uri/",
            "LocalPath"="/container/path/",
            "S3UploadMode"="EndOfJob"
          )
        ),
        list(
          "OutputName"="feature_store_output",
          "AppManaged"=TRUE,
          "FeatureStoreOutput"=list("FeatureGroupName"="FeatureGroupName")
        )
      ),
      "KmsKeyId"="arn:aws:kms:us-west-2:012345678901:key/output-kms-key"
    ),
    "job_name"=job_name,
    "resources"=list(
      "ClusterConfig"=list(
        "InstanceType"="ml.m4.xlarge",
        "InstanceCount"=1,
        "VolumeSizeInGB"=100,
        "VolumeKmsKeyId"="arn:aws:kms:us-west-2:012345678901:key/volume-kms-key"
      )
    ),
    "stopping_condition"=list("MaxRuntimeInSeconds"=3600),
    "app_specification"=list(
      "ImageUri"="012345678901.dkr.ecr.us-west-2.amazonaws.com/my-custom-image-uri",
      "ContainerArguments"=list("--drop-columns", "'SelfEmployed'"),
      "ContainerEntrypoint"=list("python3", "/opt/ml/processing/input/code/processing_code.py")
    ),
    "environment"=list("my_env_variable"="my_env_variable_value"),
    "network_config"=list(
      "EnableNetworkIsolation"=TRUE,
      "EnableInterContainerTrafficEncryption"=TRUE,
      "VpcConfig"=list(
        "SecurityGroupIds"=list("my_security_group_id"),
        "Subnets"=list("my_subnet_id")
      )
    ),
    "role_arn"=ROLE,
    "tags"=list(list("Key"="my-tag", "Value"="my-tag-value")),
    "experiment_config"=list("ExperimentName"="AnExperiment")
  ))
}

.get_describe_response_inputs_and_ouputs = function(){
  return(list(
    "ProcessingInputs"=.get_expected_args_all_parameters(NULL)[["inputs"]],
    "ProcessingOutputConfig"=.get_expected_args_all_parameters(NULL)[["output_config"]]
  ))
}

test_that("test_script_processor_errors_with_nonexistent_local_code", {
  sms = sagemaker_session()
  processor = .get_script_processor(sms)
  with_mock(
    `fs::file_exists` = mock_fun(FALSE),
    {
      expect_error(processor$run(code="/local/path/to/processing_code.py"))
    }
  )
})

test_that("test_script_processor_errors_with_code_directory", {
  sms = sagemaker_session()
  processor = .get_script_processor(sms)
  with_mock(
    `fs::file_exists` = mock_fun(TRUE),
    `fs::is_file` = mock_fun(FALSE),
    {
      expect_error(processor$run(code="/local/path/to/code"))
    }
  )
})

test_that("test_script_processor_errors_with_invalid_code_url_scheme", {
  sms = sagemaker_session()
  processor = .get_script_processor(sms)
  with_mock(
    `fs::file_exists` = mock_fun(TRUE),
    `fs::is_file` = mock_fun(TRUE),
    {
      expect_error(processor$run(code="hdfs:///path/to/processing_code.py"))
    }
  )
})

test_that("test_script_processor_works_with_absolute_local_path", {
  sms = sagemaker_session()
  processor = .get_script_processor(sms)
  with_mock(
    `fs::file_exists` = mock_fun(TRUE),
    `fs::is_file` = mock_fun(TRUE),
    {
      processor$run(code="/local/path/to/processing_code.py")
      expected_args = .get_expected_args(processor$.current_job_name, code_s3_uri=MOCKED_S3_URI)
      expect_equal(sms$process(..return_value = T), expected_args)
    }
  )
})

test_that("test_script_processor_works_with_relative_local_path", {
  sms = sagemaker_session()
  processor = .get_script_processor(sms)
  with_mock(
    `fs::file_exists` = mock_fun(TRUE),
    `fs::is_file` = mock_fun(TRUE),
    {
      processor$run(code="processing_code.py")
      expected_args = .get_expected_args(processor$.current_job_name, code_s3_uri=MOCKED_S3_URI)
      expect_equal(sms$process(..return_value = T), expected_args)
    }
  )
})

test_that("test_script_processor_works_with_relative_local_path_with_directories", {
  sms = sagemaker_session()
  processor = .get_script_processor(sms)
  with_mock(
    `fs::file_exists` = mock_fun(TRUE),
    `fs::is_file` = mock_fun(TRUE),
    {
      processor$run(code="path/to/processing_code.py")
      expected_args = .get_expected_args(processor$.current_job_name, code_s3_uri=MOCKED_S3_URI)
      expect_equal(sms$process(..return_value = T), expected_args)
    }
  )
})

test_that("test_script_processor_works_with_file_code_url_scheme", {
  sms = sagemaker_session()
  processor = .get_script_processor(sms)
  with_mock(
    `fs::file_exists` = mock_fun(TRUE),
    `fs::is_file` = mock_fun(TRUE),
    {
      processor$run(code="file:///path/to/processing_code.py")
      expected_args = .get_expected_args(processor$.current_job_name, code_s3_uri=MOCKED_S3_URI)
      expect_equal(sms$process(..return_value = T), expected_args)
    }
  )
})

test_that("test_script_processor_works_with_s3_code_url", {
  sms = sagemaker_session()
  processor = .get_script_processor(sms)
  with_mock(
    `fs::file_exists` = mock_fun(TRUE),
    `fs::is_file` = mock_fun(TRUE),
    {
      processor$run(code="s3://bucket/path/to/processing_code.py")
      expected_args = .get_expected_args(
        processor$.current_job_name,"s3://bucket/path/to/processing_code.py"
      )
      expect_equal(sms$process(..return_value = T), expected_args)
    }
  )
})

test_that("test_script_processor_with_one_input", {
  sms = sagemaker_session()
  processor = .get_script_processor(sms)
  with_mock(
    `fs::file_exists` = mock_fun(TRUE),
    `fs::is_file` = mock_fun(TRUE),
    {
      processor$run(
        code="/local/path/to/processing_code.py",
        inputs=ProcessingInput$new(source="/local/path/to/my/dataset/census.csv", destination="/data/")
      )
      expected_args = .get_expected_args(processor$.current_job_name, code_s3_uri=MOCKED_S3_URI)
      expected_args[["inputs"]] = append(expected_args[["inputs"]], list(.get_data_input()), 0)
      expect_equal(sms$process(..return_value = T), expected_args)
    }
  )
})




