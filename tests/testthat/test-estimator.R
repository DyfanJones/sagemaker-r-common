# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/tests/unit/test_session.py

lg = lgr::get_logger("R6sagemaker")

MODEL_DATA = "s3://bucket/model.tar.gz"
MODEL_IMAGE = "mi"
ENTRY_POINT = "blah.py"

DATA_DIR = file.path(getwd(), "tests","testthat", "data")
# DATA_DIR = file.path(getwd(), "data")
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

sagemaker_session = function(region=REGION){
  paws_mock = Mock$new(
    name = "PawsSession",
    region_name = region
  )

  sms = Mock$new(
    name="sagemaker_session",
    paws_session=paws_mock,
    paws_region_name=region,
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
  sms$.call_args("describe_training_job", return_value=DESCRIBE_TRAINING_JOB_RESULT)
  sms$.call_args("update_training_job")
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
    base_config=R6sagemaker.debugger::stalled_training_rule(),
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


test_that("test_framework_with_debugger_and_custom_rule", {
  hook_config = DebuggerHookConfig$new(
    s3_output_path="s3://output", collection_configs=list(CollectionConfig$new(name="weights"))
  )
  debugger_custom_rule = Rule$new()$custom(
    name="CustomRule",
    image_uri="RuleImageUri",
    instance_type=INSTANCE_TYPE,
    volume_size_in_gb=5,
    source="path/to/my_custom_rule.py",
    rule_to_invoke="CustomRule",
    other_trials_s3_input_paths=c("s3://path/trial1", "s3://path/trial2"),
    rule_parameters=list("threshold"="120")
  )

  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    rules=list(debugger_custom_rule),
    debugger_hook_config=hook_config
  )
  f$fit("s3://mydata")

  args = sms$train(..return_value = T)

  expect_equal(args[["debugger_rule_configs"]], list(
    list(
      "RuleConfigurationName"="CustomRule",
      "RuleEvaluatorImage"="RuleImageUri",
      "InstanceType"=INSTANCE_TYPE,
      "VolumeSizeInGB"=5,
      "RuleParameters"=list(
        "other_trial_0"="s3://path/trial1",
        "other_trial_1"="s3://path/trial2",
        "source_s3_uri"=sms$upload_data(),
        "rule_to_invoke"="CustomRule",
        "threshold"="120"
        )
      )
    )
  )
  expect_equal(args[["debugger_hook_config"]], list(
    "S3OutputPath"="s3://output",
    "CollectionConfigurations"=list(list("CollectionName"="weights"))
  ))
})

test_that("test_framework_with_only_debugger_rule", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    rules=list(Rule$new()$sagemaker(R6sagemaker.debugger::stalled_training_rule()))
  )
  f$fit("s3://mydata")
  args = sms$train(..return_value = T)
  expect_equal(args[["debugger_rule_configs"]][[1]][["RuleParameters"]], list(
    "rule_to_invoke"="StalledTrainingRule"
  ))
  expect_equal(args[["debugger_hook_config"]], list(
    "S3OutputPath"=sprintf("s3://%s/",BUCKET_NAME),
    "CollectionConfigurations"=list()
  ))
})

test_that("test_framework_with_debugger_rule_and_single_action", {
  stop_training_action = R6sagemaker.debugger::StopTraining$new()
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    rules=list(Rule$new()$sagemaker(R6sagemaker.debugger::stalled_training_rule(), actions=stop_training_action))
  )
  f$fit("s3://mydata")
  args = sms$train(..return_value = T)
  expect_equal(args[["debugger_rule_configs"]][[1]][["RuleParameters"]], list(
    "rule_to_invoke"="StalledTrainingRule",
    "action_json"=stop_training_action$serialize()
  ))
  expect_equal(stop_training_action$action_parameters[["training_job_prefix"]], f$.current_job_name)
  expect_equal(args[["debugger_hook_config"]], list(
    "S3OutputPath"=sprintf("s3://%s/",BUCKET_NAME),
    "CollectionConfigurations"=list()
  ))
})

test_that("test_framework_with_debugger_rule_and_multiple_actions", {
  action_list = R6sagemaker.debugger::ActionList$new(
    R6sagemaker.debugger::StopTraining$new(),
    R6sagemaker.debugger::Email$new("abc@abc.com"),
    R6sagemaker.debugger::SMS$new("+1234567890")
  )
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    rules=list(Rule$new()$sagemaker(R6sagemaker.debugger::stalled_training_rule(), actions=action_list))
  )
  f$fit("s3://mydata")
  args = sms$train(..return_value = T)
  expect_equal(args[["debugger_rule_configs"]][[1]][["RuleParameters"]], list(
    "rule_to_invoke"="StalledTrainingRule",
    "action_json"=action_list$serialize()
  ))
  expect_equal(args[["debugger_hook_config"]], list(
    "S3OutputPath"=sprintf("s3://%s/",BUCKET_NAME),
    "CollectionConfigurations"=list()
  ))
})

test_that("test_framework_with_only_debugger_hook_config", {
  hook_config = DebuggerHookConfig$new(
    s3_output_path="s3://output", collection_configs=list(CollectionConfig$new(name="weights"))
  )
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    debugger_hook_config=hook_config
  )
  f$fit("s3://mydata")
  args = sms$train(..return_value = T)
  expect_equal(args[["debugger_hook_config"]], list(
    "S3OutputPath"="s3://output",
    "CollectionConfigurations"=list(list("CollectionName"="weights"))
  ))
  expect_false("debugger_rule_configs" %in% names(args))
})

test_that("test_framework_without_debugger_and_profiler", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  f$fit("s3://mydata")
  args = sms$train(..return_value = T)
  expect_equal(args[["debugger_hook_config"]], list(
    "S3OutputPath"=sprintf("s3://%s/", BUCKET_NAME),
    "CollectionConfigurations"=list()
  ))
  expect_false("debugger_rule_configs" %in% names(args))
  expect_equal(args[["profiler_config"]], list(
    "S3OutputPath"=sprintf("s3://%s/", BUCKET_NAME)
  ))
  expect_true(grepl("ProfilerReport-[0-9]+", args[["profiler_rule_configs"]][[1]][["RuleConfigurationName"]]))
  expect_equal(
    args[["profiler_rule_configs"]][[1]][["RuleEvaluatorImage"]],
    "895741380848.dkr.ecr.us-west-2.amazonaws.com/sagemaker-debugger-rules:latest"
  )
  expect_equal(
    args[["profiler_rule_configs"]][[1]][["RuleParameters"]],
    list("rule_to_invoke"="ProfilerReport")
  )
})

test_that("test_framework_with_debugger_and_profiler_rules", {
  debugger_built_in_rule_with_custom_args = Rule$new()$sagemaker(
    base_config=R6sagemaker.debugger::stalled_training_rule(),
    rule_parameters=list("threshold"="120", "stop_training_on_fire"="True"),
    collections_to_save=list(
      CollectionConfig$new(
        name="losses", parameters=list("train.save_interval"="50", "eval.save_interval"="10")
      )
    )
  )
  profiler_built_in_rule_with_custom_args = ProfilerRule$new()$sagemaker(
    base_config=R6sagemaker.debugger::ProfilerReport$new(CPUBottleneck_threshold=90),
    name="CustomProfilerReportRule"
  )
  profiler_custom_rule = ProfilerRule$new()$custom(
    name="CustomProfilerRule",
    image_uri="RuleImageUri",
    instance_type=INSTANCE_TYPE,
    volume_size_in_gb=5,
    source="path/to/my_custom_rule.py",
    rule_to_invoke="CustomProfilerRule",
    rule_parameters=list("threshold"="10")
  )
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    rules=list(
      debugger_built_in_rule_with_custom_args,
      profiler_built_in_rule_with_custom_args,
      profiler_custom_rule
    )
  )
  f$fit("s3://mydata")
  args = sms$train(..return_value = T)
  expect_equal(args[["debugger_rule_configs"]],list(
   list(
     "RuleConfigurationName"="StalledTrainingRule",
     "RuleEvaluatorImage"="895741380848.dkr.ecr.us-west-2.amazonaws.com/sagemaker-debugger-rules:latest",
     "RuleParameters"=list(
       "rule_to_invoke"="StalledTrainingRule",
       "threshold"="120",
       "stop_training_on_fire"="True"
       )
     )
  ))
  expect_equal(args[["debugger_hook_config"]],list(
    "S3OutputPath"="s3://mybucket/",
    "CollectionConfigurations"=list(
      list(
        "CollectionName"="losses",
        "CollectionParameters"=list("train.save_interval"="50", "eval.save_interval"="10")
      )
    )
  ))
  expect_equal(args[["profiler_config"]],list(
    "S3OutputPath"=sprintf("s3://%s/", BUCKET_NAME)
  ))
  expect_equal(args[["profiler_rule_configs"]],list(
    list(
      "RuleConfigurationName"="CustomProfilerReportRule",
      "RuleEvaluatorImage"="895741380848.dkr.ecr.us-west-2.amazonaws.com/sagemaker-debugger-rules:latest",
      "RuleParameters"=list("CPUBottleneck_threshold"="90", "rule_to_invoke"="ProfilerReport")
    ),
    list(
      "RuleConfigurationName"="CustomProfilerRule",
      "RuleEvaluatorImage"="RuleImageUri",
      "InstanceType"="c4.4xlarge",
      "VolumeSizeInGB"=5,
      "RuleParameters"=list(
        "source_s3_uri"=OUTPUT_PATH,
        "rule_to_invoke"="CustomProfilerRule",
        "threshold"="10"
      )
    )
  ))
})

test_that("test_framework_with_only_profiler_rule_specified", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    rules=list(ProfilerRule$new()$sagemaker(R6sagemaker.debugger::CPUBottleneck$new(gpu_threshold=60)))
  )
  f$fit("s3://mydata")
  args = sms$train(..return_value = T)
  expect_equal(args[["profiler_config"]], list(
    "S3OutputPath"=sprintf("s3://%s/", BUCKET_NAME)
  ))
  expect_equal(args[["profiler_rule_configs"]], list(
    list(
      "RuleConfigurationName"="CPUBottleneck",
      "RuleEvaluatorImage"="895741380848.dkr.ecr.us-west-2.amazonaws.com/sagemaker-debugger-rules:latest",
      "RuleParameters"=list(
        "threshold"="50",
        "gpu_threshold"="60",
        "cpu_threshold"="90",
        "patience"="1000",
        "scan_interval_us"="60000000",
        "rule_to_invoke"="CPUBottleneck"
      )
    )
  ))
})

test_that("test_framework_with_only_profiler_rule_specified", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    rules=list(ProfilerRule$new()$sagemaker(R6sagemaker.debugger::CPUBottleneck$new(gpu_threshold=60)))
  )
  f$fit("s3://mydata")
  args = sms$train(..return_value = T)
  expect_equal(args[["profiler_config"]], list(
    "S3OutputPath"=sprintf("s3://%s/", BUCKET_NAME)
  ))
  expect_equal(args[["profiler_rule_configs"]], list(
    list(
      "RuleConfigurationName"="CPUBottleneck",
      "RuleEvaluatorImage"="895741380848.dkr.ecr.us-west-2.amazonaws.com/sagemaker-debugger-rules:latest",
      "RuleParameters"=list(
        "threshold"="50",
        "gpu_threshold"="60",
        "cpu_threshold"="90",
        "patience"="1000",
        "scan_interval_us"="60000000",
        "rule_to_invoke"="CPUBottleneck"
      )
    )
  ))
})

test_that("test_framework_with_profiler_config_without_s3_output_path", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    profiler_config=ProfilerConfig$new(system_monitor_interval_millis=1000)
  )
  f$fit("s3://mydata")
  args = sms$train(..return_value = T)
  expect_equal(args[["profiler_config"]], list(
    "S3OutputPath"=sprintf("s3://%s/", BUCKET_NAME),
    "ProfilingIntervalInMilliseconds"= 1000
  ))
  expect_true(grepl("ProfilerReport-[0-9]+",args[["profiler_rule_configs"]][[1]][["RuleConfigurationName"]]))
  expect_equal(args[["profiler_rule_configs"]][[1]][["RuleEvaluatorImage"]], "895741380848.dkr.ecr.us-west-2.amazonaws.com/sagemaker-debugger-rules:latest")
  expect_equal(args[["profiler_rule_configs"]][[1]][["RuleParameters"]], list("rule_to_invoke"="ProfilerReport"))
})

test_that("test_framework_with_no_default_profiler_in_unsupported_region", {
  sms = sagemaker_session(R6sagemaker.common:::PROFILER_UNSUPPORTED_REGIONS)
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  f$fit("s3://mydata")
  args = sms$train(..return_value = T)
  expect_null(args[["profiler_config"]])
  expect_null(args[["profiler_rule_configs"]])
})

test_that("test_framework_with_profiler_config_and_profiler_disabled", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    profiler_config=ProfilerConfig$new(),
    disable_profiler=TRUE
  )
  expect_error(
    f$fit("s3://mydata"),
    "profiler_config cannot be set when disable_profiler is True.",
    class = "RuntimeError"
  )
})

test_that("test_framework_with_profiler_rule_and_profiler_disabled", {
  profiler_custom_rule = ProfilerRule$new()$custom(
    name="CustomProfilerRule",
    image_uri="RuleImageUri",
    instance_type=INSTANCE_TYPE,
    volume_size_in_gb=5
  )
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    rules=list(profiler_custom_rule),
    disable_profiler=TRUE
  )
  expect_error(
    f$fit("s3://mydata"),
    "ProfilerRule cannot be set when disable_profiler is True.",
    class = "RuntimeError"
  )
})

test_that("test_framework_with_enabling_default_profiling_when_profiler_is_already_enabled", {
  sms = sagemaker_session()
  sms$.call_args(
    "describe_training_job",
    return_value = modifyList(DESCRIBE_TRAINING_JOB_RESULT, list("ProfilingStatus" = "Enabled"))
  )
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  f$fit("s3://mydata")
  expect_error(
    f$enable_default_profiling(),
    paste0("Debugger monitoring is already enabled. To update the profiler_config parameter ",
           "and the Debugger profiling rules, please use the update_profiler function."),
    class = "ValueError"
  )
})

test_that("test_framework_with_enabling_default_profiling", {
  sms = sagemaker_session()
  sms$.call_args(
    "describe_training_job",
    return_value = modifyList(DESCRIBE_TRAINING_JOB_RESULT, list("ProfilingStatus" = "Disabled"))
  )
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    disable_profiler=TRUE
  )
  f$fit("s3://mydata")
  f$enable_default_profiling()
  args = sms$update_training_job(..return_value = T)
  expect_equal(args[["profiler_config"]], list(
    "S3OutputPath"=sprintf("s3://%s/", BUCKET_NAME)
  ))
  expect_true(grepl("ProfilerReport-[0-9]+",args[["profiler_rule_configs"]][[1]][["RuleConfigurationName"]]))
  expect_equal(args[["profiler_rule_configs"]][[1]][["RuleEvaluatorImage"]],
    "895741380848.dkr.ecr.us-west-2.amazonaws.com/sagemaker-debugger-rules:latest"
  )
  expect_equal(args[["profiler_rule_configs"]][[1]][["RuleParameters"]], list("rule_to_invoke"="ProfilerReport"))
})

test_that("test_framework_with_enabling_default_profiling_with_existed_s3_output_path", {
  sms = sagemaker_session()
  sms$.call_args(
    "describe_training_job",
    return_value = modifyList(
      DESCRIBE_TRAINING_JOB_RESULT, list(
        "ProfilingStatus" = "Disabled",
        "ProfilerConfig" = list(
          "S3OutputPath"="s3://custom/",
          "ProfilingIntervalInMilliseconds"=1000)
        )
      )
    )
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    disable_profiler=TRUE
  )
  f$fit("s3://mydata")
  f$enable_default_profiling()
  args = sms$update_training_job(..return_value = T)
  expect_equal(args[["profiler_config"]], list(
    "S3OutputPath"="s3://custom/"
  ))
  expect_true(grepl("ProfilerReport-[0-9]+",args[["profiler_rule_configs"]][[1]][["RuleConfigurationName"]]))
  expect_equal(args[["profiler_rule_configs"]][[1]][["RuleEvaluatorImage"]],
               "895741380848.dkr.ecr.us-west-2.amazonaws.com/sagemaker-debugger-rules:latest"
  )
  expect_equal(args[["profiler_rule_configs"]][[1]][["RuleParameters"]], list("rule_to_invoke"="ProfilerReport"))
})

test_that("test_framework_with_disabling_profiling_when_profiler_is_already_disabled", {
  sms = sagemaker_session()
  sms$.call_args(
    "describe_training_job",
    return_value = modifyList(DESCRIBE_TRAINING_JOB_RESULT, list("ProfilingStatus" = "Disabled"))
  )
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  f$fit("s3://mydata")
  expect_error(
    f$disable_profiling(),
    "Profiler is already disabled.",
    class = "ValueError"
  )
})

test_that("test_framework_with_disabling_profiling", {
  sms = sagemaker_session()
  sms$.call_args(
    "describe_training_job",
    return_value = modifyList(DESCRIBE_TRAINING_JOB_RESULT, list("ProfilingStatus" = "Enabled"))
  )
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  f$fit("s3://mydata")
  f$disable_profiling()
  args = sms$update_training_job(..return_value = T)
  expect_equal(args[["profiler_config"]], list("DisableProfiler"=TRUE))
})

test_that("test_framework_with_update_profiler_when_no_training_job", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  expect_error(
    f$update_profiler(system_monitor_interval_millis=1000),
    "Estimator is not associated with a training job",
    class = "ValueError"
  )
})

test_that("test_framework_with_update_profiler_without_any_parameter", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  f$fit("s3://mydata")
  expect_error(
    f$update_profiler(),
    "Please provide profiler config or profiler rule to be updated.",
    class = "ValueError"
  )
})

test_that("test_framework_with_update_profiler_with_debugger_rule", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  f$fit("s3://mydata")
  expect_error(
    f$update_profiler(rules=list(Rule$new()$sagemaker(R6sagemaker.debugger::stalled_training_rule()))),
    "Please provide ProfilerRule to be updated.",
    class = "ValueError"
  )
})

test_that("test_framework_with_update_profiler_config", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  f$fit("s3://mydata")
  f$update_profiler(system_monitor_interval_millis=1000)
  args = sms$update_training_job(..return_value = T)
  expect_equal(args[["profiler_config"]], list(
    "ProfilingIntervalInMilliseconds"=1000
  ))
  expect_false("profiler_rule_configs" %in% names(args))
})

test_that("test_framework_with_update_profiler_report_rule", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  f$fit("s3://mydata")
  f$update_profiler(
    rules=list(
      ProfilerRule$new()$sagemaker(R6sagemaker.debugger::ProfilerReport$new(), name="CustomProfilerReportRule")
    )
  )
  args = sms$update_training_job(..return_value = T)
  expect_equal(args[["profiler_rule_configs"]], list(
    list(
      "RuleConfigurationName"="CustomProfilerReportRule",
      "RuleEvaluatorImage"="895741380848.dkr.ecr.us-west-2.amazonaws.com/sagemaker-debugger-rules:latest",
      "RuleParameters"=list("rule_to_invoke"="ProfilerReport")
    )
  ))
  expect_false("profiler_config" %in% names(args))
})

test_that("test_framework_with_disable_framework_metrics", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  f$fit("s3://mydata")
  f$update_profiler(disable_framework_metrics=TRUE)
  args = sms$update_training_job(..return_value = T)
  expect_equal(args[["profiler_config"]], list("ProfilingParameters"=list()))
  expect_false("profiler_rule_configs" %in% names(args))
})

test_that("test_framework_with_disable_framework_metrics_and_update_system_metrics", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  f$fit("s3://mydata")
  f$update_profiler(system_monitor_interval_millis=1000, disable_framework_metrics=TRUE)
  args = sms$update_training_job(..return_value = T)
  expect_equal(args[["profiler_config"]], list(
    "ProfilingIntervalInMilliseconds"=1000,
    "ProfilingParameters"=list()
  ))
  expect_false("profiler_rule_configs" %in% names(args))
})

test_that("test_framework_with_disable_framework_metrics_and_update_framework_params", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  f$fit("s3://mydata")
  expect_error(
    f$update_profiler(
      framework_profile_params=FrameworkProfile$new(), disable_framework_metrics=TRUE
    ),
    "framework_profile_params cannot be set when disable_framework_metrics is True",
    class = "ValueError"
  )
})

test_that("test_framework_with_update_profiler_config_and_profiler_rule", {
  profiler_custom_rule = ProfilerRule$new()$custom(
    name="CustomProfilerRule",
    image_uri="RuleImageUri",
    instance_type=INSTANCE_TYPE,
    volume_size_in_gb=5
  )
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  f$fit("s3://mydata")
  f$update_profiler(rules=list(profiler_custom_rule), system_monitor_interval_millis=1000)
  args = sms$update_training_job(..return_value = T)
  expect_equal(args[["profiler_config"]], list("ProfilingIntervalInMilliseconds"=1000))
  expect_equal(args[["profiler_rule_configs"]], list(
    list(
      "RuleConfigurationName"="CustomProfilerRule",
      "RuleEvaluatorImage"="RuleImageUri",
      "InstanceType"="c4.4xlarge",
      "VolumeSizeInGB"=5
    )
  ))
})

test_that("test_training_job_with_rule_job_summary", {
  sms = sagemaker_session()
  sms$.call_args("describe_training_job", return_value=modifyList(DESCRIBE_TRAINING_JOB_RESULT, list(
      "DebugRuleEvaluationStatuses" = list(
        list(
          "RuleConfigurationName"="debugger_rule",
          "RuleEvaluationJobArn"="debugger_rule_job_arn",
          "RuleEvaluationStatus"="InProgress"
        )
      ),
      "ProfilerRuleEvaluationStatuses" = list(
        list(
          "RuleConfigurationName"="profiler_rule_1",
          "RuleEvaluationJobArn"="profiler_rule_job_arn_1",
          "RuleEvaluationStatus"="InProgress"
        ),
        list(
          "RuleConfigurationName"="profiler_rule_2",
          "RuleEvaluationJobArn"="profiler_rule_job_arn_2",
          "RuleEvaluationStatus"="ERROR"
        )
      )
    )
  ))
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  f$fit("s3://mydata")

  job_summary = f$rule_job_summary()
  expect_equal(job_summary, list(
    list(
      "RuleConfigurationName"="debugger_rule",
      "RuleEvaluationJobArn"="debugger_rule_job_arn",
      "RuleEvaluationStatus"="InProgress"
    ),
    list(
      "RuleConfigurationName"="profiler_rule_1",
      "RuleEvaluationJobArn"="profiler_rule_job_arn_1",
      "RuleEvaluationStatus"="InProgress"
    ),
    list(
      "RuleConfigurationName"="profiler_rule_2",
      "RuleEvaluationJobArn"="profiler_rule_job_arn_2",
      "RuleEvaluationStatus"="ERROR"
    )
  ))
})

test_that("test_framework_with_spot_and_checkpoints", {
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
    subnets=list("123", "456"),
    security_group_ids=list("789", "012"),
    metric_definitions=list(list("Name"="validation-rmse", "Regex"="validation-rmse=(\\d+)")),
    encrypt_inter_container_traffic=TRUE,
    use_spot_instances=TRUE,
    max_wait=500,
    checkpoint_s3_uri="s3://mybucket/checkpoints/",
    checkpoint_local_path="/tmp/checkpoints"
  )
  f$.__enclos_env__$private$.start_new("s3://mydata", NULL)
  args = sms$train(..return_value = T)
  expect_equal(args, list(
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
    "stop_condition"=list("MaxRuntimeInSeconds"=456, "MaxWaitTimeInSeconds"=500),
    "vpc_config"=list("Subnets"=list("123", "456"), "SecurityGroupIds"=list("789", "012")),
    "input_mode"="inputmode",
    "hyperparameters"=list(),
    "tags"=list(list("foo"="bar")),
    "metric_definitions"=list(list("Name"="validation-rmse", "Regex"="validation-rmse=(\\d+)")),
    "encrypt_inter_container_traffic"=TRUE,
    "image_uri"="fakeimage",
    "use_spot_instances"=TRUE,
    "checkpoint_s3_uri"="s3://mybucket/checkpoints/",
    "checkpoint_local_path"="/tmp/checkpoints"
  ))
})

test_that("test_framework_init_s3_entry_point_invalid", {
  sms = sagemaker_session()
  expect_error(
    DummyFramework$new(
      "s3://remote-script-because-im-mistaken",
      role=ROLE,
      sagemaker_session=sms,
      instance_count=INSTANCE_COUNT,
      instance_type=INSTANCE_TYPE
    ),
    "Must be a path to a local file",
    class = "ValueError"
  )
})

test_that("test_sagemaker_s3_uri_invalid", {
  sms = sagemaker_session()
  t = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  expect_error(
    t$fit("thisdoesntstartwiths3"),
    "must be a valid S3 or FILE URI",
    class = "ValueError"
  )
})

test_that("test_sagemaker_model_s3_uri_invalid", {
  sms = sagemaker_session()
  t = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    model_uri="thisdoesntstartwiths3either.tar.gz"
  )
  expect_error(
    t$fit("s3://mydata"),
    "must be a valid S3 or FILE URI",
    class="ValueError"
  )
})

test_that("test_sagemaker_model_file_uri_invalid", {
  sms = sagemaker_session()
  t = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    model_uri="file://notins3.tar.gz"
  )
  expect_error(
    t$fit("s3://mydata"),
    "File URIs are supported in local mode only",
    class = "ValueError"
  )
})

test_that("test_sagemaker_model_default_channel_name", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point="my_script.py",
    role="DummyRole",
    instance_count=3,
    instance_type="ml.m4.xlarge",
    sagemaker_session=sms,
    model_uri="s3://model-bucket/prefix/model.tar.gz"
  )
  f$.__enclos_env__$private$.start_new(list(), NULL)
  args = sms$train(..return_value = T)
  expect_equal(args[["input_config"]], list(
    list(
      "DataSource"=list(
        "S3DataSource"=list(
          "S3DataType"="S3Prefix",
          "S3Uri"="s3://model-bucket/prefix/model.tar.gz",
          "S3DataDistributionType"="FullyReplicated"
        )
      ),
      "ContentType"= "application/x-sagemaker-model",
      "InputMode"="File",
      "ChannelName"="model"
    )
  ))
})

