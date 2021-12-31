# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/tests/unit/test_session.py

lg = lgr::get_logger("sagemaker")

MODEL_DATA = "s3://bucket/model.tar.gz"
MODEL_IMAGE = "mi"
ENTRY_POINT = "blah.py"

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
JOB_NAME = sprintf("%s-[0-9:.-]+", IMAGE_URI)
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
        self$sagemaker_session,
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
        if(is.null(entry_point)) ENTRY_POINT else entry_point,
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

  cloudwatchlogs = Mock$new(name="cloudwatchlogs")

  paws_mock$.call_args("client", side_effect = function(obj, ...){
    switch(obj,
           "cloudwatchlogs" = cloudwatchlogs)
  })

  sms = Mock$new(
    name="Session",
    paws_session=paws_mock,
    paws_region_name=region,
    config=NULL,
    local_mode=FALSE,
    s3=NULL
  )

  sagemaker = Mock$new()
  sagemaker$.call_args("describe_training_job", return_value=DESCRIBE_TRAINING_JOB_RESULT)
  sagemaker$.call_args("describe_endpoint", return_value=ENDPOINT_DESC)
  sagemaker$.call_args("describe_endpoint_config", return_value=ENDPOINT_CONFIG_DESC)
  sagemaker$.call_args("list_tags", return_value=LIST_TAGS_RESULT)
  sagemaker$.call_args("train")

  s3_client = Mock$new()
  s3_client$.call_args("put_object")

  sms$.call_args("default_bucket", return_value=BUCKET_NAME)
  sms$.call_args("upload_data", return_value=OUTPUT_PATH)
  sms$.call_args("expand_role")
  sms$.call_args("train")
  sms$.call_args("logs_for_job")
  sms$.call_args("wait_for_job")
  sms$.call_args("describe_training_job", return_value=DESCRIBE_TRAINING_JOB_RESULT)
  sms$.call_args("update_training_job")
  sms$.call_args("wait_for_model_package")
  sms$.call_args("create_model_package_from_algorithm")
  sms$.call_args("create_model")
  sms$.call_args("endpoint_from_production_variants")
  sms$.call_args("create_model_package_from_containers", return_value = list(ModelPackageArn="dummy"))
  sms$sagemaker = sagemaker
  sms$s3 = s3_client
  return(sms)
}

training_job_description = function(returned_job_description = RETURNED_JOB_DESCRIPTION, ll = list()){
  sms = sagemaker_session()
  sms$sagemaker$.call_args("describe_training_job", return_value=modifyList(
    returned_job_description, ll))
  sms$.call_args("describe_training_job", return_value=modifyList(
    returned_job_description, ll))
  return(sms)
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
    base_config=sagemaker.debugger::stalled_training_rule(),
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
    rules=list(Rule$new()$sagemaker(sagemaker.debugger::stalled_training_rule()))
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
  stop_training_action = sagemaker.debugger::StopTraining$new()
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    rules=list(Rule$new()$sagemaker(sagemaker.debugger::stalled_training_rule(), actions=stop_training_action))
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
  action_list = sagemaker.debugger::ActionList$new(
    sagemaker.debugger::StopTraining$new(),
    sagemaker.debugger::Email$new("abc@abc.com"),
    sagemaker.debugger::SMS$new("+1234567890")
  )
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    rules=list(Rule$new()$sagemaker(sagemaker.debugger::stalled_training_rule(), actions=action_list))
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
    base_config=sagemaker.debugger::stalled_training_rule(),
    rule_parameters=list("threshold"="120", "stop_training_on_fire"="True"),
    collections_to_save=list(
      CollectionConfig$new(
        name="losses", parameters=list("train.save_interval"="50", "eval.save_interval"="10")
      )
    )
  )
  profiler_built_in_rule_with_custom_args = ProfilerRule$new()$sagemaker(
    base_config=sagemaker.debugger::ProfilerReport$new(CPUBottleneck_threshold=90),
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
    rules=list(ProfilerRule$new()$sagemaker(sagemaker.debugger::CPUBottleneck$new(gpu_threshold=60)))
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
    rules=list(ProfilerRule$new()$sagemaker(sagemaker.debugger::CPUBottleneck$new(gpu_threshold=60)))
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
  sms = sagemaker_session(sagemaker.common:::PROFILER_UNSUPPORTED_REGIONS)
  # sms$.call_args("train", list(TrainingJobArn = NULL))
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
    f$update_profiler(rules=list(Rule$new()$sagemaker(sagemaker.debugger::stalled_training_rule()))),
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
      ProfilerRule$new()$sagemaker(sagemaker.debugger::ProfilerReport$new(), name="CustomProfilerReportRule")
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

test_that("test_sagemaker_model_custom_channel_name", {
  sms = sagemaker_session()
  f = DummyFramework$new(
    entry_point="my_script.py",
    role="DummyRole",
    instance_count=3,
    instance_type="ml.m4.xlarge",
    sagemaker_session=sms,
    model_uri="s3://model-bucket/prefix/model.tar.gz",
    model_channel_name="testModelChannel"
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
      "ContentType"="application/x-sagemaker-model",
      "InputMode"="File",
      "ChannelName"="testModelChannel"
    )
  ))
})

test_that("test_custom_code_bucket", {
  code_bucket = "codebucket"
  prefix = "someprefix"
  code_location = sprintf("s3://%s/%s", code_bucket, prefix)
  sms = sagemaker_session()
  t = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    code_location=code_location
  )
  t$fit("s3://bucket/mydata")

  expected_key = sprintf("%s/%s/source/sourcedir.tar.gz", prefix, JOB_NAME)
  args = sms$s3$put_object(..return_value = T)
  expect_equal(args[["Bucket"]], code_bucket)
  expect_true(grepl(expected_key, args[["Key"]]))

  expected_submit_dir = sprintf("s3://%s/%s", code_bucket, expected_key)
  args = sms$train(..return_value = T)
  expect_true(grepl(expected_submit_dir, args[["hyperparameters"]][["sagemaker_submit_directory"]]))
})

test_that("test_custom_code_bucket_without_prefix", {
  code_bucket = "codebucket"
  code_location = sprintf("s3://%s", code_bucket)
  sms = sagemaker_session()
  t = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    code_location=code_location
  )
  t$fit("s3://bucket/mydata")

  expected_key = sprintf("%s/source/sourcedir.tar.gz", JOB_NAME)
  args = sms$s3$put_object(..return_value = T)
  expect_equal(args[["Bucket"]], code_bucket)
  expect_true(grepl(expected_key, args[["Key"]]))

  expected_submit_dir = sprintf("s3://%s/%s", code_bucket, expected_key)
  args = sms$train(..return_value = T)
  expect_true(grepl(expected_submit_dir, args[["hyperparameters"]][["sagemaker_submit_directory"]]))
})

test_that("test_invalid_custom_code_bucket", {
  code_location = "thisllworkright?"
  sms = sagemaker_session()
  t = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    code_location=code_location
  )
  expect_error(
    t$fit("s3://bucket/mydata")
  )
})

test_that("test_augmented_manifest", {
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role="DummyRole",
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  fw$fit(
    inputs=TrainingInput$new(
      "s3://mybucket/train_manifest",
      s3_data_type="AugmentedManifestFile",
      attribute_names=list("foo", "bar")
    )
  )
  train_kwargs = sms$train(..return_value = T)
  s3_data_source = train_kwargs[["input_config"]][[1]][["DataSource"]][["S3DataSource"]]
  expect_equal(s3_data_source[["S3Uri"]], "s3://mybucket/train_manifest")
  expect_equal(s3_data_source[["S3DataType"]], "AugmentedManifestFile")
  expect_equal(s3_data_source[["AttributeNames"]], list("foo", "bar"))
})

test_that("test_s3_input_mode", {
  expected_input_mode = "Pipe"
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role="DummyRole",
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  fw$fit(inputs=TrainingInput$new("s3://mybucket/train_manifest", input_mode=expected_input_mode))
  train_kwargs = sms$train(..return_value = T)
  expect_equal(train_kwargs[["input_config"]][[1]][["InputMode"]], "Pipe")
  expect_equal(train_kwargs[["input_mode"]], "Pipe")
})

test_that("test_shuffle_config", {
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role="DummyRole",
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  fw$fit(inputs=TrainingInput$new("s3://mybucket/train_manifest", shuffle_config=ShuffleConfig$new(100)))
  train_kwargs = sms$train(..return_value = T)
  channel = train_kwargs[["input_config"]][[1]]
  expect_equal(channel[["ShuffleConfig"]][["Seed"]], 100)
})

BASE_HP = list(
  "sagemaker_program"=SCRIPT_NAME,
  "sagemaker_submit_directory"=sprintf("s3://mybucket/%s/source/sourcedir.tar.gz", JOB_NAME),
  "sagemaker_job_name"=JOB_NAME
)

sagemaker_local_session = function(region=REGION, config = NULL){
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
  sagemaker$.call_args("describe_training_job", return_value=DESCRIBE_TRAINING_JOB_RESULT)
  sagemaker$.call_args("describe_endpoint", return_value=ENDPOINT_DESC)
  sagemaker$.call_args("describe_endpoint_config", return_value=ENDPOINT_CONFIG_DESC)
  sagemaker$.call_args("list_tags", return_value=LIST_TAGS_RESULT)
  sagemaker$.call_args("train")

  s3_client = Mock$new()
  s3_client$.call_args("put_object")

  sms$.call_args("default_bucket", return_value=BUCKET_NAME)
  sms$.call_args("upload_data", return_value=OUTPUT_PATH)
  sms$.call_args("expand_role")
  sms$.call_args("train")
  sms$.call_args("logs_for_job")
  sms$.call_args("wait_for_job")
  sms$sagemaker = sagemaker
  sms$s3 = s3_client
  return(sms)
}

test_that("test_local_code_location", {
  config = list("local"=list("local_code"=TRUE, "region"="us-west-2"))
  sms = sagemaker_local_session(config = config)
  t = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=1,
    instance_type="local",
    base_job_name=IMAGE_URI,
    hyperparameters=list("123"=456, "learning_rate"=0.1)
  )
  t$fit("file:///data/file")
  expect_equal(t$source_dir, DATA_DIR)
  expect_equal(t$entry_point, "dummy_script.py")
})

test_that("test_start_new_convert_hyperparameters_to_str", {
  uri = "bucket/mydata"
  sms = sagemaker_session()
  t = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    base_job_name=IMAGE_URI,
    hyperparameters=list("123"=list(456), "learning_rate"=0.1)
  )
  t$fit(sprintf("s3://%s",uri))
  expected_hyperparameters = BASE_HP
  expected_hyperparameters[["sagemaker_container_log_level"]] = "20"
  expected_hyperparameters[["learning_rate"]] = "0.1"
  expected_hyperparameters[["123"]] = as.character(jsonlite::toJSON(list(456), auto_unbox = T))
  expected_hyperparameters[["sagemaker_region"]] = 'us-west-2'

  actual_hyperparameter = sms$train(..return_value = T)$hyperparameters

  for (n in sort(names(expected_hyperparameters))){
    if (!(n  %in% c("sagemaker_job_name", "sagemaker_submit_directory")))
      expect_equal(actual_hyperparameter[[n]], expected_hyperparameters[[n]])
    else
      expect_true(grepl(expected_hyperparameters[[n]], actual_hyperparameter[[n]]))
  }
})

test_that("test_start_new_wait_called", {
  uri = "bucket/mydata"
  sms = sagemaker_session()
  t = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  t$fit(sprintf("s3://%s",uri))
  expected_hyperparameters = BASE_HP
  expected_hyperparameters[["sagemaker_container_log_level"]] = "20"
  expected_hyperparameters[["sagemaker_region"]] = 'us-west-2'

  actual_hyperparameter = sms$train(..return_value = T)$hyperparameters
  for (n in sort(names(expected_hyperparameters))){
    if (!(n  %in% c("sagemaker_job_name", "sagemaker_submit_directory")))
      expect_equal(actual_hyperparameter[[n]], expected_hyperparameters[[n]])
    else
      expect_true(grepl(expected_hyperparameters[[n]], actual_hyperparameter[[n]]))
  }
})

test_that("test_attach_framework", {
  sms = training_job_description(ll=list(
    "VpcConfig" = list("Subnets"=list("foo"), "SecurityGroupIds"=list("bar")),
    "EnableNetworkIsolation" = TRUE)
  )
  f = DummyFramework$new("dummy", instance_count=10, instance_type="dummy", role = "dummy", sagemaker_session=sms)
  framework_estimator = f$attach(
    training_job_name="neo", sagemaker_session=sms
  )
  expect_equal(framework_estimator$.current_job_name, "neo")
  expect_equal(framework_estimator$latest_training_job, "neo")
  expect_equal(framework_estimator$role, "arn:aws:iam::366:role/SageMakerRole")
  expect_equal(framework_estimator$instance_count, 1)
  expect_equal(framework_estimator$max_run, 24 * 60 * 60)
  expect_equal(framework_estimator$input_mode, "File")
  expect_equal(framework_estimator$base_job_name, "neo")
  expect_equal(framework_estimator$output_path, "s3://place/output/neo")
  expect_equal(framework_estimator$output_kms_key, "")
  expect_equal(framework_estimator$hyperparameters()$training_steps, "100")
  expect_equal(framework_estimator$source_dir, "s3://some/sourcedir.tar.gz")
  expect_equal(framework_estimator$entry_point, "iris-dnn-classifier.py")
  expect_equal(framework_estimator$subnets, list("foo"))
  expect_equal(framework_estimator$security_group_ids, list("bar"))
  expect_false(framework_estimator$encrypt_inter_container_traffic)
  expect_equal(framework_estimator$tags, LIST_TAGS_RESULT[["Tags"]])
  expect_equal(framework_estimator$tags, LIST_TAGS_RESULT[["Tags"]])
  expect_true(framework_estimator$enable_network_isolation())
})

mod_list = list("VpcConfig" = list("Subnets"=list("foo"), "SecurityGroupIds"=list("bar")), "EnableNetworkIsolation" = TRUE)

test_that("test_attach_framework", {
  SagemakerSesion = training_job_description(ll=mod_list)
  f = DummyFramework$new("dummy", instance_count=10, instance_type="dummy", role = "dummy", sagemaker_session=SagemakerSesion)
  framework_estimator = f$attach(training_job_name="neo", sagemaker_session=SagemakerSesion)
  expect_equal(framework_estimator$.current_job_name, "neo")
  expect_equal(framework_estimator$latest_training_job, "neo")
  expect_equal(framework_estimator$role, "arn:aws:iam::366:role/SageMakerRole")
  expect_equal(framework_estimator$instance_count, 1)
  expect_equal(framework_estimator$max_run, 24 * 60 * 60)
  expect_equal(framework_estimator$input_mode, "File")
  expect_equal(framework_estimator$base_job_name, "neo")
  expect_equal(framework_estimator$output_path, "s3://place/output/neo")
  expect_equal(framework_estimator$output_kms_key, "")
  expect_equal(framework_estimator$hyperparameters()$training_steps, "100")
  expect_equal(framework_estimator$source_dir, "s3://some/sourcedir.tar.gz")
  expect_equal(framework_estimator$entry_point, "iris-dnn-classifier.py")
  expect_equal(framework_estimator$subnets, list("foo"))
  expect_equal(framework_estimator$security_group_ids, list("bar"))
  expect_false(framework_estimator$encrypt_inter_container_traffic)
  expect_equal(framework_estimator$tags, LIST_TAGS_RESULT[["Tags"]])
  expect_equal(framework_estimator$tags, LIST_TAGS_RESULT[["Tags"]])
  expect_true(framework_estimator$enable_network_isolation())
})

test_that("test_attach_no_logs", {
  SagemakerSesion = training_job_description(ll = mod_list)
  f = Estimator$new("dummy", instance_count=10, instance_type="dummy", role = "dummy", sagemaker_session=SagemakerSesion)
  f$attach(training_job_name="job", sagemaker_session=SagemakerSesion)
  expect_equal(SagemakerSesion$logs_for_job(..count = T), 0)
  expect_null(SagemakerSesion$logs_for_job(..return_value = T))
})

test_that("test_logs", {
  SagemakerSesion = training_job_description(ll = mod_list)
  f = Estimator$new("dummy", instance_count=10, instance_type="dummy", role = "dummy", sagemaker_session=SagemakerSesion)
  estimator = f$attach(training_job_name="job", sagemaker_session=SagemakerSesion)
  estimator$logs()
  expect_true(SagemakerSesion$logs_for_job(..return_value = T)$wait)
})

test_that("test_attach_without_hyperparameters", {
  RETURNED_JOB_NO_HYPER_DESC = RETURNED_JOB_DESCRIPTION
  RETURNED_JOB_NO_HYPER_DESC[["HyperParameters"]] = NULL
  SagemakerSesion = training_job_description(RETURNED_JOB_NO_HYPER_DESC, ll = mod_list)
  f = Estimator$new("dummy", instance_count=10, instance_type="dummy", role = "dummy", sagemaker_session=SagemakerSesion)
  estimator = f$attach(training_job_name="job", sagemaker_session=SagemakerSesion)

  expect_equal(estimator$hyperparameters(), list())
})

test_that("test_attach_framework_with_tuning", {
  sms = training_job_description(ll = list("HyperParameters"= list("_tuning_objective_metric"="Validation-accuracy")))
  f = DummyFramework$new("dummy", instance_count=10, instance_type="dummy", role = "dummy", sagemaker_session=sms)
  framework_estimator = f$attach(training_job_name="neo", sagemaker_session=sms)
  expect_equal(framework_estimator$latest_training_job, "neo")
  expect_equal(framework_estimator$role, "arn:aws:iam::366:role/SageMakerRole")
  expect_equal(framework_estimator$instance_count, 1)
  expect_equal(framework_estimator$max_run, 24 * 60 * 60)
  expect_equal(framework_estimator$input_mode, "File")
  expect_equal(framework_estimator$base_job_name, "neo")
  expect_equal(framework_estimator$output_path, "s3://place/output/neo")
  expect_equal(framework_estimator$output_kms_key, "")
  hyper_params = framework_estimator$hyperparameters()
  expect_equal(hyper_params[["training_steps"]], "100")
  expect_equal(hyper_params[["_tuning_objective_metric"]], "Validation-accuracy")
  expect_equal(framework_estimator$source_dir, "s3://some/sourcedir.tar.gz")
  expect_equal(framework_estimator$entry_point, "iris-dnn-classifier.py")
  expect_false(framework_estimator$encrypt_inter_container_traffic)
})

test_that("test_attach_framework_with_model_channel", {
  s3_uri = "s3://some/s3/path/model.tar.gz"
  sms = training_job_description(ll = list("InputDataConfig" = list(
    list(
      "ChannelName"="model",
      "InputMode"="File",
      "DataSource"=list("S3DataSource"=list("S3Uri"=s3_uri))
      )
    )
  ))
  f = DummyFramework$new("dummy", instance_count=10, instance_type="dummy", role = "dummy", sagemaker_session=sms)
  framework_estimator = f$attach(training_job_name="neo", sagemaker_session=sms)
  expect_equal(framework_estimator$model_uri, s3_uri)
  expect_false(framework_estimator$encrypt_inter_container_traffic)
})

test_that("test_attach_framework_with_inter_container_traffic_encryption_flag", {
  sms = training_job_description(ll = list("EnableInterContainerTrafficEncryption" = TRUE))
  f = DummyFramework$new("dummy", instance_count=10, instance_type="dummy", role = "dummy", sagemaker_session=sms)
  framework_estimator = f$attach(training_job_name="neo", sagemaker_session=sms)
  expect_true(framework_estimator$encrypt_inter_container_traffic)
})

test_that("test_attach_framework_base_from_generated_name", {
  base_job_name = "neo"
  sms = training_job_description()
  f = DummyFramework$new("dummy", instance_count=10, instance_type="dummy", role = "dummy", sagemaker_session=sms)
  framework_estimator = f$attach(training_job_name=name_from_base(base_job_name), sagemaker_session=sms)
  expect_equal(framework_estimator$base_job_name, base_job_name)
})

test_that("est_fit_verify_job_name", {
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role="DummyRole",
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    tags=TAGS,
    encrypt_inter_container_traffic=TRUE
  )
  fw$fit(inputs=TrainingInput$new("s3://mybucket/train"))
  train_kwargs = sms$train(..return_value = T)
  expect_equal(train_kwargs$image_uri, IMAGE_URI)
  expect_equal(train_kwargs$input_mode, "File")
  expect_equal(train_kwargs$tags, TAGS)
  expect_true(grepl(JOB_NAME, train_kwargs$job_name))
  expect_true(train_kwargs$encrypt_inter_container_traffic)
})

test_that("test_prepare_for_training_unique_job_name_generation", {
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  fw$.prepare_for_training()
  first_job_name = fw$.current_job_name

  Sys.sleep(0.1)
  fw$.prepare_for_training()
  second_job_name = fw$.current_job_name

  expect_false(first_job_name == second_job_name)
})

test_that("test_prepare_for_training_force_name", {
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    base_job_name="some"
  )
  fw$.prepare_for_training(job_name="use_it")
  expect_equal(fw$.current_job_name, "use_it")
})

test_that("test_prepare_for_training_force_name_generation", {
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    base_job_name="some"
  )
  fw$base_job_name = NULL
  fw$.prepare_for_training()
  expect_true(grepl(JOB_NAME, fw$.current_job_name))
})

test_that("test_git_support_with_branch_and_commit_succeed", {
  mock_git_clone_repo = mock_fun(side_effect = function(...) list(
    "entry_point"="/tmp/repo_dir/entry_point",
    "source_dir"=NULL,
    "dependencies"=NULL)
  )
  mock_tar_and_upload_dir = mock_fun(side_effect = function(...) list())
  git_config = list("repo"=GIT_REPO, "branch"=BRANCH, "commit"=COMMIT)
  entry_point = "entry_point"
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=entry_point,
    git_config=git_config,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  assign(
    "git_clone_repo",
    mock_git_clone_repo,
    envir = environment(fw$.prepare_for_training)
  )
  assign(
    "tar_and_upload_dir",
    mock_tar_and_upload_dir,
    envir = environment(fw$.__enclos_env__$private$.stage_user_code_in_s3)
  )
  fw$fit()
  expect_equal(mock_git_clone_repo(..return_value = T), list(
      git_config,
      entry_point,
      NULL,
      list()
  ))
})

test_that("test_git_support_with_branch_succeed", {
  mock_git_clone_repo = mock_fun(side_effect = function(...) list(
    "entry_point"="/tmp/repo_dir/source_dir/entry_point",
    "source_dir"=NULL,
    "dependencies"=NULL)
  )
  mock_tar_and_upload_dir = mock_fun(side_effect = function(...) list())
  git_config = list("repo"=GIT_REPO, "branch"=BRANCH)
  entry_point = "entry_point"
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=entry_point,
    git_config=git_config,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  assign(
    "git_clone_repo",
    mock_git_clone_repo,
    envir = environment(fw$.prepare_for_training)
  )
  assign(
    "tar_and_upload_dir",
    mock_tar_and_upload_dir,
    envir = environment(fw$.__enclos_env__$private$.stage_user_code_in_s3)
  )
  fw$fit()
  expect_equal(mock_git_clone_repo(..return_value = T), list(
    git_config,
    entry_point,
    NULL,
    list()
  ))
})

test_that("test_git_support_with_dependencies_succeed", {
  mock_git_clone_repo = mock_fun(side_effect = function(...) list(
    "entry_point"="/tmp/repo_dir/source_dir/entry_point",
    "source_dir"=NULL,
    "dependencies"=list("/tmp/repo_dir/foo", "/tmp/repo_dir/foo/bar"))
  )
  mock_tar_and_upload_dir = mock_fun(side_effect = function(...) list())
  git_config = list("repo"=GIT_REPO, "branch"=BRANCH,"commit"=COMMIT)
  entry_point = "entry_point"
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=entry_point,
    git_config=git_config,
    dependencies=list("foo", "foo/bar"),
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  assign(
    "git_clone_repo",
    mock_git_clone_repo,
    envir = environment(fw$.prepare_for_training)
  )
  assign(
    "tar_and_upload_dir",
    mock_tar_and_upload_dir,
    envir = environment(fw$.__enclos_env__$private$.stage_user_code_in_s3)
  )
  fw$fit()
  expect_equal(mock_git_clone_repo(..return_value = T), list(
    git_config,
    entry_point,
    NULL,
    list("foo", "foo/bar")
  ))
})

test_that("test_git_support_without_branch_and_commit_succeed", {
  mock_git_clone_repo = mock_fun(side_effect = function(...) list(
    "entry_point"="/tmp/repo_dir/source_dir/entry_point",
    "source_dir"=NULL,
    "dependencies"=NULL)
  )
  mock_tar_and_upload_dir = mock_fun(side_effect = function(...) list())
  git_config = list("repo"=GIT_REPO)
  entry_point = "source_dir/entry_point"
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=entry_point,
    git_config=git_config,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  assign(
    "git_clone_repo",
    mock_git_clone_repo,
    envir = environment(fw$.prepare_for_training)
  )
  assign(
    "tar_and_upload_dir",
    mock_tar_and_upload_dir,
    envir = environment(fw$.__enclos_env__$private$.stage_user_code_in_s3)
  )
  fw$fit()
  expect_equal(mock_git_clone_repo(..return_value = T), list(
    git_config,
    entry_point,
    NULL,
    list()
  ))
})

test_that("test_git_support_repo_not_provided", {
  git_config = list("branch"=BRANCH, "commit"=COMMIT)
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point="entry_point",
    git_config=git_config,
    source_dir="source_dir",
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  expect_error(
    fw$fit(),
    "Please provide a repo for git_config.",
    class = "ValueError"
  )
})

test_that("test_git_support_bad_repo_url_format", {
  git_config = list("repo"="hhttps://github.com/user/repo.git", "branch"=BRANCH)
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point="entry_point",
    git_config=git_config,
    source_dir="source_dir",
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  expect_error(
    fw$fit(),
    "Invalid Git url provided.",
    class = "ValueError"
  )
})

test_that("test_git_support_entry_point_not_exist", {
  mock_git_clone_repo = mock_fun(side_effect = function(...) ValueError$new("Entry point does not exist in the repo."))
  git_config = list("repo"=GIT_REPO, "branch"=BRANCH, "commit"=COMMIT)
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point="entry_point_that_does_not_exist",
    git_config=git_config,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  assign(
    "git_clone_repo",
    mock_git_clone_repo,
    envir = environment(fw$.prepare_for_training)
  )
  expect_error(
    fw$fit(),
    "Entry point does not exist in the repo.",
    class = "ValueError"
  )
})

test_that("test_git_support_source_dir_not_exist", {
  mock_git_clone_repo = mock_fun(side_effect = function(...) ValueError$new("Source directory does not exist in the repo."))
  git_config = list("repo"=GIT_REPO, "branch"=BRANCH, "commit"=COMMIT)
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point="entry_point",
    git_config=git_config,
    source_dir="source_dir_that_does_not_exist",
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  assign(
    "git_clone_repo",
    mock_git_clone_repo,
    envir = environment(fw$.prepare_for_training)
  )
  expect_error(
    fw$fit(),
    "Source directory does not exist in the repo.",
    class = "ValueError"
  )
})

test_that("test_git_support_dependencies_not_exist", {
  mock_git_clone_repo = mock_fun(side_effect = function(...) ValueError$new("Dependency no-such-dir does not exist in the repo."))
  git_config = list("repo"=GIT_REPO, "branch"=BRANCH, "commit"=COMMIT)
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point="entry_point",
    git_config=git_config,
    source_dir="source_dir",
    dependencies=list("foo", "no-such-dir"),
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  assign(
    "git_clone_repo",
    mock_git_clone_repo,
    envir = environment(fw$.prepare_for_training)
  )
  expect_error(
    fw$fit(),
    "Dependency no-such-dir does not exist in the repo.",
    class = "ValueError"
  )
})

test_that("test_git_support_with_username_password_no_2fa", {
  mock_git_clone_repo = mock_fun(side_effect = function(...) list(
    "entry_point"="/tmp/repo_dir/entry_point",
    "source_dir"=NULL,
    "dependencies"=NULL
  ))
  mock_tar_and_upload_dir = mock_fun(side_effect = function(...) list())
  git_config = list(
    "repo"=PRIVATE_GIT_REPO,
    "branch"=PRIVATE_BRANCH,
    "commit"=PRIVATE_COMMIT,
    "username"="username",
    "password"="passw0rd!"
  )
  entry_point="entry_point"
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=entry_point,
    git_config=git_config,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  assign(
    "git_clone_repo",
    mock_git_clone_repo,
    envir = environment(fw$.prepare_for_training)
  )
  assign(
    "tar_and_upload_dir",
    mock_tar_and_upload_dir,
    envir = environment(fw$.__enclos_env__$private$.stage_user_code_in_s3)
  )
  fw$fit()
  expect_equal(mock_git_clone_repo(..return_value = T), list(git_config, entry_point, NULL, list()))
  expect_equal(fw$entry_point, "/tmp/repo_dir/entry_point")
})

test_that("test_git_support_with_token_2fa", {
  mock_git_clone_repo = mock_fun(side_effect = function(...) list(
    "entry_point"="/tmp/repo_dir/entry_point",
    "source_dir"=NULL,
    "dependencies"=NULL
  ))
  mock_tar_and_upload_dir = mock_fun(side_effect = function(...) list())
  git_config = list(
    "repo"=PRIVATE_GIT_REPO,
    "branch"=PRIVATE_BRANCH,
    "commit"=PRIVATE_COMMIT,
    "token"="my-token",
    "2FA_enabled"=TRUE
  )
  entry_point = "entry_point"
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=entry_point,
    git_config=git_config,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  assign(
    "git_clone_repo",
    mock_git_clone_repo,
    envir = environment(fw$.prepare_for_training)
  )
  assign(
    "tar_and_upload_dir",
    mock_tar_and_upload_dir,
    envir = environment(fw$.__enclos_env__$private$.stage_user_code_in_s3)
  )
  fw$fit()
  expect_equal(mock_git_clone_repo(..return_value = T), list(git_config, entry_point, NULL, list()))
  expect_equal(fw$entry_point, "/tmp/repo_dir/entry_point")
})

test_that("test_git_support_ssh_no_passphrase_needed", {
  mock_git_clone_repo = mock_fun(side_effect = function(...) list(
    "entry_point"="/tmp/repo_dir/entry_point",
    "source_dir"=NULL,
    "dependencies"=NULL
  ))
  mock_tar_and_upload_dir = mock_fun(side_effect = function(...) list())
  git_config = list("repo"=PRIVATE_GIT_REPO_SSH, "branch"=PRIVATE_BRANCH, "commit"=PRIVATE_COMMIT)
  sms = sagemaker_session()
  entry_point="entry_point"
  fw = DummyFramework$new(
    entry_point=entry_point,
    git_config=git_config,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
  )
  assign(
    "git_clone_repo",
    mock_git_clone_repo,
    envir = environment(fw$.prepare_for_training)
  )
  assign(
    "tar_and_upload_dir",
    mock_tar_and_upload_dir,
    envir = environment(fw$.__enclos_env__$private$.stage_user_code_in_s3)
  )
  fw$fit()
  expect_equal(mock_git_clone_repo(..return_value = T), list(git_config, entry_point, NULL, list()))
  expect_equal(fw$entry_point, "/tmp/repo_dir/entry_point")
})

test_that("test_git_support_codecommit_with_username_and_password_succeed", {
  mock_git_clone_repo = mock_fun(side_effect = function(...) list(
    "entry_point"="/tmp/repo_dir/entry_point",
    "source_dir"=NULL,
    "dependencies"=NULL
  ))
  mock_tar_and_upload_dir = mock_fun(side_effect = function(...) list())
  git_config = list(
    "repo"=CODECOMMIT_REPO,
    "branch"=CODECOMMIT_BRANCH,
    "username"="username",
    "password"="passw0rd!"
  )
  entry_point = "entry_point"
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=entry_point,
    git_config=git_config,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  assign(
    "git_clone_repo",
    mock_git_clone_repo,
    envir = environment(fw$.prepare_for_training)
  )
  assign(
    "tar_and_upload_dir",
    mock_tar_and_upload_dir,
    envir = environment(fw$.__enclos_env__$private$.stage_user_code_in_s3)
  )
  fw$fit()
  expect_equal(mock_git_clone_repo(..return_value = T), list(git_config, entry_point, NULL, list()))
  expect_equal(fw$entry_point, "/tmp/repo_dir/entry_point")
})

test_that("test_git_support_codecommit_with_ssh_no_passphrase_needed", {
  mock_git_clone_repo = mock_fun(side_effect = function(...) list(
    "entry_point"="/tmp/repo_dir/entry_point",
    "source_dir"=NULL,
    "dependencies"=NULL
  ))
  mock_tar_and_upload_dir = mock_fun(side_effect = function(...) list())
  git_config = list("repo"=CODECOMMIT_REPO_SSH, "branch"=CODECOMMIT_BRANCH)
  entry_point = "entry_point"
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=entry_point,
    git_config=git_config,
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  assign(
    "git_clone_repo",
    mock_git_clone_repo,
    envir = environment(fw$.prepare_for_training)
  )
  assign(
    "tar_and_upload_dir",
    mock_tar_and_upload_dir,
    envir = environment(fw$.__enclos_env__$private$.stage_user_code_in_s3)
  )
  fw$fit()
  expect_equal(mock_git_clone_repo(..return_value = T), list(git_config, entry_point, NULL, list()))
  expect_equal(fw$entry_point, "/tmp/repo_dir/entry_point")
})

test_that("test_init_with_source_dir_s3", {
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=SCRIPT_NAME,
    source_dir="s3://location",
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  fw$.prepare_for_training()
  actual = fw$hyperparameters()
  expect_equal(actual[["sagemaker_submit_directory"]], "s3://location")
  expect_equal(actual[["sagemaker_program"]], SCRIPT_NAME)
  expect_equal(actual[["sagemaker_container_log_level"]], "20")
  expect_true(grepl(JOB_NAME, actual[["sagemaker_job_name"]]))
  expect_equal(actual[["sagemaker_region"]], "us-west-2")
})

test_that("test_framework_transformer_creation", {
  vpc_config = list("Subnets"=list("foo"), "SecurityGroupIds"=list("bar"))
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    sagemaker_session=sms,
    subnets=vpc_config[["Subnets"]],
    security_group_ids=vpc_config[["SecurityGroupIds"]]
  )
  fw$latest_training_job = JOB_NAME
  assign("name_from_base", mock_fun(MODEL_IMAGE), envir = environment(fw$.__enclos_env__$private$.get_or_create_name))

  transformer = fw$transformer(INSTANCE_COUNT, INSTANCE_TYPE)
  expect_equal(sms$create_model(..return_value = T), list(
    MODEL_IMAGE,
    ROLE,
    MODEL_CONTAINER_DEF,
    vpc_config=vpc_config,
    enable_network_isolation=FALSE,
    tags=NULL
  ))
  expect_true(inherits(transformer, "Transformer"))
  expect_equal(transformer$sagemaker_session, sms)
  expect_equal(transformer$instance_count, INSTANCE_COUNT)
  expect_equal(transformer$instance_type, INSTANCE_TYPE)
  expect_equal(transformer$model_name, MODEL_IMAGE)
  expect_null(transformer$tags)
  expect_equal(transformer$env, list())
})

test_that("test_framework_transformer_creation_with_optional_params", {
  base_name = "foo"
  vpc_config = list("Subnets"=list("foo"), "SecurityGroupIds"=list("bar"))
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    sagemaker_session=sms,
    base_job_name=base_name,
    subnets=vpc_config[["Subnets"]],
    security_group_ids=vpc_config[["SecurityGroupIds"]],
    enable_network_isolation=FALSE
  )
  fw$latest_training_job = JOB_NAME
  assign("name_from_base", mock_fun(MODEL_IMAGE), envir = environment(fw$.__enclos_env__$private$.get_or_create_name))

  strategy = "MultiRecord"
  assemble_with = "Line"
  kms_key = "key"
  accept = "text/csv"
  max_concurrent_transforms = 1
  max_payload = 6
  env = list("FOO"="BAR")
  new_role = "dummy-model-role"
  new_vpc_config = list("Subnets"=list("x"), "SecurityGroupIds"=list("y"))
  model_name = "model-name"

  transformer = fw$transformer(
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    strategy=strategy,
    assemble_with=assemble_with,
    output_path=OUTPUT_PATH,
    output_kms_key=kms_key,
    accept=accept,
    tags=TAGS,
    max_concurrent_transforms=max_concurrent_transforms,
    max_payload=max_payload,
    volume_kms_key=kms_key,
    env=env,
    role=new_role,
    model_server_workers=1,
    vpc_config_override=new_vpc_config,
    enable_network_isolation=TRUE,
    model_name=model_name
  )
  expect_equal(sms$create_model(..return_value = T), list(
    model_name,
    new_role,
    MODEL_CONTAINER_DEF,
    vpc_config=new_vpc_config,
    enable_network_isolation=TRUE,
    tags=TAGS
  ))
  expect_equal(transformer$strategy, strategy)
  expect_equal(transformer$assemble_with, assemble_with)
  expect_equal(transformer$output_path, OUTPUT_PATH)
  expect_equal(transformer$output_kms_key, kms_key)
  expect_equal(transformer$accept, accept)
  expect_equal(transformer$max_concurrent_transforms, max_concurrent_transforms)
  expect_equal(transformer$max_payload, max_payload)
  expect_equal(transformer$env, env)
  expect_equal(transformer$base_transform_job_name, base_name)
  expect_equal(transformer$volume_kms_key, kms_key)
  expect_equal(transformer$model_name, model_name)
})

test_that("test_ensure_latest_training_job", {
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    sagemaker_session=sms
  )
  fw$latest_training_job = "training_job"
  expect_null(fw$.__enclos_env__$private$.ensure_latest_training_job())
})

test_that("test_ensure_latest_training_job_failure", {
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role=ROLE,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    sagemaker_session=sms
  )
  expect_error(
    fw$.__enclos_env__$private$.ensure_latest_training_job(),
    "Estimator is not associated with a training job",
    class="ValueError"
  )
})

test_that("test_estimator_transformer_creation", {
  sms = sagemaker_session()
  estimator = Estimator$new(
    image_uri=IMAGE_URI,
    role=ROLE,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    sagemaker_session=sms
  )
  estimator$latest_training_job = JOB_NAME
  model_name = "model_name"
  assign(
    "name_from_base",
    mock_fun(model_name),
    envir = environment(estimator$.__enclos_env__$private$.get_or_create_name)
  )
  transformer = estimator$transformer(INSTANCE_COUNT, INSTANCE_TYPE)

  expect_true(inherits(transformer, "Transformer"))
  expect_equal(transformer$sagemaker_session, sms)
  expect_equal(transformer$instance_count, INSTANCE_COUNT)
  expect_equal(transformer$instance_type, INSTANCE_TYPE)
  expect_equal(transformer$model_name, model_name)
  expect_null(transformer$tags)
})

test_that("test_estimator_transformer_creation_with_optional_params", {
  base_name = "foo"
  kms_key = "key"
  sms = sagemaker_session()
  estimator = Estimator$new(
    image_uri=IMAGE_URI,
    role=ROLE,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    sagemaker_session=sms,
    base_job_name=base_name,
    output_kms_key=kms_key
  )
  estimator$latest_training_job = JOB_NAME
  strategy = "MultiRecord"
  assemble_with = "Line"
  accept = "text/csv"
  max_concurrent_transforms = 1
  max_payload = 6
  env = list("FOO"="BAR")
  new_vpc_config = list("Subnets"=list("x"), "SecurityGroupIds"=list("y"))
  model_name = "model-name"

  assign(
    "name_from_base",
    mock_fun(model_name),
    envir = environment(estimator$.__enclos_env__$private$.get_or_create_name)
  )
  transformer = estimator$transformer(
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    strategy=strategy,
    assemble_with=assemble_with,
    output_path=OUTPUT_PATH,
    output_kms_key=kms_key,
    accept=accept,
    tags=TAGS,
    max_concurrent_transforms=max_concurrent_transforms,
    max_payload=max_payload,
    env=env,
    role=ROLE,
    vpc_config_override=new_vpc_config,
    enable_network_isolation=TRUE,
    model_name=model_name
  )
  expect_equal(transformer$strategy, strategy)
  expect_equal(transformer$assemble_with, assemble_with)
  expect_equal(transformer$output_path, OUTPUT_PATH)
  expect_equal(transformer$output_kms_key, kms_key)
  expect_equal(transformer$accept, accept)
  expect_equal(transformer$max_concurrent_transforms, max_concurrent_transforms)
  expect_equal(transformer$max_payload, max_payload)
  expect_equal(transformer$env, env)
  expect_equal(transformer$base_transform_job_name, base_name)
  expect_equal(transformer$tags, TAGS)
  expect_equal(transformer$model_name, model_name)
})

test_that("test_start_new", {
  training_job = JOB_NAME
  hyperparameters = list("mock"="hyperparameters")
  inputs = "s3://mybucket/train"
  sms = sagemaker_session()
  estimator = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms,
    hyperparameters=hyperparameters
  )

  exp_config = list("ExperimentName"="exp", "TrialName"="t", "TrialComponentDisplayName"="tc")
  started_training_job = estimator$.__enclos_env__$private$.start_new(inputs, exp_config)
  called_args = sms$train(..return_value = T)
  expect_equal(called_args[["hyperparameters"]], hyperparameters)
  expect_equal(called_args[["experiment_config"]], exp_config)
})

test_that("test_start_new", {
  training_job = JOB_NAME
  inputs = "file://mybucket/train"
  sms = sagemaker_session()
  estimator = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms
  )
  expect_error(
    estimator$.__enclos_env__$private$.start_new(inputs, exp_config),
    "File URIs are supported in local mode only. Please use a S3 URI instead.",
    class="ValueError"
  )
})

test_that("test_container_log_level", {
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role="DummyRole",
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE,
    container_log_level="DEBUG"
  )
  fw$fit(inputs=TrainingInput$new("s3://mybucket/train"))
  train_kwargs = sms$train(..return_value = T)
  expect_equal(train_kwargs[["hyperparameters"]][["sagemaker_container_log_level"]], "10")
})

test_that("test_wait_without_logs", {
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role="DummyRole",
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  fw$latest_training_job = "JOB_NAME"
  fw$wait(FALSE)

  kwargs = sms$wait_for_job(..return_value = T)
  expect_equal(kwargs[["job"]], "JOB_NAME")
  expect_null(sms$logs_for_job(..return_value = T))
  expect_equal(sms$logs_for_job(..count = T), 0)
})

test_that("test_wait_with_logs", {
  sms = sagemaker_session()
  fw = DummyFramework$new(
    entry_point=SCRIPT_PATH,
    role="DummyRole",
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  fw$latest_training_job = "JOB_NAME"
  fw$wait()

  expect_equal(sms$logs_for_job(..return_value = T), list(
    job_name="JOB_NAME",
    wait=TRUE,
    log_type="All"
  ))
  expect_null(sms$wait_for_job(..return_value = T))
  expect_equal(sms$wait_for_job(..count = T), 0)
})

#################################################################################
# Tests for the generic Estimator class

NO_INPUT_TRAIN_CALL = list(
  "input_config"=NULL,
  "output_config"=list("S3OutputPath"=OUTPUT_PATH),
  "resource_config"=list(
    "InstanceCount"=INSTANCE_COUNT,
    "InstanceType"=INSTANCE_TYPE,
    "VolumeSizeInGB"=30
  ),
  "stop_condition"=list("MaxRuntimeInSeconds"=86400),
  "vpc_config"=NULL,
  "input_mode"="File",
  "hyperparameters"=list(),
  "image_uri"=IMAGE_URI,
  "profiler_rule_configs"=list(
    list(
      "RuleConfigurationName"="ProfilerReport-[0-9]+",
      "RuleEvaluatorImage"="895741380848.dkr.ecr.us-west-2.amazonaws.com/sagemaker-debugger-rules:latest",
      "RuleParameters"=list("rule_to_invoke"="ProfilerReport")
    )
  ),
  "profiler_config"=list("S3OutputPath"=OUTPUT_PATH)
)

INPUT_CONFIG = list(
  list(
    "DataSource"=list(
      "S3DataSource"=list(
        "S3DataType"="S3Prefix",
        "S3Uri"="s3://bucket/training-prefix",
        "S3DataDistributionType"="FullyReplicated"
      )
    ),
    "ChannelName"="train"
  )
)

BASE_TRAIN_CALL = NO_INPUT_TRAIN_CALL
BASE_TRAIN_CALL = modifyList(BASE_TRAIN_CALL, list("input_config"=INPUT_CONFIG))

HYPERPARAMS = list("x"=1, "y"="hello")
STRINGIFIED_HYPERPARAMS = lapply(HYPERPARAMS, function(x) as.character(x))
HP_TRAIN_CALL = BASE_TRAIN_CALL
HP_TRAIN_CALL = modifyList(HP_TRAIN_CALL, list("hyperparameters"=STRINGIFIED_HYPERPARAMS))

EXP_TRAIN_CALL = BASE_TRAIN_CALL
EXP_TRAIN_CALL = modifyList(EXP_TRAIN_CALL, list(
    "experiment_config"=list(
      "ExperimentName"="exp",
      "TrialName"="trial",
      "TrialComponentDisplayName"="tc"
    )
  )
)

test_that("test_fit_deploy_tags_in_estimator", {
  tags = list(list("Key"="TagtestKey", "Value"="TagtestValue"))
  sms = sagemaker_session()
  estimator = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    tags=tags,
    sagemaker_session=sms
  )
  estimator$fit()

  model_name = "model_name"
  assign("name_from_base", mock_fun(model_name), envir = environment(estimator$.__enclos_env__$private$.get_or_create_name))
  estimator$deploy(INSTANCE_COUNT, INSTANCE_TYPE)

  variant = list(
    list(
      "ModelName"=model_name,
      "InstanceType"="c4.4xlarge",
      "InitialInstanceCount"=1,
      "VariantName"="AllTraffic",
      "InitialVariantWeight"=1
    )
  )
  expect_equal(sms$endpoint_from_production_variants(..return_value = T), list(
    name=model_name,
    production_variants=variant,
    tags=tags,
    kms_key=NULL,
    wait=TRUE,
    data_capture_config_list=NULL
  ))
  expect_equal(sms$create_model(..return_value = TRUE), list(
    model_name,
    "DummyRole",
    list("Image"="fakeimage", "Environment"=list(), "ModelDataUrl"="s3://bucket/model.tar.gz"),
    vpc_config=NULL,
    enable_network_isolation=FALSE,
    tags=tags
  ))
})

test_that("test_fit_deploy_tags", {
  sms = sagemaker_session()
  estimator = Estimator$new(
    IMAGE_URI, ROLE, INSTANCE_COUNT, INSTANCE_TYPE, sagemaker_session=sms
  )
  estimator$fit()

  model_name = "model_name"
  mock_name_from_base = mock_fun(model_name)
  assign("name_from_base", mock_name_from_base, envir = environment(estimator$.__enclos_env__$private$.get_or_create_name))

  tags = list(list("Key"="TagtestKey", "Value"="TagtestValue"))
  estimator$deploy(INSTANCE_COUNT, INSTANCE_TYPE, tags=tags)

  variant = list(
    list(
      "ModelName"=model_name,
      "InstanceType"="c4.4xlarge",
      "InitialInstanceCount"=1,
      "VariantName"="AllTraffic",
      "InitialVariantWeight"=1
    )
  )
  expect_equal(mock_name_from_base(..return_value = T), list(IMAGE_URI))
  expect_equal(sms$endpoint_from_production_variants(..return_value = T), list(
    name=model_name,
    production_variants=variant,
    tags=tags,
    kms_key=NULL,
    wait=TRUE,
    data_capture_config_list=NULL
  ))
  expect_equal(sms$create_model(..return_value = TRUE), list(
    model_name,
    "DummyRole",
    list("Image"="fakeimage", "Environment"=list(), "ModelDataUrl"="s3://bucket/model.tar.gz"),
    vpc_config=NULL,
    enable_network_isolation=FALSE,
    tags=tags
  ))
})

test_that("test_generic_to_fit_no_input", {
  sms = sagemaker_session()
  e = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms
  )
  e$fit()

  args = sms$train(..return_value = TRUE)
  expect_true(startsWith(args[["job_name"]], IMAGE_URI))

  args[["job_name"]] = NULL
  args[["role"]] = NULL

  exp_args = NO_INPUT_TRAIN_CALL
  actual_rule_config = args$profiler_rule_configs[[1]]$RuleConfigurationName
  exp_rule_config = exp_args$profiler_rule_configs[[1]]$RuleConfigurationName
  args$profiler_rule_configs[[1]]$RuleConfigurationName = NULL
  exp_args$profiler_rule_configs[[1]]$RuleConfigurationName = NULL
  expect_true(grepl(exp_rule_config, actual_rule_config))
  expect_equal(args, exp_args)
})

test_that("test_generic_to_fit_no_hps", {
  sms = sagemaker_session()
  e = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms
  )
  e$fit(list("train"="s3://bucket/training-prefix"))

  args = sms$train(..return_value = TRUE)
  expect_true(startsWith(args[["job_name"]], IMAGE_URI))

  args[["job_name"]] = NULL
  args[["role"]] = NULL

  exp_args = BASE_TRAIN_CALL
  actual_rule_config = args$profiler_rule_configs[[1]]$RuleConfigurationName
  exp_rule_config = exp_args$profiler_rule_configs[[1]]$RuleConfigurationName
  args$profiler_rule_configs[[1]]$RuleConfigurationName = NULL
  exp_args$profiler_rule_configs[[1]]$RuleConfigurationName = NULL
  expect_true(grepl(exp_rule_config, actual_rule_config))
  expect_equal(args, exp_args)
})

test_that("test_generic_to_fit_with_hps", {
  sms = sagemaker_session()
  e = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms
  )
  do.call(e$set_hyperparameters, HYPERPARAMS)
  e$fit(list("train"="s3://bucket/training-prefix"))

  args = sms$train(..return_value = TRUE)
  expect_true(startsWith(args[["job_name"]], IMAGE_URI))

  args[["job_name"]] = NULL
  args[["role"]] = NULL

  exp_args = HP_TRAIN_CALL
  actual_rule_config = args$profiler_rule_configs[[1]]$RuleConfigurationName
  exp_rule_config = exp_args$profiler_rule_configs[[1]]$RuleConfigurationName
  args$profiler_rule_configs[[1]]$RuleConfigurationName = NULL
  exp_args$profiler_rule_configs[[1]]$RuleConfigurationName = NULL
  expect_true(grepl(exp_rule_config, actual_rule_config))
  expect_equal(args, exp_args)
})

test_that("test_generic_to_fit_with_experiment_config", {
  sms = sagemaker_session()
  e = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms
  )
  e$fit(inputs=list("train"="s3://bucket/training-prefix"),
        experiment_config=list(
          "ExperimentName"="exp",
          "TrialName"="trial",
          "TrialComponentDisplayName"="tc"
        )
  )

  args = sms$train(..return_value = TRUE)
  expect_true(startsWith(args[["job_name"]], IMAGE_URI))

  args[["job_name"]] = NULL
  args[["role"]] = NULL

  exp_args = EXP_TRAIN_CALL
  actual_rule_config = args$profiler_rule_configs[[1]]$RuleConfigurationName
  exp_rule_config = exp_args$profiler_rule_configs[[1]]$RuleConfigurationName
  args$profiler_rule_configs[[1]]$RuleConfigurationName = NULL
  exp_args$profiler_rule_configs[[1]]$RuleConfigurationName = NULL
  expect_true(grepl(exp_rule_config, actual_rule_config))
  expect_equal(args[sort(names(args))], exp_args[sort(names(exp_args))])
})

test_that("test_generic_to_fit_with_encrypt_inter_container_traffic_flag", {
  sms = sagemaker_session()
  e = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms,
    encrypt_inter_container_traffic=TRUE
  )
  e$fit()

  args = sms$train(..return_value = TRUE)

  expect_true(args[["encrypt_inter_container_traffic"]])
})

test_that("test_generic_to_fit_with_network_isolation", {
  sms = sagemaker_session()
  e = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms,
    enable_network_isolation=TRUE
  )
  e$fit()

  args = sms$train(..return_value = TRUE)

  expect_true(args[["enable_network_isolation"]])
})

test_that("test_generic_to_fit_with_sagemaker_metrics_missing", {
  sms = sagemaker_session()
  e = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms
  )
  e$fit()

  args = sms$train(..return_value = TRUE)
  expect_false("enable_sagemaker_metrics" %in% names(args))
})

test_that("test_add_environment_variables_to_train_args", {
  sms = sagemaker_session()
  e = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms,
    environment=ENV_INPUT
  )
  e$fit()

  args = sms$train(..return_value = TRUE)
  expect_equal(args[["environment"]], ENV_INPUT)
})

test_that("test_add_retry_strategy_to_train_args", {
  sms = sagemaker_session()
  e = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms,
    max_retry_attempts=2
  )
  e$fit()

  args = sms$train(..return_value = TRUE)
  expect_equal(args[["retry_strategy"]], list("MaximumRetryAttempts"=2))
})

test_that("test_generic_to_fit_with_sagemaker_metrics_enabled", {
  sms = sagemaker_session()
  e = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms,
    enable_sagemaker_metrics=TRUE
  )
  e$fit()

  args = sms$train(..return_value = TRUE)
  expect_true(args[["enable_sagemaker_metrics"]])
})

test_that("test_generic_to_fit_with_sagemaker_metrics_disabled", {
  sms = sagemaker_session()
  e = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms,
    enable_sagemaker_metrics=FALSE
  )
  e$fit()

  args = sms$train(..return_value = TRUE)
  expect_false("enable_sagemaker_metrics" %in% names(args))
})

test_that("test_generic_to_deploy", {
  sms = sagemaker_session()
  e = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms
  )
  do.call(e$set_hyperparameters, HYPERPARAMS)
  e$fit(list("train"="s3://bucket/training-prefix"))
  predictor = e$deploy(INSTANCE_COUNT, INSTANCE_TYPE)

  args = sms$train(..return_value = TRUE)

  expect_true(startsWith(args[["job_name"]], IMAGE_URI))
  args[["job_name"]] = NULL
  args[["role"]] = NULL

  args$profiler_rule_configs[[1]]$RuleConfigurationName
  exp_args = HP_TRAIN_CALL
  actual_rule_config = args$profiler_rule_configs[[1]]$RuleConfigurationName
  exp_rule_config = exp_args$profiler_rule_configs[[1]]$RuleConfigurationName
  args$profiler_rule_configs[[1]]$RuleConfigurationName = NULL
  exp_args$profiler_rule_configs[[1]]$RuleConfigurationName = NULL
  expect_true(grepl(exp_rule_config, actual_rule_config))

  args = sms$create_model(..return_value = T)
  expect_true(startsWith(args[[1]], IMAGE_URI))
  expect_equal(args[[2]], ROLE)
  expect_equal(args[[3]][["Image"]], IMAGE_URI)
  expect_equal(args[[3]][["ModelDataUrl"]], MODEL_DATA)
  expect_null(args[["vpc_config"]])

  expect_true(inherits(predictor, "Predictor"))
  expect_true(startsWith(predictor$endpoint_name, IMAGE_URI))
  expect_equal(predictor$sagemaker_session, sms)
})

test_that("test_generic_to_deploy_network_isolation", {
  sms = sagemaker_session()
  e = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    enable_network_isolation=TRUE,
    sagemaker_session=sms
  )
  e$fit()
  e$deploy(INSTANCE_COUNT, INSTANCE_TYPE)

  args = sms$create_model(..return_value = T)
  expect_true(args[["enable_network_isolation"]])
})

test_that("test_generic_training_job_analytics", {
  sms = sagemaker_session()
  sms$sagemaker$.call_args("describe_training_job", return_value = list(
    "TuningJobArn"="arn:aws:sagemaker:us-west-2:968277160000:hyper-parameter-tuning-job/mock-tuner",
    "TrainingStartTime"=1530562991.299,
    "AlgorithmSpecification"=list(
      "TrainingImage"="some-image-url",
      "TrainingInputMode"="File",
      "MetricDefinitions"=list(
        list("Name"="train:loss", "Regex"="train_loss=([0-9]+\\.[0-9]+)"),
        list("Name"="validation:loss", "Regex"="valid_loss=([0-9]+\\.[0-9]+)")
      )
    )
  ))
  e = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms
  )
  expect_error(
    e$training_job_analytics,
    class = "ValueError"
  )
  do.call(e$set_hyperparameters, HYPERPARAMS)
  e$fit(list("train"="s3://bucket/training-prefix"))
  a = e$training_job_analytics
  expect_true(!is.null(a))
})

test_that("test_generic_create_model_vpc_config_override", {
  vpc_config_a = list("Subnets"=list("foo"), "SecurityGroupIds"=list("bar"))
  vpc_config_b = list("Subnets"=list("foo", "bar"), "SecurityGroupIds"=list("baz"))

  sms = sagemaker_session()
  e = Estimator$new(
    IMAGE_URI, ROLE, INSTANCE_COUNT, INSTANCE_TYPE, sagemaker_session=sms
  )
  e$fit(list("train"="s3://bucket/training-prefix"))
  expect_null(e$get_vpc_config())
  expect_null(e$create_model()$vpc_config)
  expect_equal(e$create_model(vpc_config_override=vpc_config_a)$vpc_config,vpc_config_a)
  expect_null(e$create_model(vpc_config_override=NULL)$vpc_config)

  e$subnets = vpc_config_a[["Subnets"]]
  e$security_group_ids = vpc_config_a[["SecurityGroupIds"]]
  expect_equal(e$get_vpc_config(), vpc_config_a)
  expect_equal(e$create_model()$vpc_config, vpc_config_a)
  expect_equal(e$create_model(vpc_config_override=vpc_config_b)$vpc_config, vpc_config_b)
  expect_null(e$create_model(vpc_config_override=NULL)$vpc_config)

  expect_error(
    e$get_vpc_config(vpc_config_override=list("invalid")), class = "ValueError"
  )
  expect_error(
    e$create_model(vpc_config_override=list("invalid")), class = "ValueError"
  )
})

test_that("test_generic_deploy_vpc_config_override", {
  vpc_config_a = list("Subnets"=list("foo"), "SecurityGroupIds"=list("bar"))
  vpc_config_b = list("Subnets"=list("foo", "bar"), "SecurityGroupIds"=list("baz"))

  sms = sagemaker_session()
  e = Estimator$new(
    IMAGE_URI, ROLE, INSTANCE_COUNT, INSTANCE_TYPE, sagemaker_session=sms
  )
  e$fit(list("train"="s3://bucket/training-prefix"))
  e$deploy(INSTANCE_COUNT, INSTANCE_TYPE)

  expect_null(sms$create_model(..return_value = T)[["vpc_config"]])

  e$subnets = vpc_config_a[["Subnets"]]
  e$security_group_ids = vpc_config_a[["SecurityGroupIds"]]
  e$deploy(INSTANCE_COUNT, INSTANCE_TYPE)
  expect_equal(sms$create_model(..return_value = T)[["vpc_config"]], vpc_config_a)

  e$deploy(INSTANCE_COUNT, INSTANCE_TYPE, vpc_config_override=vpc_config_b)
  expect_equal(sms$create_model(..return_value = T)[["vpc_config"]], vpc_config_b)

  e$deploy(INSTANCE_COUNT, INSTANCE_TYPE, vpc_config_override=NULL)
  expect_null(sms$create_model(..return_value = T)[["vpc_config"]])
})

test_that("test_generic_deploy_accelerator_type", {
  sms = sagemaker_session()
  e = Estimator$new(
    IMAGE_URI, ROLE, INSTANCE_COUNT, INSTANCE_TYPE, sagemaker_session=sms
  )
  e$fit(list("train"="s3://bucket/training-prefix"))
  e$deploy(INSTANCE_COUNT, INSTANCE_TYPE, accelerator_type=ACCELERATOR_TYPE)

  args = e$sagemaker_session$endpoint_from_production_variants(..return_value = T)
  expect_true(startsWith(args[["name"]], IMAGE_URI))
  expect_equal(args[["production_variants"]][[1]][["AcceleratorType"]], ACCELERATOR_TYPE)
  expect_equal(args[["production_variants"]][[1]][["InitialInstanceCount"]], INSTANCE_COUNT)
  expect_equal(args[["production_variants"]][[1]][["InstanceType"]], INSTANCE_TYPE)
})

test_that("test_deploy_with_model_name", {
  sms = sagemaker_session()
  estimator = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms
  )

  do.call(estimator$set_hyperparameters, HYPERPARAMS)
  estimator$fit(list("train"="s3://bucket/training-prefix"))
  model_name = "model-name"
  estimator$deploy(INSTANCE_COUNT, INSTANCE_TYPE, model_name=model_name)

  args = sms$create_model(..return_value = T)
  expect_equal(args[[1]], model_name)
})

test_that("test_deploy_with_no_model_name", {
  sms = sagemaker_session()
  estimator = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms
  )

  do.call(estimator$set_hyperparameters, HYPERPARAMS)
  estimator$fit(list("train"="s3://bucket/training-prefix"))
  estimator$deploy(INSTANCE_COUNT, INSTANCE_TYPE)

  args = sms$create_model(..return_value = T)
  expect_true(startsWith(args[[1]], IMAGE_URI))
})

test_that("test_register_default_image", {
  sms = sagemaker_session()
  estimator = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms
  )
  do.call(estimator$set_hyperparameters, HYPERPARAMS)
  estimator$fit(list("train"="s3://bucket/training-prefix"))

  model_package_name = "test-estimator-register-model"
  content_types = "application/json"
  response_types = "application/json"
  inference_instances = "ml.m4.xlarge"
  transform_instances = "ml.m4.xlarget"

  estimator$register(
    content_types=content_types,
    response_types=response_types,
    inference_instances=inference_instances,
    transform_instances=transform_instances,
    model_package_name=model_package_name
  )

  expected_create_model_package_request = list(
    "containers"=list(
      list(
        "Image"=estimator$image_uri,
        "ModelDataUrl"=estimator$model_data
      )
    ),
    "content_types"=content_types,
    "response_types"=response_types,
    "inference_instances"=inference_instances,
    "transform_instances"=transform_instances,
    "marketplace_cert"=FALSE,
    "model_package_name"=model_package_name
  )
  expect_equal(sms$create_model_package_from_containers(..return_value = T), expected_create_model_package_request)
})

test_that("test_register_inference_image", {
  sms = sagemaker_session()
  estimator = Estimator$new(
    IMAGE_URI,
    ROLE,
    INSTANCE_COUNT,
    INSTANCE_TYPE,
    output_path=OUTPUT_PATH,
    sagemaker_session=sms
  )
  do.call(estimator$set_hyperparameters, HYPERPARAMS)
  estimator$fit(list("train"="s3://bucket/training-prefix"))

  model_package_name = "test-estimator-register-model"
  content_types = "application/json"
  response_types = "application/json"
  inference_instances = "ml.m4.xlarge"
  transform_instances = "ml.m4.xlarget"
  inference_image = "fake-inference-image"

  estimator$register(
    content_types=content_types,
    response_types=response_types,
    inference_instances=inference_instances,
    transform_instances=transform_instances,
    model_package_name=model_package_name,
    image_uri=inference_image
  )

  expected_create_model_package_request = list(
    "containers"=list(
      list(
        "Image"=inference_image,
        "ModelDataUrl"=estimator$model_data
      )
    ),
    "content_types"=content_types,
    "response_types"=response_types,
    "inference_instances"=inference_instances,
    "transform_instances"=transform_instances,
    "marketplace_cert"=FALSE,
    "model_package_name"=model_package_name
  )
  expect_equal(sms$create_model_package_from_containers(..return_value = T), expected_create_model_package_request)
})

test_that("test_prepare_init_params_from_job_description_with_image_training_job", {
  init_params = EstimatorBase$private_methods$.prepare_init_params_from_job_description(
    job_details=RETURNED_JOB_DESCRIPTION
  )
  expect_equal(init_params[["role"]], "arn:aws:iam::366:role/SageMakerRole")
  expect_equal(init_params[["instance_count"]], 1)
  expect_equal(init_params[["image_uri"]], "1.dkr.ecr.us-west-2.amazonaws.com/sagemaker-other:1.0.4")
})

test_that("test_prepare_init_params_from_job_description_with_algorithm_training_job", {
  algorithm_job_description = RETURNED_JOB_DESCRIPTION
  algorithm_job_description[["AlgorithmSpecification"]] = list(
    "TrainingInputMode"="File",
    "AlgorithmName"="arn:aws:sagemaker:us-east-2:1234:algorithm/scikit-decision-trees",
    "TrainingImage"=""
  )
  init_params = EstimatorBase$private_methods$.prepare_init_params_from_job_description(
    job_details=algorithm_job_description
  )
  expect_equal(init_params[["role"]], "arn:aws:iam::366:role/SageMakerRole")
  expect_equal(init_params[["instance_count"]], 1)
  expect_equal(init_params[["algorithm_arn"]], "arn:aws:sagemaker:us-east-2:1234:algorithm/scikit-decision-trees")
})

test_that("test_prepare_init_params_from_job_description_with_spot_training", {
  job_description = RETURNED_JOB_DESCRIPTION
  job_description[["EnableManagedSpotTraining"]] = TRUE
  job_description[["StoppingCondition"]] = list(
    "MaxRuntimeInSeconds"=86400,
    "MaxWaitTimeInSeconds"=87000
  )
  init_params = EstimatorBase$private_methods$.prepare_init_params_from_job_description(
    job_details=job_description
  )
  expect_equal(init_params[["role"]], "arn:aws:iam::366:role/SageMakerRole")
  expect_equal(init_params[["instance_count"]], 1)
  expect_true(init_params[["use_spot_instances"]])
  expect_equal(init_params[["max_run"]], 86400)
  expect_equal(init_params[["max_wait"]], 87000)
})

test_that("test_prepare_init_params_from_job_description_with_retry_strategy", {
  job_description = RETURNED_JOB_DESCRIPTION
  job_description[["RetryStrategy"]] = list("MaximumRetryAttempts"=2)
  job_description[["StoppingCondition"]] = list(
    "MaxRuntimeInSeconds"=86400,
    "MaxWaitTimeInSeconds"=87000
  )
  init_params = EstimatorBase$private_methods$.prepare_init_params_from_job_description(
    job_details=job_description
  )
  expect_equal(init_params[["role"]], "arn:aws:iam::366:role/SageMakerRole")
  expect_equal(init_params[["instance_count"]], 1)
  expect_equal(init_params[["max_run"]], 86400)
  expect_equal(init_params[["max_wait"]], 87000)
  expect_equal(init_params[["max_retry_attempts"]], 2)
})

test_that("test_prepare_init_params_from_job_description_with_retry_strategy", {
  invalid_job_description = RETURNED_JOB_DESCRIPTION
  invalid_job_description[["AlgorithmSpecification"]] = list("TrainingInputMode"="File")

  expect_error(
    EstimatorBase$private_methods$.prepare_init_params_from_job_description(
      job_details=invalid_job_description
    ),
    "Invalid AlgorithmSpecification",
    class = "RuntimeError"
  )
})

test_that("test_prepare_for_training_with_base_name", {
  sms = sagemaker_session()
  estimator = Estimator$new(
    image_uri="some-image",
    role="some_image",
    instance_count=1,
    instance_type="ml.m4.xlarge",
    sagemaker_session=sms,
    base_job_name="base_job_name"
  )
  estimator$.prepare_for_training()
  expect_true(grepl("base_job_name",estimator$.current_job_name))
})

test_that("test_prepare_for_training_with_name_based_on_image", {
  sms = sagemaker_session()
  estimator = Estimator$new(
    image_uri="some-image",
    role="some_image",
    instance_count=1,
    instance_type="ml.m4.xlarge",
    sagemaker_session=sms
  )
  estimator$.prepare_for_training()
  expect_true(grepl("some-image",estimator$.current_job_name))
})

test_that("test_estimator_local_mode_error", {
  # When using instance local with a session which is not LocalSession we should error out
  sms = sagemaker_session()
  expect_error(
    Estimator$new(
      image_uri="some-image",
      role="some_image",
      instance_count=1,
      instance_type="local",
      sagemaker_session=sms,
      base_job_name="base_job_name"
    ),
    class = "RuntimeError"
  )
})

test_that("test_estimator_local_mode_error", {
  # When using instance local with a session which is not LocalSession we should error out
  expect_true(inherits(
    Estimator$new(
      image_uri="some-image",
      role="some_image",
      instance_count=1,
      instance_type="local",
      sagemaker_session=sagemaker_local_session(),
      base_job_name="base_job_name"),
    "Estimator"
  ))
})

test_that("test_framework_distribution_configuration", {
  sms = sagemaker_session()
  framework = DummyFramework$new(
    entry_point="script",
    role=ROLE,
    sagemaker_session=sms,
    instance_count=INSTANCE_COUNT,
    instance_type=INSTANCE_TYPE
  )
  actual_ps = framework$.__enclos_env__$private$.distribution_configuration(
    distribution=DISTRIBUTION_PS_ENABLED
  )
  expected_ps = list("sagemaker_parameter_server_enabled"=TRUE)

  actual_mpi = framework$.__enclos_env__$private$.distribution_configuration(
    distribution=DISTRIBUTION_MPI_ENABLED
  )
  expected_mpi = list(
    "sagemaker_mpi_enabled"=TRUE,
    "sagemaker_mpi_num_of_processes_per_host"=2,
    "sagemaker_mpi_custom_mpi_options"="options"
  )
  expect_equal(actual_mpi, expected_mpi)

  actual_ddp = framework$.__enclos_env__$private$.distribution_configuration(
    distribution=DISTRIBUTION_SM_DDP_ENABLED
  )
  expected_ddp = list(
    "sagemaker_distributed_dataparallel_enabled"=TRUE,
    "sagemaker_instance_type"=INSTANCE_TYPE,
    "sagemaker_distributed_dataparallel_custom_mpi_options"="options"
  )
  expect_equal(actual_ddp, expected_ddp)
})

test_that("test_image_name_map", {
  sms = sagemaker_session()
  expect_warning({
    e = DummyFramework$new(
      "my_script.py",
      image_name=IMAGE_URI,
      role=ROLE,
      sagemaker_session=sms,
      instance_count=INSTANCE_COUNT,
      instance_type=INSTANCE_TYPE
    )
  })
  expect_equal(e$image_uri, IMAGE_URI)
})
