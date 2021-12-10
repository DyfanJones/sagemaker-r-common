# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/tests/unit/test_session.py

lg = lgr::get_logger("R6sagemaker")

MODEL_DATA = "s3://bucket/model.tar.gz"
MODEL_IMAGE = "mi"
ENTRY_POINT = "blah.py"

DATA_DIR = file.path(getwd(), "tests","testthat", "data")
DATA_DIR = file.path(getwd(), "data")
SCRIPT_NAME = "dummy_script.py"
SCRIPT_PATH = file.path(DATA_DIR, SCRIPT_NAME)
TIMESTAMP = "2017-11-06-14:14:15.671"
TIME = 1510006209.073025
BUCKET_NAME = "mybucket"
INSTANCE_COUNT = 1
INSTANCE_TYPE = "c4.4xlarge"
ACCELERATOR_TYPE = "ml.eia.medium"
ROLE = "DummyRole"
IMAGE_URI = "fakeimage"
REGION = "us-west-2"
JOB_NAME = sprintf("%s-%s", IMAGE_URI, TIMESTAMP)
TAGS = list(list("Name"="some-tag", "Value"="value-for-tag"))
OUTPUT_PATH = "s3://bucket/prefix"
GIT_REPO = "https://github.com/aws/sagemaker-python-sdk.git"
BRANCH = "test-branch-git-config"
COMMIT = "ae15c9d7d5b97ea95ea451e4662ee43da3401d73"
PRIVATE_GIT_REPO_SSH = "git@github.com:testAccount/private-repo.git"
PRIVATE_GIT_REPO = "https://github.com/testAccount/private-repo.git"
PRIVATE_BRANCH = "test-branch"
PRIVATE_COMMIT = "329bfcf884482002c05ff7f44f62599ebc9f445a"
CODECOMMIT_REPO = "https://git-codecommit.us-west-2.amazonaws.com/v1/repos/test-repo/"
CODECOMMIT_REPO_SSH = "ssh://git-codecommit.us-west-2.amazonaws.com/v1/repos/test-repo/"
CODECOMMIT_BRANCH = "master"
REPO_DIR = "/tmp/repo_dir"
ENV_INPUT = list("env_key1"="env_val1", "env_key2"="env_val2", "env_key3"="env_val3")

DESCRIBE_TRAINING_JOB_RESULT = list("ModelArtifacts"=list("S3ModelArtifacts"=MODEL_DATA))

RETURNED_JOB_DESCRIPTION = list(
  "AlgorithmSpecification"=list(
    "TrainingInputMode"="File",
    "TrainingImage"="1.dkr.ecr.us-west-2.amazonaws.com/sagemaker-other:1.0.4"
  ),
  "HyperParameters"=list(
    "sagemaker_submit_directory"='s3://some/sourcedir.tar.gz',
    "checkpoint_path"='s3://other/1508872349',
    "sagemaker_program"='iris-dnn-classifier.py',
    "sagemaker_container_log_level"='INFO',
    "sagemaker_job_name"='"neo"',
    "training_steps"="100"
  ),
  "RoleArn"="arn:aws:iam::366:role/SageMakerRole",
  "ResourceConfig"=list("VolumeSizeInGB"=30, "InstanceCount"=1, "InstanceType"="ml.c4.xlarge"),
  "EnableNetworkIsolation"=FALSE,
  "StoppingCondition"=list("MaxRuntimeInSeconds"=24 * 60 * 60),
  "TrainingJobName"="neo",
  "TrainingJobStatus"="Completed",
  "TrainingJobArn"="arn:aws:sagemaker:us-west-2:336:training-job/neo",
  "OutputDataConfig"=list("KmsKeyId"="", "S3OutputPath"="s3://place/output/neo"),
  "TrainingJobOutput"=list("S3TrainingJobOutput"="s3://here/output.tar.gz"),
  "EnableInterContainerTrafficEncryption"=FALSE
)

MODEL_CONTAINER_DEF = list(
  "Environment"=list(
    "SAGEMAKER_PROGRAM"=ENTRY_POINT,
    "SAGEMAKER_SUBMIT_DIRECTORY"="s3://mybucket/mi-2017-10-10-14-14-15/sourcedir.tar.gz",
    "SAGEMAKER_CONTAINER_LOG_LEVEL"="20",
    "SAGEMAKER_REGION"=REGION
  ),
  "Image"=MODEL_IMAGE,
  "ModelDataUrl"=MODEL_DATA
)

ENDPOINT_DESC = list("EndpointConfigName"="test-endpoint")

ENDPOINT_CONFIG_DESC = list("ProductionVariants"=list(list("ModelName"="model-1"), list("ModelName"="model-2")))

LIST_TAGS_RESULT = list("Tags"=list(list("Key"="TagtestKey", "Value"="TagtestValue")))

DISTRIBUTION_PS_ENABLED = list("parameter_server"=list("enabled"=TRUE))
DISTRIBUTION_MPI_ENABLED = list(
  "mpi"=list("enabled"=TRUE, "custom_mpi_options"="options", "processes_per_host"=2)
)
DISTRIBUTION_SM_DDP_ENABLED = list(
  "smdistributed"=list("dataparallel"=list("enabled"=TRUE, "custom_mpi_options"="options"))
)


DummyFramework = R6::R6Class("DummyFramework",
  inherit = Framework,
  public = list(
    initialize = function(...){
      super$initialize(...)
      attr(self, "_framework_name") = "dummy"
    },
    training_image_uri = function(){
      return(IMAGE_URI)
    },
    create_model = function(role=NULL,
                            model_server_workers=NULL,
                            entry_point=NULL,
                            vpc_config_override="VPC_CONFIG_DEFAULT",
                            enable_network_isolation=NULL,
                            model_dir=NULL,
                            ...){
      if (is.null(enable_network_isolation))
        enable_network_isolation = self$enable_network_isolation()
      return(DummyFrameworkModel$new(
        self.sagemaker_session,
        vpc_config=self$get_vpc_config(vpc_config_override),
        entry_point=entry_point,
        enable_network_isolation=enable_network_isolation,
        role=role,
        ...)
      )
    }
  ),
  private = list(
    .prepare_init_params_from_job_description = function(job_details,
                                                         model_channel_name=NULL){
      init_params = super$.prepare_init_params_from_job_description(
        job_details, model_channel_name
      )
      init_params[["image_uri"]] = NULL
      return(init_params)
    }
  ),
  lock_objects = F
)

DummyFrameworkModel = R6::R6Class("DummyFrameworkModel",
  inherit = FrameworkModel,
  public = list(
    initialize = function(sagemaker_session,
                          entry_point=NULL,
                          role=ROLE,
                          ...){
      super$initialize(
        MODEL_DATA,
        MODEL_IMAGE,
        role,
        entry_point %||% ENTRY_POINT,
        sagemaker_session=sagemaker_session,
        ...
      )
    },
    create_predictor = function(endpoint_name){
      return(NULL)
    },
    prepare_container_def = function(instance_type, accelerator_type=NULL){
      return(MODEL_CONTAINER_DEF)
    }
  ),
  lock_objects = F
)


sagemaker_session = function(){
  paws_mock = Mock$new(
    name = "PawsSession",
    region_name = REGION
  )

  sms = Mock$new(
    name="sagemaker_session",
    paws_session=paws_mock,
    paws_region_name=REGION,
    config=NULL,
    local_mode=FALSE,
    s3=NULL,
    s3_resource=NULL
  )

  sagemaker = Mock$new()
  sagemaker$.call_args("describe_training_job", return_value=DESCRIBE_TRAINING_JOB_RESULT)
  sagemaker$.call_args("describe_endpoint", return_value=ENDPOINT_DESC)
  sagemaker$.call_args("describe_endpoint_config", return_value=ENDPOINT_CONFIG_DESC)
  sagemaker$.call_args("list_tags", return_value=LIST_TAGS_RESULT)
  sagemaker$.call_args("train")

  sms$.call_args("default_bucket", return_value=BUCKET_NAME)
  sms$.call_args("upload_data", return_value=OUTPUT_PATH)
  sms$.call_args("expand_role")
  sms$.call_args("train")
  sms$.call_args("logs_for_job")
  sms$.call_args("wait_for_job")
  sms$sagemaker = sagemaker
  return(sms)
}

training_job_description = function(sms){
  sagemaker_session = sms$clone()
  returned_job_description = RETURNED_JOB_DESCRIPTION
  sagemaker_session$sagemaker$.call_args("describe_training_job", return_value=returned_job_description)
  sagemaker_session$.call_args("describe_training_job", return_value=returned_job_description)
  return(sagemaker_session)
}

test_that("test_framework_all_init_args", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    "my_script.py",
    role="DummyRole",
    instance_count=3,
    instance_type="ml.m4.xlarge",
    sagemaker_session=sms,
    volume_size=123,
    volume_kms_key="volumekms",
    max_run=456,
    input_mode="inputmode",
    output_path="outputpath",
    output_kms_key="outputkms",
    base_job_name="basejobname",
    tags=list(list("foo"="bar")),
    subnets=c("123", "456"),
    security_group_ids=c("789", "012"),
    metric_definitions=list(list("Name"="validation-rmse", "Regex"="validation-rmse=(\\d+)")),
    encrypt_inter_container_traffic=TRUE,
    checkpoint_s3_uri="s3://bucket/checkpoint",
    checkpoint_local_path="file://local/checkpoint",
    enable_sagemaker_metrics=TRUE,
    enable_network_isolation=TRUE,
    environment=ENV_INPUT,
    max_retry_attempts=2
  )

  f$.__enclos_env__$private$.start_new("s3://mydata", NULL)


  expect_equal(sms$train(..return_value = T), list(
      "input_config"=list(
        list(
          "DataSource"=list(
            "S3DataSource"=list(
              "S3DataType"="S3Prefix",
              "S3Uri"="s3://mydata",
              "S3DataDistributionType"="FullyReplicated"
            )
          ),
          "ChannelName"="training"
        )
      ),
      "role"=sms$expand_role(),
      "output_config"=list("S3OutputPath"="outputpath", "KmsKeyId"="outputkms"),
      "resource_config"=list(
        "InstanceCount"=3,
        "InstanceType"="ml.m4.xlarge",
        "VolumeSizeInGB"=123,
        "VolumeKmsKeyId"="volumekms"
      ),
      "stop_condition"=list("MaxRuntimeInSeconds"=456),
      "vpc_config"=list("Subnets"=c("123", "456"), "SecurityGroupIds"=c("789", "012")),
      "input_mode"="inputmode",
      "hyperparameters"=list(),
      "tags"=list(list("foo"="bar")),
      "metric_definitions"=list(list("Name"="validation-rmse", "Regex"="validation-rmse=(\\d+)")),
      "environment"=list("env_key1"="env_val1", "env_key2"="env_val2", "env_key3"="env_val3"),
      "enable_network_isolation"=TRUE,
      "retry_strategy"=list("MaximumRetryAttempts"=2),
      "encrypt_inter_container_traffic"=TRUE,
      "image_uri"="fakeimage",
      "checkpoint_s3_uri"="s3://bucket/checkpoint",
      "checkpoint_local_path"="file://local/checkpoint",
      "enable_sagemaker_metrics"=TRUE
    )
  )
})

test_that("test_framework_with_debugger_and_built_in_rule", {
  debugger_built_in_rule_with_custom_args = Rule$new()$sagemaker(
    base_config=R6sagemaker.debugger:::stalled_training_rule(),
    rule_parameters=list("threshold"="120", "stop_training_on_fire"="True"),
    collections_to_save=list(
      CollectionConfig$new(
        name="losses", parameters=list("train.save_interval"="50", "eval.save_interval"="10")
      )
    )
  )
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    rules=list(debugger_built_in_rule_with_custom_args),
    debugger_hook_config=DebuggerHookConfig$new(s3_output_path="s3://output"),
  )
  f$fit("s3://mydata")
  args = sms$train(..return_value = T)
  ## fix this
  expect_equal(args[["debugger_rule_configs"]][[1]][["RuleParameters"]], list(
    "rule_to_invoke"="StalledTrainingRule",
    "threshold"="120",
    "stop_training_on_fire"="True"
    )
  )
  expect_equal(args[["debugger_hook_config"]], list(
    "S3OutputPath"="s3://output",
    "CollectionConfigurations"=list(
      list(
        "CollectionName"="losses",
        "CollectionParameters"=list("train.save_interval"="50", "eval.save_interval"="10")
        )
      )
    )
  )
  expect_equal(args[["profiler_config"]], list(
    "S3OutputPath"=sprintf("s3://%s/", BUCKET_NAME)
    )
  )
})

