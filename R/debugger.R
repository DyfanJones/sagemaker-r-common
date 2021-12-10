# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/src/sagemaker/debugger.py

#' @include r_utils.R
#' @include utils.R

#' @import R6
#' @import R6sagemaker.debugger

DEBUGGER_FLAG = "USE_SMDEBUG"

# Return the Debugger rule image URI for the given AWS Region.
# For a full list of rule image URIs,
# see `Use Debugger Docker Images for Built-in or Custom Rules
# <https://docs.aws.amazon.com/sagemaker/latest/dg/debugger-docker-images-rules.html>`_.
# Args:
#   region (str): A string of AWS Region. For example, ``'us-east-1'``.
# Returns:
#   str: Formatted image URI for the given AWS Region and the rule container type.
get_rule_container_image_uri <- function(region){
  return(ImageUris$new()$retrieve("debugger", region))
}

# Return the default built-in profiler rule with a unique name.
# Returns:
#   sagemaker.debugger.ProfilerRule: The instance of the built-in ProfilerRule.
get_default_profiler_rule <- function(){
  default_rule = R6sagemaker.debugger::ProfilerReport$new()
  custom_name = sprintf("%s-%s", default_rule$rule_name, as.integer(Sys.time()))
  return(ProfilerRule$new()$sagemaker(default_rule, name=custom_name))
}

#' @title The SageMaker Debugger rule base class that cannot be instantiated directly.
#' @description Debugger rule classes inheriting this RuleBase class are
#'              :class:`~sagemaker.debugger.Rule` and :class:`~sagemaker.debugger.ProfilerRule`.
#'              Do not directly use the rule base class to instantiate a SageMaker Debugger rule.
#'              Use the :class:`~sagemaker.debugger.Rule` classmethods for debugging
#'              and the :class:`~sagemaker.debugger.ProfilerRule` classmethods for profiling.
#' @export
RuleBase = R6Class("RuleBase",
  public = list(

    #' @field name
    #' (str): The name of the rule.
    name = NULL,

    #' @field image_uri
    #' (str): The image URI to use the rule.
    image_uri = NULL,

    #' @field instance_type
    #' (str): Type of EC2 instance to use. For example, 'ml.c4.xlarge'.
    instance_type = NULL,

    #' @field container_local_output_path
    #' (str): The local path to store the Rule output.
    container_local_output_path = NULL,

    #' @field s3_output_path
    #' (str): The location in S3 to store the output.
    s3_output_path = NULL,

    #' @field volume_size_in_gb
    #' (int): Size in GB of the EBS volume to use for storing data.
    volume_size_in_gb = NULL,

    #' @field rule_parameters
    #' (dict): A dictionary of parameters for the rule.
    rule_parameters = NULL,

    #' @description Initialize RuleBase class
    #' @param name (str): The name of the rule.
    #' @param image_uri (str): The image URI to use the rule.
    #' @param instance_type (str): Type of EC2 instance to use. For example, 'ml.c4.xlarge'.
    #' @param container_local_output_path (str): The local path to store the Rule output.
    #' @param s3_output_path (str): The location in S3 to store the output.
    #' @param volume_size_in_gb (int): Size in GB of the EBS volume to use for storing data.
    #' @param rule_parameters (dict): A dictionary of parameters for the rule.
    initialize = function(name=NULL,
                          image_uri=NULL,
                          instance_type=NULL,
                          container_local_output_path=NULL,
                          s3_output_path=NULL,
                          volume_size_in_gb=NULL,
                          rule_parameters=NULL){
      stopifnot(is.null(name) || is.character(name),
                is.null(image_uri) || is.character(image_uri),
                is.null(instance_type) || is.character(instance_type),
                is.null(container_local_output_path) || is.character(container_local_output_path),
                is.null(s3_output_path) || is.character(s3_output_path),
                is.null(volume_size_in_gb) || is.integer(volume_size_in_gb),
                is.null(rule_parameters) || is.list(rule_parameters))

      self$name = name
      self$image_uri = image_uri
      self$instance_type = instance_type
      self$container_local_output_path = container_local_output_path
      self$s3_output_path = s3_output_path
      self$volume_size_in_gb = volume_size_in_gb
      self$rule_parameters = rule_parameters
    },

    #' @description format class
    format = function(){
      return(format_class(self))
    }
  ),
  private = list(
    # @description Create a dictionary of rule parameters.
    # @param source (str): Optional. A source file containing a rule to invoke. If provided,
    #              you must also provide rule_to_invoke. This can either be an S3 uri or
    #              a local path.
    # @param rule_to_invoke (str): Optional. The name of the rule to invoke within the source.
    #              If provided, you must also provide source.
    # @param rule_parameters (dict): Optional. A dictionary of parameters for the rule.
    # @return dict: A dictionary of rule parameters.
    .set_rule_parameters = function(source=NULL,
                                    rule_to_invoke=NULL,
                                    rule_parameters=NULL){
      if (!is.null(source) && !is.null(rule_to_invoke))
        stop("If you provide a source, you must also provide a rule to invoke (and vice versa).",
             call. = F)

      merged_rule_params = list()
      merged_rule_params = c(merged_rule_params, build_dict("source_s3_uri", source))
      merged_rule_params = c(merged_rule_params , build_dict("rule_to_invoke", rule_to_invoke))
      merged_rule_params = c(merged_rule_params, rule_parameters %||% list())

      return(merged_rule_params)
    }
  ),
  lock_objects = F
)

.get_rule_config <- function(rule_name){
  rule_config = NULL
  config_file_path = system.file("rule_config_jsons", "ruleConfigs.json", package= "R6sagemaker.common")
  if(file.exists(config_file_path)){
    configs = jsonlite::read_json(config_file_path)
    rule_config = configs[[rule_name]]
  }
  return(rule_config)
}

#' @title Debug Rule Class
#' @description The SageMaker Debugger Rule class configures *debugging* rules to debug your training job.
#'              The debugging rules analyze tensor outputs from your training job
#'              and monitor conditions that are critical for the success of the training
#'              job.
#'              SageMaker Debugger comes pre-packaged with built-in *debugging* rules.
#'              For example, the debugging rules can detect whether gradients are getting too large or
#'              too small, or if a model is overfitting.
#'              For a full list of built-in rules for debugging, see
#'              `List of Debugger Built-in Rules
#'              <https://docs.aws.amazon.com/sagemaker/latest/dg/debugger-built-in-rules.html>`_.
#'              You can also write your own rules using the custom rule classmethod.
#' @export
Rule = R6Class("Rule",
  inherit = RuleBase,
  public = list(

    #' @field collection_configs
    #' A list of :class:`~sagemaker.debugger.CollectionConfig
    collection_configs = NULL,

    #' @field actions
    #' Placeholder
    actions = NULL,

    #' @description Configure the debugging rules using the following classmethods.
    #' @param name (str): The name of the rule.
    #' @param image_uri (str): The image URI to use the rule.
    #' @param instance_type (str): Type of EC2 instance to use. For example, 'ml.c4.xlarge'.
    #' @param container_local_output_path (str): The local path to store the Rule output.
    #' @param s3_output_path (str): The location in S3 to store the output.
    #' @param volume_size_in_gb (int): Size in GB of the EBS volume to use for storing data.
    #' @param rule_parameters (dict): A dictionary of parameters for the rule.
    #' @param collections_to_save ([sagemaker.debugger.CollectionConfig]): Optional. A list
    #'              of :class:`~sagemaker.debugger.CollectionConfig` objects to be saved.
    #' @param actions :
    initialize = function(name=NULL,
                          image_uri=NULL,
                          instance_type=NULL,
                          container_local_output_path=NULL,
                          s3_output_path=NULL,
                          volume_size_in_gb=NULL,
                          rule_parameters=NULL,
                          collections_to_save=NULL,
                          actions=NULL){
      super$initialize(
        name,
        image_uri,
        instance_type,
        container_local_output_path,
        s3_output_path,
        volume_size_in_gb,
        rule_parameters)
      self$collection_configs = collections_to_save
      self$actions = actions
    },

    #' @description Initialize a ``Rule`` object for a \code{built-in} debugging rule.
    #' @param base_config (dict): Required. This is the base rule config dictionary returned from the
    #'              :class:`~sagemaker.debugger.rule_configs` method.
    #'              For example, ``rule_configs.dead_relu()``.
    #'              For a full list of built-in rules for debugging, see
    #'              `List of Debugger Built-in Rules
    #'              <https://docs.aws.amazon.com/sagemaker/latest/dg/debugger-built-in-rules.html>`_.
    #' @param name (str): Optional. The name of the debugger rule. If one is not provided,
    #'              the name of the base_config will be used.
    #' @param container_local_output_path (str): Optional. The local path in the rule processing
    #'              container.
    #' @param s3_output_path (str): Optional. The location in Amazon S3 to store the output tensors.
    #'              The default Debugger output path for debugging data is created under the
    #'              default output path of the :class:`~sagemaker.estimator.Estimator` class.
    #'              For example,
    #'              s3://sagemaker-<region>-<12digit_account_id>/<training-job-name>/debug-output/.
    #' @param other_trials_s3_input_paths ([str]): Optional. The Amazon S3 input paths
    #'              of other trials to use the SimilarAcrossRuns rule.
    #' @param rule_parameters (dict): Optional. A dictionary of parameters for the rule.
    #' @param collections_to_save (:class:`~sagemaker.debugger.CollectionConfig`):
    #'              Optional. A list
    #'              of :class:`~sagemaker.debugger.CollectionConfig` objects to be saved.
    #' @param actions :
    #' @return :class:`~sagemaker.debugger.Rule`: An instance of the built-in rule.
    sagemaker = function(base_config,
                         name=NULL,
                         container_local_output_path=NULL,
                         s3_output_path=NULL,
                         other_trials_s3_input_paths=NULL,
                         rule_parameters=NULL,
                         collections_to_save=NULL,
                         actions=NULL){
      merged_rule_params = list()

      if (!is.null(rule_parameters) && !islistempty(rule_parameters$rule_to_invoke))
        stop("You cannot provide a 'rule_to_invoke' for SageMaker rules.",
             "Either remove the rule_to_invoke or use a custom rule.",
             call. = F)

      if (!is.null(actions) && (inherits(actions, "Action") || inherits(actions, "ActionList")))
        stop("`actions` must be of type `Action` or `ActionList`!", call. = F)

      if (!is.null(other_trials_s3_input_paths)){
        s3_in_split = split_str(other_trials_s3_input_paths, "")
        for (index in seq_along(s3_in_split)){
          merged_rule_params[[sprintf("other_trial_%s",index)]] = s3_in_split[index]
        }
      }

      default_rule_params = base_config[["DebugRuleConfiguration"]][["RuleParameters"]] %||% list()
      merged_rule_params = c(merged_rule_params, default_rule_params)
      merged_rule_params = c(merged_rule_params, rule_parameters %||% list())

      base_config_collections = list()
      for (config in (base_config[["CollectionConfigurations"]] %||% list())){
        collection_name = NULL
        collection_parameters = list()
        for (i in seq_along(config)){
          key = names(config)[i]
          value = config[[i]]
          if (key == "CollectionName")
            collection_name = value
          if (key == "CollectionParameters")
            collection_parameters = value
        }
        base_config_collections = c(
          base_config_collections, CollectionConfig$new(name=collection_name, parameters=collection_parameters))
      }

      self$initialize(
        name=name %||% base_config[["DebugRuleConfiguration"]][["RuleConfigurationName"]],
        image_uri="DEFAULT_RULE_EVALUATOR_IMAGE",
        instance_type=NULL,
        container_local_output_path=container_local_output_path,
        s3_output_path=s3_output_path,
        volume_size_in_gb=NULL,
        rule_parameters=merged_rule_params,
        collections_to_save=collections_to_save %||% base_config_collections,
        actions=actions
      )
      return(self)
    },

    #' @description Initialize a ``Rule`` object for a *custom* debugging rule.
    #'              You can create a custom rule that analyzes tensors emitted
    #'              during the training of a model
    #'              and monitors conditions that are critical for the success of a training
    #'              job. For more information, see `Create Debugger Custom Rules for Training Job
    #'              Analysis
    #'              <https://docs.aws.amazon.com/sagemaker/latest/dg/debugger-custom-rules.html>`_.
    #' @param name (str): Required. The name of the debugger rule.
    #' @param image_uri (str): Required. The URI of the image to be used by the debugger rule.
    #' @param instance_type (str): Required. Type of EC2 instance to use, for example,
    #'              'ml.c4.xlarge'.
    #' @param volume_size_in_gb (int): Required. Size in GB of the EBS volume
    #'              to use for storing data.
    #' @param source (str): Optional. A source file containing a rule to invoke. If provided,
    #'              you must also provide rule_to_invoke. This can either be an S3 uri or
    #'              a local path.
    #' @param rule_to_invoke (str): Optional. The name of the rule to invoke within the source.
    #'              If provided, you must also provide source.
    #' @param container_local_output_path (str): Optional. The local path in the container.
    #' @param s3_output_path (str): Optional. The location in Amazon S3 to store the output tensors.
    #'              The default Debugger output path for debugging data is created under the
    #'              default output path of the :class:`~sagemaker.estimator.Estimator` class.
    #'              For example,
    #'              s3://sagemaker-<region>-<12digit_account_id>/<training-job-name>/debug-output/.
    #' @param other_trials_s3_input_paths ([str]): Optional. The Amazon S3 input paths
    #'              of other trials to use the SimilarAcrossRuns rule.
    #' @param rule_parameters (dict): Optional. A dictionary of parameters for the rule.
    #' @param collections_to_save ([sagemaker.debugger.CollectionConfig]): Optional. A list
    #'              of :class:`~sagemaker.debugger.CollectionConfig` objects to be saved.
    #' @param actions :
    #' @return :class:`~sagemaker.debugger.Rule`: The instance of the custom rule.
    custom = function(name,
                      image_uri,
                      instance_type,
                      volume_size_in_gb,
                      source=NULL,
                      rule_to_invoke=NULL,
                      container_local_output_path=NULL,
                      s3_output_path=NULL,
                      other_trials_s3_input_paths=NULL,
                      rule_parameters=NULL,
                      collections_to_save=NULL,
                      actions=NULL){
      if(!is.null(actions) && !(inherits(actions, "Action") || inherits(actions, "ActionList")))
        stop("`actions` must be of type `Action` or `ActionList`!", call. = F)

      merged_rule_params = private$.set_rule_parameters(
        source, rule_to_invoke, other_trials_s3_input_paths, rule_parameters)

      self$initialize(
        name=name,
        image_uri=image_uri,
        instance_type=instance_type,
        container_local_output_path=container_local_output_path,
        s3_output_path=s3_output_path,
        volume_size_in_gb=volume_size_in_gb,
        rule_parameters=merged_rule_params,
        collections_to_save=collections_to_save %||% list(),
        actions=actions)
      return(self)
    },

    #' @description Prepare actions for Debugger Rule.
    #' @param training_job_name (str): The training job name. To be set as the default training job
    #'              prefix for the StopTraining action if it is specified.
    prepare_actions = function(training_job_name){
      if (is.null(self$actions)){
        # user cannot manually specify action_json in rule_parameters for actions.
        self$rule_parameters$action_json <- NULL
        return(NULL)}

      self$actions$update_training_job_prefix_if_not_specified(training_job_name)
      action_params = list("action_json"= self$actions$serialize())
      self$rule_parameters = modifyList(self$rule_parameters, action_params)
    },

    #' @description Generates a request dictionary using the parameters provided when initializing object.
    #' @return dict: An portion of an API request as a dictionary.
    to_debugger_rule_config_dict = function(){
      debugger_rule_config_request = list(
        "RuleConfigurationName"= self$name,
        "RuleEvaluatorImage"= self$image_uri)

      debugger_rule_config_request = c(debugger_rule_config_request, build_dict("InstanceType", self$instance_type))
      debugger_rule_config_request = c(debugger_rule_config_request, build_dict("VolumeSizeInGB", self$volume_size_in_gb))
      debugger_rule_config_request = c(debugger_rule_config_request,
        build_dict("LocalPath", self$container_local_output_path))
      debugger_rule_config_request = c(debugger_rule_config_request, build_dict("S3OutputPath", self$s3_output_path))
      debugger_rule_config_request = c(debugger_rule_config_request, build_dict("RuleParameters", self$rule_parameters))

      return(debugger_rule_config_request)
    }
  ),
  private = list(

    # Set rule parameters for Debugger Rule.
    # Args:
    #   source (str): Optional. A source file containing a rule to invoke. If provided,
    # you must also provide rule_to_invoke. This can either be an S3 uri or
    # a local path.
    # rule_to_invoke (str): Optional. The name of the rule to invoke within the source.
    # If provided, you must also provide source.
    # other_trials_s3_input_paths ([str]): Optional. S3 input paths for other trials.
    # rule_parameters (dict): Optional. A dictionary of parameters for the rule.
    # Returns:
    #   dict: A dictionary of rule parameters.
    .set_rule_parameters = function(source,
                                    rule_to_invoke,
                                    other_trials_s3_input_paths,
                                    rule_parameters){
      merged_rule_params = list()
      if (!is.null(other_trials_s3_input_paths)){
        s3_in_split = split_str(other_trials_s3_input_paths, "")
        for (index in seq_along(s3_in_split)){
          merged_rule_params[[sprintf("other_trial_%s",index)]] = s3_in_split[index]
        }
      }
      merged_rule_params = c(
        merged_rule_params,
        super$.set_rule_parameters(source, rule_to_invoke, rule_parameters))
      return(merged_rule_params)
    }
  )
)

#' @title The SageMaker Debugger ProfilerRule class configures *profiling* rules.
#' @description SageMaker Debugger profiling rules automatically analyze
#'              hardware system resource utilization and framework metrics of a
#'              training job to identify performance bottlenecks.
#'              SageMaker Debugger comes pre-packaged with built-in *profiling* rules.
#'              For example, the profiling rules can detect if GPUs are underutilized due to CPU bottlenecks or
#'              IO bottlenecks.
#'              For a full list of built-in rules for debugging, see
#'              `List of Debugger Built-in Rules <https://docs.aws.amazon.com/sagemaker/latest/dg/debugger-built-in-rules.html>`_.
#'              You can also write your own profiling rules using the Amazon SageMaker
#'              Debugger APIs.
#' @export
ProfilerRule = R6Class("ProfilerRule",
  inherit = RuleBase,
  public = list(

    #' @description Initialize a ``ProfilerRule`` object for a *built-in* profiling rule.
    #'              The rule analyzes system and framework metrics of a given
    #'              training job to identify performance bottlenecks.
    #' @param base_config (rule_configs.ProfilerReport): The base rule configuration object
    #'              returned from the ``rule_configs`` method.
    #'              For example, 'rule_configs.ProfilerReport()'.
    #'              For a full list of built-in rules for debugging, see
    #'              `List of Debugger Built-in Rules
    #'              <https://docs.aws.amazon.com/sagemaker/latest/dg/debugger-built-in-rules.html>`_.
    #' @param name (str): The name of the profiler rule. If one is not provided,
    #'              the name of the base_config will be used.
    #' @param container_local_output_path (str): The path in the container.
    #' @param s3_output_path (str): The location in Amazon S3 to store the profiling output data.
    #'              The default Debugger output path for profiling data is created under the
    #'              default output path of the :class:`~sagemaker.estimator.Estimator` class.
    #'              For example,
    #'              s3://sagemaker-<region>-<12digit_account_id>/<training-job-name>/profiler-output/.
    #' @return :class:`~sagemaker.debugger.ProfilerRule`:
    #'              The instance of the built-in ProfilerRule.
    sagemaker = function(base_config,
                         name=NULL,
                         container_local_output_path=NULL,
                         s3_output_path=NULL){
      self$initialize(
        name = name %||% base_config$rule_name,
        image_uri = "DEFAULT_RULE_EVALUATOR_IMAGE",
        instance_type = NULL,
        container_local_output_path = container_local_output_path,
        s3_output_path = s3_output_path,
        volume_size_in_gb = NULL,
        rule_parameters = base_config$rule_parameters
      )
      return(self)
    },

    #' @description Initialize a ``ProfilerRule`` object for a *custom* profiling rule.
    #'              You can create a rule that
    #'              analyzes system and framework metrics emitted during the training of a model and
    #'              monitors conditions that are critical for the success of a
    #'              training job.
    #' @param name (str): The name of the profiler rule.
    #' @param image_uri (str): The URI of the image to be used by the proflier rule.
    #' @param instance_type (str): Type of EC2 instance to use, for example,
    #'              'ml.c4.xlarge'.
    #' @param volume_size_in_gb (int): Size in GB of the EBS volume
    #'              to use for storing data.
    #' @param source (str): A source file containing a rule to invoke. If provided,
    #'              you must also provide rule_to_invoke. This can either be an S3 uri or
    #'              a local path.
    #' @param rule_to_invoke (str): The name of the rule to invoke within the source.
    #'              If provided, you must also provide the source.
    #' @param container_local_output_path (str): The path in the container.
    #' @param s3_output_path (str): The location in Amazon S3 to store the output.
    #'              The default Debugger output path for profiling data is created under the
    #'              default output path of the :class:`~sagemaker.estimator.Estimator` class.
    #'              For example,
    #'              s3://sagemaker-<region>-<12digit_account_id>/<training-job-name>/profiler-output/.
    #' @param rule_parameters (dict): A dictionary of parameters for the rule.
    #' @return :class:`~sagemaker.debugger.ProfilerRule`:
    #'              The instance of the custom ProfilerRule.
    custom = function(name,
                      image_uri,
                      instance_type,
                      volume_size_in_gb,
                      source=NULL,
                      rule_to_invoke=NULL,
                      container_local_output_path=NULL,
                      s3_output_path=NULL,
                      rule_parameters=NULL){
      merged_rule_params = super$.set_rule_parameters(source, rule_to_invoke, rule_parameters)

      self$initialize(
        name = name,
        image_uri = image_uri,
        instance_type = instance_type,
        container_local_output_path = container_local_output_path,
        s3_output_path = s3_output_path,
        volume_size_in_gb = volume_size_in_gb,
        rule_parameters = merged_rule_params
      )
      return(self)
    },

    #' @description Generates a request dictionary using the parameters provided when initializing object.
    #' @return dict: An portion of an API request as a dictionary.
    to_profiler_rule_config_dict = function(){
      profiler_rule_config_request = list(
        "RuleConfigurationName"= self$name,
        "RuleEvaluatorImage"= self$image_uri)
      profiler_rule_config_request = c(profiler_rule_config_request, build_dict("InstanceType", self$instance_type))
      profiler_rule_config_request = c(profiler_rule_config_request, build_dict("VolumeSizeInGB", self$volume_size_in_gb))
      profiler_rule_config_request = c(profiler_rule_config_request,
        build_dict("LocalPath", self$container_local_output_path))
      profiler_rule_config_request = c(profiler_rule_config_request, build_dict("S3OutputPath", self$s3_output_path))

      if (!islistempty(self$rule_parameters)){
        profiler_rule_config_request[["RuleParameters"]] = self$rule_parameters
        for (i in seq_along(profiler_rule_config_request[["RuleParameters"]])){
          k = names(profiler_rule_config_request[["RuleParameters"]])[i]
          v = profiler_rule_config_request[["RuleParameters"]][[i]]
          profiler_rule_config_request[["RuleParameters"]][[k]] = as.character(v)
        }
      }
      return(profiler_rule_config_request)
    }
  ),
  lock_objects = F
)

#' @title Create a Debugger hook configuration object to save the tensor for debugging.
#' @description DebuggerHookConfig provides options to customize how debugging
#'              information is emitted and saved. This high-level DebuggerHookConfig class
#'              runs based on the `smdebug.SaveConfig
#'              <https://github.com/awslabs/sagemaker-debugger/blob/master/docs/api.md#saveconfig>`
#'              class.
#' @export
DebuggerHookConfig = R6Class("DebuggerHookConfig",
  public = list(
    #' @field s3_output_path
    #' The location in Amazon S3 to store the output tensors
    s3_output_path = NULL,

    #' @field container_local_output_path
    #' The local path in the container
    container_local_output_path = NULL,

    #' @field hook_parameters
    #' A dictionary of parameters
    hook_parameters = NULL,

    #' @field collection_configs
    #' A list of :class:`~sagemaker.debugger.CollectionConfig
    collection_configs = NULL,

    #' @description Initialize the DebuggerHookConfig instance.
    #' @param s3_output_path (str): Optional. The location in Amazon S3 to store the output tensors.
    #'              The default Debugger output path is created under the
    #'              default output path of the :class:`~sagemaker.estimator.Estimator` class.
    #'              For example,
    #'              s3://sagemaker-<region>-<12digit_account_id>/<training-job-name>/debug-output/.
    #' @param container_local_output_path (str): Optional. The local path in the container.
    #' @param hook_parameters (dict): Optional. A dictionary of parameters.
    #' @param collection_configs ([sagemaker.debugger.CollectionConfig]): Required. A list
    #'              of :class:`~sagemaker.debugger.CollectionConfig` objects to be saved
    #'              at the \code{s3_output_path}.
    initialize = function(s3_output_path = NULL,
                          container_local_output_path = NULL,
                          hook_parameters = NULL,
                          collection_configs = NULL){

      self$s3_output_path = s3_output_path
      self$container_local_output_path = container_local_output_path
      self$hook_parameters = hook_parameters
      self$collection_configs = collection_configs
      },

    #' @description Generate a request dictionary using the parameters when initializing the object.
    #' @return dict: An portion of an API request as a dictionary.
    to_request_list = function(){
      debugger_hook_config_request = list("S3OutputPath"= self$s3_output_path)
      debugger_hook_config_request[["LocalPath"]] = self$container_local_output_path
      debugger_hook_config_request[["HookParameters"]] = self$hook_parameters



      if(!is.null(self$collection_configs))
        debugger_hook_config_request[[
          "CollectionConfigurations"
        ]] = lapply(self$collection_configs, function(collection_config)
          collection_config$to_request_list()
        )
      return(debugger_hook_config_request)
    },

    #' @description format class
    format = function(){
      return(format_class(self))
    }
  )
)

#' @title TensorBoardOutputConfig Class
#' @description Create a tensor ouput configuration object for debugging visualizations on TensorBoard
#' @export
TensorBoardOutputConfig = R6Class("TensorBoardOutputConfig",
  public = list(

    #' @field s3_output_path
    #' The location in Amazon S3 to store the output.
    s3_output_path = NULL,

    #' @field container_local_output_path
    #' The local path in the container.
    container_local_output_path = NULL,

    #' @description Initialize the TensorBoardOutputConfig instance.
    #' @param s3_output_path (str): Optional. The location in Amazon S3 to store the output.
    #' @param container_local_output_path (str): Optional. The local path in the container.
    initialize = function(s3_output_path,
                          container_local_output_path=NULL){
      self$s3_output_path = s3_output_path
      self$container_local_output_path = container_local_output_path
    },

    #' @description Generate a request dictionary using the instances attributes.
    #' @return dict: An portion of an API request as a dictionary.
    to_request_list = function(){
      tensorboard_output_config_request = list("S3OutputPath"= self$s3_output_path)
      tensorboard_output_config_request$LocalPath = self$container_local_output_path
      return(tensorboard_output_config_request)
    },

    #' @description format class
    format = function(){
      return(format_class(self))
    }
  )
)

#' @title CollectionConfig Class
#' @description Creates tensor collections for SageMaker Debugger
#' @export
CollectionConfig = R6Class("CollectionConfig",
  public = list(

    #' @field name
    #' The name of the collection configuration.
    name = NULL,

    #' @field parameters
    #' The parameters for the collection configuration.
    parameters = NULL,

    #' @description Constructor for collection configuration.
    #' @param name (str): Required. The name of the collection configuration.
    #' @param parameters (dict): Optional. The parameters for the collection
    #'              configuration.
    initialize = function(name,
                          parameters=NULL){
      self$name = name
      self$parameters = parameters
    },

    #' @description Generate a request dictionary using the parameters initializing the object.
    #' @return dict: A portion of an API request as a dictionary.
    to_request_list = function(){
      collection_config_request = list("CollectionName"= self$name)
      collection_config_request[["CollectionParameters"]] = self$parameters
      return(collection_config_request)
    },

    #' @description format class
    format = function(){
      return(format_class(self))
    }
  )
)

# Equal method override.
# Args:
#   other: Object to test equality against.
#' @export
`==.CollectionConfig` <- function(self, other){
  if (!inherits(other, "CollectionConfig"))
    stop("CollectionConfig is only comparable with other CollectionConfig objects.",
         call. = F)

  eq_name = self$name == other$name

  # added an extra step for rebustness of check
  eq_parm = (
    if(is.null(self$parameters) || is.null(other$parameters))
      identical(self$parameters, other$self$parameters)
    else
      identical(
        self$parameters[order(names(self$parameters))],
        other$parameters[order(names(other$parameters))])
  )

  return(eq_name && eq_parm)
}

# Not-equal method override.
# Args:
#   other: Object to test equality against.
#' @export
`!=.CollectionConfig` <- function(self, other){
  if (!inherits(other, "CollectionConfig"))
    stop("CollectionConfig is only comparable with other CollectionConfig objects.",
         call. = F)
  no_eq_name = self$name != other$name

  # added an extra step for rebustness of check
  no_eq_parm = (
    if(is.null(self$parameters) || is.null(other$parameters))
      !identical(self$parameters, other$self$parameters)
    else
      !identical(
        self$parameters[order(names(self$parameters))],
        other$parameters[order(names(other$parameters))])
  )

  return(no_eq_name || no_eq_parm)
}

# NOTE: Not a 100% how to implement hash method in R6. Possibly not required in R.
#
# def __hash__(self):
#   """Hash method override."""
# return hash((self.name, tuple(sorted((self.parameters or {}).items()))))
