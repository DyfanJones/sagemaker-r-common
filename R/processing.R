# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/src/sagemaker/processing.py

#' @include r_utils.R
#' @include job.R
#' @include network.R
#' @include dataset_definition_inputs.R


#' @import R6
#' @import sagemaker.core
#' @importFrom fs file_exists is_file path
#' @importFrom urltools url_decode

#' @title Processor Class
#' @family Processor
#' @description Handles Amazon SageMaker Processing tasks.
#' @export
Processor = R6Class("Processor",
  public = list(
    #' @field role
    #' An AWS IAM role name or ARN
    role = NULL,

    #' @field image_uri
    #' The URI of the Docker image to use
    image_uri = NULL,

    #' @field instance_count
    #' The number of instances to run
    instance_count = NULL,

    #' @field instance_type
    #' The type of EC2 instance to use
    instance_type = NULL,

    #' @field entrypoint
    #' The entrypoint for the processing job
    entrypoint = NULL,

    #' @field volume_size_in_gb
    #' Size in GB of the EBS volume
    volume_size_in_gb = NULL,

    #' @field volume_kms_key
    #' A KMS key for the processing
    volume_kms_key = NULL,

    #' @field output_kms_key
    #' The KMS key ID for processing job outputs
    output_kms_key = NULL,

    #' @field max_runtime_in_seconds
    #' Timeout in seconds
    max_runtime_in_seconds = NULL,

    #' @field base_job_name
    #' Prefix for processing job name
    base_job_name = NULL,

    #' @field sagemaker_session
    #' Session object which manages interactions with Amazon SageMaker
    sagemaker_session = NULL,

    #' @field env
    #' Environment variables
    env = NULL,

    #' @field tags
    #' List of tags to be passed
    tags = NULL,

    #' @field network_config
    #' A :class:`~sagemaker.network.NetworkConfig`
    network_config = NULL,

    #' @field jobs
    #' Jobs ran /running
    jobs = NULL,

    #' @field latest_job
    #' Previously ran jobs
    latest_job = NULL,

    #' @field .current_job_name
    #' Current job
    .current_job_name = NULL,

    #' @field arguments
    #' extra agruments
    arguments = NULL,
    #' @description Initializes a ``Processor`` instance. The ``Processor`` handles Amazon
    #'              SageMaker Processing tasks.
    #' @param role (str): An AWS IAM role name or ARN. Amazon SageMaker Processing
    #'              uses this role to access AWS resources, such as
    #'              data stored in Amazon S3.
    #' @param image_uri (str): The URI of the Docker image to use for the
    #'              processing jobs.
    #' @param instance_count (int): The number of instances to run
    #'              a processing job with.
    #' @param instance_type (str): The type of EC2 instance to use for
    #'              processing, for example, 'ml.c4.xlarge'.
    #' @param entrypoint (list[str]): The entrypoint for the processing job (default: NULL).
    #'              This is in the form of a list of strings that make a command.
    #' @param volume_size_in_gb (int): Size in GB of the EBS volume
    #'              to use for storing data during processing (default: 30).
    #' @param volume_kms_key (str): A KMS key for the processing
    #'              volume (default: NULL).
    #' @param output_kms_key (str): The KMS key ID for processing job outputs (default: NULL).
    #' @param max_runtime_in_seconds (int): Timeout in seconds (default: NULL).
    #'              After this amount of time, Amazon SageMaker terminates the job,
    #'              regardless of its current status. If `max_runtime_in_seconds` is not
    #'              specified, the default value is 24 hours.
    #' @param base_job_name (str): Prefix for processing job name. If not specified,
    #'              the processor generates a default job name, based on the
    #'              processing image name and current timestamp.
    #' @param sagemaker_session (:class:`~sagemaker.session.Session`):
    #'              Session object which manages interactions with Amazon SageMaker and
    #'              any other AWS services needed. If not specified, the processor creates
    #'              one using the default AWS configuration chain.
    #' @param env (dict[str, str]): Environment variables to be passed to
    #'              the processing jobs (default: NULL).
    #' @param tags (list[dict]): List of tags to be passed to the processing job
    #'              (default: NULL). For more, see
    #'              https://docs.aws.amazon.com/sagemaker/latest/dg/API_Tag.html.
    #' @param network_config (:class:`~sagemaker.network.NetworkConfig`):
    #'              A :class:`~sagemaker.network.NetworkConfig`
    #'              object that configures network isolation, encryption of
    #'              inter-container traffic, security group IDs, and subnets.
    initialize = function(role,
                          image_uri,
                          instance_count,
                          instance_type,
                          entrypoint=NULL,
                          volume_size_in_gb=30,
                          volume_kms_key=NULL,
                          output_kms_key=NULL,
                          max_runtime_in_seconds=NULL,
                          base_job_name=NULL,
                          sagemaker_session=NULL,
                          env=NULL,
                          tags=NULL,
                          network_config=NULL){
      self$role = role
      self$image_uri = image_uri
      self$instance_count = instance_count
      self$instance_type = instance_type
      self$entrypoint = entrypoint
      self$volume_size_in_gb = volume_size_in_gb
      self$volume_kms_key = volume_kms_key
      self$output_kms_key = output_kms_key
      self$max_runtime_in_seconds = max_runtime_in_seconds
      self$base_job_name = base_job_name
      self$env = env
      self$tags = tags
      self$network_config = network_config

      self$jobs = list()
      self$latest_job = NULL
      self$.current_job_name = NULL
      self$arguments = NULL

      if(self$instance_type %in% c("local", "local_gpu")){
        if(!inherits(sagemaker_session, "LocalSession")){
          LocalSession = pkg_method("LocalSession", "sagemaker.local")
          sagemaker_session = LocalSession$new()
        }
      }

      self$sagemaker_session = sagemaker_session %||% Session$new()
    },

    #' @description Runs a processing job.
    #' @param inputs (list[:class:`~sagemaker.processing.ProcessingInput`]): Input files for
    #'              the processing job. These must be provided as
    #'              :class:`~sagemaker.processing.ProcessingInput` objects (default: NULL).
    #' @param outputs (list[:class:`~sagemaker.processing.ProcessingOutput`]): Outputs for
    #'              the processing job. These can be specified as either path strings or
    #'              :class:`~sagemaker.processing.ProcessingOutput` objects (default: NULL).
    #' @param arguments (list[str]): A list of string arguments to be passed to a
    #'              processing job (default: NULL).
    #' @param wait (bool): Whether the call should wait until the job completes (default: True).
    #' @param logs (bool): Whether to show the logs produced by the job.
    #'              Only meaningful when ``wait`` is True (default: True).
    #' @param job_name (str): Processing job name. If not specified, the processor generates
    #'              a default job name, based on the base job name and current timestamp.
    #' @param experiment_config (dict[str, str]): Experiment management configuration.
    #'              Dictionary contains three optional keys:
    #'              'ExperimentName', 'TrialName', and 'TrialComponentDisplayName'.
    run = function(inputs=NULL,
                   outputs=NULL,
                   arguments=NULL,
                   wait=TRUE,
                   logs=TRUE,
                   job_name=NULL,
                   experiment_config=NULL){
      if (logs && !wait)
        ValueError$new(
          "Logs can only be shown if wait is set to True. ",
          "Please either set wait to True or set logs to False."
        )

      ll = private$.normalize_args(
        job_name=job_name,
        arguments=arguments,
        inputs=inputs,
        kms_key=kms_key,
        outputs=outputs
      )
      self$latest_job = ProcessingJob$new()$start_new(
        processor=self,
        inputs=ll$normalized_inputs,
        outputs=ll$normalized_outputs,
        experiment_config=experiment_config
      )
      self$jobs = c(self$jobs, self$latest_job)
      if (wait) self$latest_job$wait(logs=logs)
    },

    #' @description format class
    format = function(){
      format_class(self)
    }
  ),
  private = list(

    # Extend inputs and outputs based on extra parameters
    .extend_processing_args = function(inputs, outputs, ...){
      return(list(inputs, outputs))
    },

    # Normalizes the arguments so that they can be passed to the job run
    # Args:
    #   job_name (str): Name of the processing job to be created. If not specified, one
    # is generated, using the base name given to the constructor, if applicable
    # (default: None).
    # arguments (list[str]): A list of string arguments to be passed to a
    # processing job (default: None).
    # inputs (list[:class:`~sagemaker.processing.ProcessingInput`]): Input files for
    # the processing job. These must be provided as
    # :class:`~sagemaker.processing.ProcessingInput` objects (default: None).
    # outputs (list[:class:`~sagemaker.processing.ProcessingOutput`]): Outputs for
    # the processing job. These can be specified as either path strings or
    # :class:`~sagemaker.processing.ProcessingOutput` objects (default: None).
    # code (str): This can be an S3 URI or a local path to a file with the framework
    # script to run (default: None). A no op in the base class.
    # kms_key (str): The ARN of the KMS key that is used to encrypt the
    # user code file (default: None).
    .normalize_args = function(job_name=NULL,
                               arguments=NULL,
                               inputs=NULL,
                               outputs=NULL,
                               code=NULL,
                               kms_key=NULL){
      self$.current_job_name = private$.generate_current_job_name(job_name=job_name)

      inputs_with_code = private$.include_code_in_inputs(inputs, code, kms_key)
      normalized_inputs = private$.normalize_inputs(inputs_with_code, kms_key)
      normalized_outputs = private$.normalize_outputs(outputs)
      self$arguments = arguments
      return(list(
        "normalized_inputs"=normalized_inputs,
        "normalized_outputs"=normalized_outputs)
      )
    },

    # A no op in the base class to include code in the processing job inputs.
    # Args:
    #   inputs (list[:class:`~sagemaker.processing.ProcessingInput`]): Input files for
    # the processing job. These must be provided as
    # :class:`~sagemaker.processing.ProcessingInput` objects.
    # _code (str): This can be an S3 URI or a local path to a file with the framework
    # script to run (default: None). A no op in the base class.
    # kms_key (str): The ARN of the KMS key that is used to encrypt the
    # user code file (default: None).
    # Returns:
    #   list[:class:`~sagemaker.processing.ProcessingInput`]: inputs
    .include_code_in_inputs = function(inputs,
                                       .code,
                                       .kms_key){
      return(inputs)
    },

    # Generates the job name before running a processing job.
    # Args:
    #   job_name (str): Name of the processing job to be created. If not
    # specified, one is generated, using the base name given to the
    # constructor if applicable.
    # Returns:
    #   str: The supplied or generated job name.
    .generate_current_job_name = function(job_name=NULL){
      if (!is.null(job_name))
        return(job_name)
      # Honor supplied base_job_name or generate it.
      if (!is.null(self$base_job_name))
        base_name = self$base_job_name
      else
        base_name = base_name_from_image(self$image_uri)
      return(name_from_base(base_name))
    },

    # Ensures that all the ``ProcessingInput`` objects have names and S3 URIs.
    # Args:
    #   inputs (list[sagemaker.processing.ProcessingInput]): A list of ``ProcessingInput``
    # objects to be normalized (default: None). If not specified,
    # an empty list is returned.
    # kms_key (str): The ARN of the KMS key that is used to encrypt the
    # user code file (default: None).
    # Returns:
    #   list[sagemaker.processing.ProcessingInput]: The list of normalized
    # ``ProcessingInput`` objects.
    # Raises:
    #   TypeError: if the inputs are not ``ProcessingInput`` objects.
    .normalize_inputs = function(inputs=NULL,
                                 kms_key=NULL){
      # Initialize a list of normalized ProcessingInput objects.
      normalized_inputs = list()
      if (!is.null(inputs)){
        # Iterate through the provided list of inputs.
        for (count in 1:length(inputs)){
          if (!inherits(inputs[[count]], "ProcessingInput"))
            TypeError$new("Your inputs must be provided as ProcessingInput objects.")
          # Generate a name for the ProcessingInput if it doesn't have one.
          if (islistempty(inputs[[count]]$input_name))
            inputs[[count]]$input_name = sprintf("input-%s",count)

          if (inherits(inputs[[count]]$source, "Properties") || !is.null(inputs[[count]]$dataset_definition)){
            normalized_inputs = c(normalized_inputs,  inputs[[count]])
            next
          }
          if (inherits(inputs[[count]]$s3_input$s3_uri, c("Parameter", "Expression", "Properties"))){
            normalized_inputs = c(normalized_inputs,  inputs[[count]])
            next
          }
          # If the source is a local path, upload it to S3
          # and save the S3 uri in the ProcessingInput source.
          parse_result = parse_url(inputs[[count]]$s3_input$s3_uri)
          if (!identical(parse_result$scheme, "s3")){
            desired_s3_uri = s3_path_join(
              "s3://",
              self$sagemaker_session$default_bucket(),
              self$.current_job_name,
              "input",
              inputs[[count]]$input_name)
            s3_uri = S3Uploader$new()$upload(
              local_path=inputs[[count]]$s3_input$s3_uri,
              desired_s3_uri=desired_s3_uri,
              sagemaker_session=self$sagemaker_session,
              kms_key=kms_key)
            inputs[[count]]$s3_input$s3_uri = s3_uri
          }
          normalized_inputs = list.append(normalized_inputs, inputs[[count]])
        }
      }
      return(normalized_inputs)
    },

    # Ensures that all the outputs are ``ProcessingOutput`` objects with
    # names and S3 URIs.
    # Args:
    #   outputs (list[sagemaker.processing.ProcessingOutput]): A list
    # of outputs to be normalized (default: NULL). Can be either strings or
    # ``ProcessingOutput`` objects. If not specified,
    # an empty list is returned.
    # Returns:
    #   list[sagemaker.processing.ProcessingOutput]: The list of normalized
    # ``ProcessingOutput`` objects.
    .normalize_outputs = function(outputs = NULL){
      # Initialize a list of normalized ProcessingOutput objects.
      normalized_outputs = list()
      if (!is.null(outputs)){
        # Iterate through the provided list of outputs.
        for(count in 1:length(outputs)){
          if (!inherits(outputs[[count]], "ProcessingOutput"))
            TypeError$new("Your outputs must be provided as ProcessingOutput objects.")
          # Generate a name for the ProcessingOutput if it doesn't have one.
          if (islistempty(outputs[[count]]$output_name))
            outputs[[count]]$output_name = sprintf("output-%s",count)
          if (inherits(outputs[[count]]$destination, c("Parameter", "Expression", "Properties"))){
            normalized_outputs = list.append(normalized_outputs, outputs[[count]])
            next
          }
          # If the output's destination is not an s3_uri, create one.
          parse_result = parse_url(outputs[[count]]$destination)
          if (!identical(parse_result$scheme, "s3")){
            s3_uri = s3_path_join(
              "s3://",
              self$sagemaker_session$default_bucket(),
              self$.current_job_name,
              "input",
              outputs[[count]]$output_name)
            outputs[[count]]$destination = s3_uri}
          normalized_outputs = list.append(normalized_outputs, outputs[[count]])
        }
      }
      return(normalized_outputs)
    }
  )
)

#' @title Script Processor class
#' @family Processor
#' @description Handles Amazon SageMaker processing tasks for jobs using a machine learning framework.
#' @export
ScriptProcessor = R6Class("ScriptProcessor",
  inherit = Processor,
  public = list(

    #' @description Initializes a ``ScriptProcessor`` instance. The ``ScriptProcessor``
    #'              handles Amazon SageMaker Processing tasks for jobs using a machine learning framework,
    #'              which allows for providing a script to be run as part of the Processing Job.
    #' @param role (str): An AWS IAM role name or ARN. Amazon SageMaker Processing
    #'              uses this role to access AWS resources, such as
    #'              data stored in Amazon S3.
    #' @param image_uri (str): The URI of the Docker image to use for the
    #'              processing jobs.
    #' @param command ([str]): The command to run, along with any command-line flags.
    #'              Example: ["python3", "-v"].
    #' @param instance_count (int): The number of instances to run
    #'              a processing job with.
    #' @param instance_type (str): The type of EC2 instance to use for
    #'              processing, for example, 'ml.c4.xlarge'.
    #' @param volume_size_in_gb (int): Size in GB of the EBS volume
    #'              to use for storing data during processing (default: 30).
    #' @param volume_kms_key (str): A KMS key for the processing
    #'              volume (default: NULL).
    #' @param output_kms_key (str): The KMS key ID for processing job outputs (default: NULL).
    #' @param max_runtime_in_seconds (int): Timeout in seconds (default: NULL).
    #'              After this amount of time, Amazon SageMaker terminates the job,
    #'              regardless of its current status. If `max_runtime_in_seconds` is not
    #'              specified, the default value is 24 hours.
    #' @param base_job_name (str): Prefix for processing name. If not specified,
    #'              the processor generates a default job name, based on the
    #'              processing image name and current timestamp.
    #' @param sagemaker_session (:class:`~sagemaker.session.Session`):
    #'              Session object which manages interactions with Amazon SageMaker and
    #'              any other AWS services needed. If not specified, the processor creates
    #'              one using the default AWS configuration chain.
    #' @param env (dict[str, str]): Environment variables to be passed to
    #'              the processing jobs (default: NULL).
    #' @param tags (list[dict]): List of tags to be passed to the processing job
    #'              (default: NULL). For more, see
    #'              https://docs.aws.amazon.com/sagemaker/latest/dg/API_Tag.html.
    #' @param network_config (:class:`~sagemaker.network.NetworkConfig`):
    #'              A :class:`~sagemaker.network.NetworkConfig`
    #'              object that configures network isolation, encryption of
    #'              inter-container traffic, security group IDs, and subnets.
    initialize = function(role,
                          image_uri,
                          command,
                          instance_count,
                          instance_type,
                          volume_size_in_gb=30,
                          volume_kms_key=NULL,
                          output_kms_key=NULL,
                          max_runtime_in_seconds=NULL,
                          base_job_name=NULL,
                          sagemaker_session=NULL,
                          env=NULL,
                          tags=NULL,
                          network_config=NULL){
      self$.CODE_CONTAINER_BASE_PATH = "/opt/ml/processing/input/"
      self$.CODE_CONTAINER_INPUT_NAME = "code"
      self$command = command

      super$initialize(role=role,
                       image_uri=image_uri,
                       instance_count=instance_count,
                       instance_type=instance_type,
                       volume_size_in_gb=volume_size_in_gb,
                       volume_kms_key=volume_kms_key,
                       output_kms_key=output_kms_key,
                       max_runtime_in_seconds=max_runtime_in_seconds,
                       base_job_name=base_job_name,
                       sagemaker_session=sagemaker_session,
                       env=env,
                       tags=tags,
                       network_config=network_config)
    },

    #' @description Returns a RunArgs object.
    #'              For processors (:class:`~sagemaker.spark.processing.PySparkProcessor`,
    #'              :class:`~sagemaker.spark.processing.SparkJar`) that have special
    #'              run() arguments, this object contains the normalized arguments for passing to
    #'              :class:`~sagemaker.workflow.steps.ProcessingStep`.
    #' @param code (str): This can be an S3 URI or a local path to a file with the framework
    #'              script to run.
    #' @param inputs (list[:class:`~sagemaker.processing.ProcessingInput`]): Input files for
    #'              the processing job. These must be provided as
    #'              :class:`~sagemaker.processing.ProcessingInput` objects (default: None).
    #' @param outputs (list[:class:`~sagemaker.processing.ProcessingOutput`]): Outputs for
    #'              the processing job. These can be specified as either path strings or
    #'              :class:`~sagemaker.processing.ProcessingOutput` objects (default: None).
    #' @param arguments (list[str]): A list of string arguments to be passed to a
    #'              processing job (default: None).
    get_run_args = function(code,
                            inputs=NULL,
                            outputs=NULL,
                            arguments=NULL){
      return(RunArgs$new(code=code, inputs=inputs, outputs=outputs, arguments=arguments))
    },

    #' @description Runs a processing job.
    #' @param code (str): This can be an S3 URI or a local path to
    #'              a file with the framework script to run.
    #' @param inputs (list[:class:`~sagemaker.processing.ProcessingInput`]): Input files for
    #'              the processing job. These must be provided as
    #'              :class:`~sagemaker.processing.ProcessingInput` objects (default: NULL).
    #' @param outputs (list[:class:`~sagemaker.processing.ProcessingOutput`]): Outputs for
    #'              the processing job. These can be specified as either path strings or
    #'              :class:`~sagemaker.processing.ProcessingOutput` objects (default: NULL).
    #' @param arguments (list[str]): A list of string arguments to be passed to a
    #'              processing job (default: NULL).
    #' @param wait (bool): Whether the call should wait until the job completes (default: True).
    #' @param logs (bool): Whether to show the logs produced by the job.
    #'              Only meaningful when wait is True (default: True).
    #' @param job_name (str): Processing job name. If not specified, the processor generates
    #'              a default job name, based on the base job name and current timestamp.
    #' @param experiment_config (dict[str, str]): Experiment management configuration.
    #'              Dictionary contains three optional keys:
    #'              'ExperimentName', 'TrialName', and 'TrialComponentDisplayName'.
    #' @param kms_key (str): The ARN of the KMS key that is used to encrypt the
    #'              user code file (default: None).
    run = function(code,
                   inputs=NULL,
                   outputs=NULL,
                   arguments=NULL,
                   wait=TRUE,
                   logs=TRUE,
                   job_name=NULL,
                   experiment_config=NULL,
                   kms_key=NULL){
      ll = private$.normalize_args(
        job_name=job_name,
        arguments=arguments,
        inputs=inputs,
        outputs=outputs,
        code=code,
        kms_key=kms_key)
      self$latest_job = ProcessingJob$new()$start_new(
          processor=self,
          inputs=ll$normalized_inputs,
          outputs=ll$normalized_outputs,
          experiment_config=experiment_config)
      self$jobs = c(self$jobs, self$latest_job)

      if (wait) self$latest_job$wait(logs=logs)
    }
  ),
  private = list(

    # Converts code to appropriate input and includes in input list.
    # Side effects include:
    #   * uploads code to S3 if the code is a local file.
    # * sets the entrypoint attribute based on the command and user script name from code.
    # Args:
    #   inputs (list[:class:`~sagemaker.processing.ProcessingInput`]): Input files for
    # the processing job. These must be provided as
    # :class:`~sagemaker.processing.ProcessingInput` objects.
    # code (str): This can be an S3 URI or a local path to a file with the framework
    # script to run (default: None).
    # kms_key (str): The ARN of the KMS key that is used to encrypt the
    # user code file (default: None).
    # Returns:
    #   list[:class:`~sagemaker.processing.ProcessingInput`]: inputs together with the
    # code as `ProcessingInput`.
    .include_code_in_inputs = function(inputs, code, kms_key=NULL){
      user_code_s3_uri = private$.handle_user_code_url(code, kms_key)
      user_script_name = private$.get_user_code_name(code)

      inputs_with_code = private$.convert_code_and_add_to_inputs(inputs, user_code_s3_uri)
      private$.set_entrypoint(self$command, user_script_name)
      return(inputs_with_code)
    },

    # Gets the basename of the user's code from the URL the customer provided.
    # Args:
    #     code (str): A URL to the user's code.
    # Returns:
    #   str: The basename of the user's code.
    .get_user_code_name = function(code){
      code_url = parse_url(code)
      return (basename(code_url$path))
    },

    # Gets the S3 URL containing the user's code.
    #    Inspects the scheme the customer passed in ("s3://" for code in S3, "file://" or nothing
    #    for absolute or local file paths. Uploads the code to S3 if the code is a local file.
    # Args:
    #     code (str): A URL to the customer's code.
    # Returns:
    #   str: The S3 URL to the customer's code.
    .handle_user_code_url = function(code, kms_key=NULL){
      code_url = parse_url(code)
      if (identical(code_url$scheme, "s3")) {
        user_code_s3_uri = code
      } else if(is.na(code_url$scheme) || identical(code_url$scheme, "file")) {
        # Validate that the file exists locally and is not a directory.
        code_path = urltools::url_decode(code_url$path)
        if (!fs::file_exists(code_path)){
          ValueError$new(sprintf(
            "code %s wasn't found. Please make sure that the file exists.",
            code)
          )
        }
        if (!fs::is_file(code_path)){
          ValueError$new(sprintf(
            "code %s must be a file, not a directory. Please pass a path to a file.",
            code)
          )
        }
        user_code_s3_uri = private$.upload_code(code_path, kms_key)
      } else {
        ValueError$new(sprintf(
          "code %s url scheme %s is not recognized. Please pass a file path or S3 url",
          code, code_url$scheme)
        )
      }
      return(user_code_s3_uri)
    },

    # Uploads a code file or directory specified as a string
    # and returns the S3 URI.
    # Args:
    #   code (str): A file or directory to be uploaded to S3.
    # Returns:
    #   str: The S3 URI of the uploaded file or directory.
    .upload_code = function(code, kms_key=NULL){
      desired_s3_uri = s3_path_join(
        "s3://",
        self$sagemaker_session$default_bucket(),
        self$.current_job_name,
        "input",
        self$.CODE_CONTAINER_INPUT_NAME)
      return(S3Uploader$new()$upload(
        local_path=code,
        desired_s3_uri=desired_s3_uri,
        kms_key=kms_key,
        sagemaker_session=self$sagemaker_session
        )
      )
    },

    # Creates a ``ProcessingInput`` object from an S3 URI and adds it to the list of inputs.
    # Args:
    #   inputs (list[sagemaker.processing.ProcessingInput]):
    #   List of ``ProcessingInput`` objects.
    # s3_uri (str): S3 URI of the input to be added to inputs.
    # Returns:
    #   list[sagemaker.processing.ProcessingInput]: A new list of ``ProcessingInput`` objects,
    # with the ``ProcessingInput`` object created from ``s3_uri`` appended to the list.
    .convert_code_and_add_to_inputs = function(inputs, s3_uri){
      code_file_input = ProcessingInput$new(
        source=s3_uri,
        destination=sprintf("%s%s",
          self$.CODE_CONTAINER_BASE_PATH, self$.CODE_CONTAINER_INPUT_NAME),
        input_name=self$.CODE_CONTAINER_INPUT_NAME)
      return(c(inputs, code_file_input))
    },

    # Sets the entrypoint based on the user's script and corresponding executable.
    # Args:
    #     user_script_name (str): A filename with an extension.
    .set_entrypoint = function(command, user_script_name){
      user_script_location = sprintf("%s%s/%s",
        self$.CODE_CONTAINER_BASE_PATH, self$.CODE_CONTAINER_INPUT_NAME, user_script_name)
      self$entrypoint = list(command, user_script_location)
    }
  ),
  lock_objects = F
)

#' @title ProccesingJob Class
#' @family Processor
#' @description Provides functionality to start, describe, and stop processing jobs.
#' @export
ProcessingJob = R6Class("ProcessingJob",
  inherit = .Job,
  public = list(
    #' @field inputs
    #' A list of :class:`~sagemaker.processing.ProcessingInput` objects.
    inputs = NULL,

    #' @field outputs
    #' A list of :class:`~sagemaker.processing.ProcessingOutput` objects.
    outputs = NULL,

    #' @field output_kms_key
    #' The output KMS key associated with the job
    output_kms_key = NULL,

    #' @description Initializes a Processing job.
    #' @param sagemaker_session (:class:`~sagemaker.session.Session`):
    #'              Session object which manages interactions with Amazon SageMaker and
    #'              any other AWS services needed. If not specified, the processor creates
    #'              one using the default AWS configuration chain.
    #' @param job_name (str): Name of the Processing job.
    #' @param inputs (list[:class:`~sagemaker.processing.ProcessingInput`]): A list of
    #'              :class:`~sagemaker.processing.ProcessingInput` objects.
    #' @param outputs (list[:class:`~sagemaker.processing.ProcessingOutput`]): A list of
    #'              :class:`~sagemaker.processing.ProcessingOutput` objects.
    #' @param output_kms_key (str): The output KMS key associated with the job (default: None).
    initialize = function(sagemaker_session=NULL,
                          job_name=NULL,
                          inputs=NULL,
                          outputs=NULL,
                          output_kms_key=NULL){
      self$inputs = inputs
      self$outputs = outputs
      self$output_kms_key = output_kms_key
      super$initialize(sagemaker = sagemaker_session, job_name = job_name)
    },

    #' @description Starts a new processing job using the provided inputs and outputs.
    #' @param processor (:class:`~sagemaker.processing.Processor`): The ``Processor`` instance
    #'              that started the job.
    #' @param inputs (list[:class:`~sagemaker.processing.ProcessingInput`]): A list of
    #'              :class:`~sagemaker.processing.ProcessingInput` objects.
    #' @param outputs (list[:class:`~sagemaker.processing.ProcessingOutput`]): A list of
    #'              :class:`~sagemaker.processing.ProcessingOutput` objects.
    #' @param experiment_config (dict[str, str]): Experiment management configuration.
    #'              Dictionary contains three optional keys:
    #'              'ExperimentName', 'TrialName', and 'TrialComponentDisplayName'.
    #' @return :class:`~sagemaker.processing.ProcessingJob`: The instance of ``ProcessingJob`` created
    #'              using the ``Processor``.
    start_new = function(processor,
                         inputs,
                         outputs,
                         experiment_config){
      process_args = private$.get_process_args(processor, inputs, outputs, experiment_config)

      # Print the job name and the user's inputs and outputs as lists of dictionaries.
      writeLines("")
      writeLines(sprintf("Job Name: %s", process_args$job_name))
      writeLines(sprintf("Inputs: %s",
        jsonlite::toJSON(process_args$inputs, auto_unbox = T)))
      writeLines(sprintf("Outputs: %s",
        jsonlite::toJSON(process_args$output_config$Outputs, auto_unbox = T)))

      # Call sagemaker_session.process using the arguments dictionary.
      do.call(processor$sagemaker_session$process, process_args)

      cls = self$clone()
      cls$initialize(
        processor$sagemaker_session,
        processor$.current_job_name,
        inputs,
        outputs,
        processor$output_kms_key
      )
      return(cls)
    },

    #' @description Initializes a ``ProcessingJob`` from a processing job name.
    #' @param sagemaker_session (:class:`~sagemaker.session.Session`):
    #'              Session object which manages interactions with Amazon SageMaker and
    #'              any other AWS services needed. If not specified, the processor creates
    #'              one using the default AWS configuration chain.
    #' @param processing_job_name (str): Name of the processing job.
    #' @return :class:`~sagemaker.processing.ProcessingJob`: The instance of ``ProcessingJob`` created
    #'              from the job name.
    from_processing_name = function(sagemaker_session,
                                    processing_job_name){
      job_desc = sagemaker_session$describe_processing_job(job_name=processing_job_name)

      inputs = NULL
      if (!islistempty(job_desc$ProcessingInputs)){
        inputs = lapply(
          job_desc$ProcessingInputs, function(processing_input) {
            ProcessingInput$new(
              input_name=processing_input$InputName,
              s3_input=S3Input$new()$from_paws(processing_input[["S3Input"]]),
              dataset_definition=DatasetDefinition$new()$from_paws(
                processing_input[["DatasetDefinition"]]),
              app_managed=processing_input[["AppManaged"]] %||% FALSE)
        })
      }
      outputs = NULL
      if (!islistempty(job_desc$ProcessingOutputConfig) && !islistempty(job_desc$ProcessingOutputConfig$Outputs)){
        outputs = lapply(
          job_desc$ProcessingOutputConfig$Outputs,
          function(processing_output_dict) {
            processing_output = ProcessingOutput$new(
              output_name=processing_output_dict[["OutputName"]],
              app_managed=processing_output_dict[["AppManaged"]] %||% FALSE,
              feature_store_output=FeatureStoreOutput$new()$from_paws(
                processing_output_dict[["FeatureStoreOutput"]]))

            if("S3Output" %in% names(processing_output_dict)){
              processing_output$source = processing_output_dict[["S3Output"]][["LocalPath"]]
              processing_output$destination = processing_output_dict[["S3Output"]][["S3Uri"]]
            }
            return(processing_output)
        })
      }
      output_kms_key = NULL
      if (!islistempty(job_desc$ProcessingOutputConfig))
        output_kms_key = job_desc$ProcessingOutputConfig$KmsKeyId

      cls = self$clone()
      cls$initialize(
        sagemaker_session=sagemaker_session,
        job_name=processing_job_name,
        inputs=inputs,
        outputs=outputs,
        output_kms_key=output_kms_key
      )
      return(cls)
    },

    #' @description Initializes a ``ProcessingJob`` from a Processing ARN.
    #' @param sagemaker_session (:class:`~sagemaker.session.Session`):
    #'              Session object which manages interactions with Amazon SageMaker and
    #'              any other AWS services needed. If not specified, the processor creates
    #'              one using the default AWS configuration chain.
    #' @param processing_job_arn (str): ARN of the processing job.
    #' @return :class:`~sagemaker.processing.ProcessingJob`: The instance of ``ProcessingJob`` created
    #'              from the processing job's ARN.
    from_processing_arn = function(sagemaker_session,
                                   processing_job_arn){
      processing_job_name = split_str(processing_job_arn, ":")[6]
      processing_job_name = substring(
        processing_job_name,
        nchar("processing-job/") + 1,
        nchar(processing_job_name)) # This is necessary while the API only vends an arn.
      return(self$from_processing_name(
        sagemaker_session=sagemaker_session, processing_job_name=processing_job_name
        )
      )
    },

    #' @description Waits for the processing job to complete.
    #' @param logs (bool): Whether to show the logs produced by the job (default: True).
    wait = function(logs = TRUE){
      if (logs)
        self$sagemaker_session$logs_for_processing_job(self$job_name, wait=TRUE)
      else
        self$sagemaker_session$wait_for_processing_job(self$job_name)
    },

    #' @description Prints out a response from the DescribeProcessingJob API call.
    describe = function(){
      return(self$sagemaker_session$describe_processing_job(self$job_name))
    },

    #' @description the processing job.
    stop = function(){
      return(self$sagemaker_session$stop_processing_job(self$name))
    },

    #' @description Prepares a dict that represents a ProcessingJob's AppSpecification.
    #' @param container_arguments (list[str]): The arguments for a container
    #'              used to run a processing job.
    #' @param container_entrypoint (list[str]): The entrypoint for a container
    #'              used to run a processing job.
    #' @param image_uri (str): The container image to be run by the processing job.
    #' @return dict: Represents AppSpecification which configures the
    #'              processing job to run a specified Docker container image.
    prepare_app_specification = function(container_arguments,
                                         container_entrypoint,
                                         image_uri){
      config = list("ImageUri"=image_uri)
      if (!islistempty(container_arguments))
        config[["ContainerArguments"]] = container_arguments
      if (!islistempty(container_entrypoint))
        config[["ContainerEntrypoint"]] = container_entrypoint
        return(invisible())
    },

    #' @description Prepares a dict that represents a ProcessingOutputConfig.
    #' @param kms_key_id (str): The AWS Key Management Service (AWS KMS) key that
    #'              Amazon SageMaker uses to encrypt the processing job output.
    #'              KmsKeyId can be an ID of a KMS key, ARN of a KMS key, alias of a KMS key,
    #'              or alias of a KMS key. The KmsKeyId is applied to all outputs.
    #' @param outputs (list[dict]): Output configuration information for a processing job.
    #' @return dict: Represents output configuration for the processing job.
    prepare_output_config = function(kms_key_id,
                                     outputs){
      config = list("Outputs"=outputs)
      if (!is.null(kms_key_id))
        config[["KmsKeyId"]] = kms_key_id
      return(invisible())
    },

    #' @description Prepares a dict that represents the ProcessingResources.
    #' @param instance_count (int): The number of ML compute instances
    #'              to use in the processing job. For distributed processing jobs,
    #'              specify a value greater than 1. The default value is 1.
    #' @param instance_type (str): The ML compute instance type for the processing job.
    #' @param volume_kms_key_id (str): The AWS Key Management Service (AWS KMS) key
    #'              that Amazon SageMaker uses to encrypt data on the storage
    #'              volume attached to the ML compute instance(s) that run the processing job.
    #' @param volume_size_in_gb (int): The size of the ML storage volume in gigabytes
    #'              that you want to provision. You must specify sufficient
    #'              ML storage for your scenario.
    #' @return dict: Represents ProcessingResources which identifies the resources,
    #'              ML compute instances, and ML storage volumes to deploy
    #'              for a processing job.
    prepare_processing_resources = function(instance_count,
                                            instance_type,
                                            volume_kms_key_id,
                                            volume_size_in_gb){
      processing_resources = list()
      cluster_config = list(
        "InstanceCount"=instance_count,
        "InstanceType"=instance_type,
        "VolumeSizeInGB"=volume_size_in_gb
      )
      if (!is.null(volume_kms_key_id))
        cluster_config[["VolumeKmsKeyId"]] = volume_kms_key_id
      processing_resources[["ClusterConfig"]] = cluster_config
      return(processing_resources)
    },

    #' @description Prepares a dict that represents the job's StoppingCondition.
    #' @param max_runtime_in_seconds (int): Specifies the maximum runtime in seconds.
    #' @return list
    prepare_stopping_condition= function(max_runtime_in_seconds){
      return(list("MaxRuntimeInSeconds"=max_runtime_in_seconds))
    }
  ),
  private = list(

    # Gets a dict of arguments for a new Amazon SageMaker processing job from the processor
    # Args:
    #   processor (:class:`~sagemaker.processing.Processor`): The ``Processor`` instance
    # that started the job.
    # inputs (list[:class:`~sagemaker.processing.ProcessingInput`]): A list of
    # :class:`~sagemaker.processing.ProcessingInput` objects.
    # outputs (list[:class:`~sagemaker.processing.ProcessingOutput`]): A list of
    # :class:`~sagemaker.processing.ProcessingOutput` objects.
    # experiment_config (dict[str, str]): Experiment management configuration.
    # Dictionary contains three optional keys:
    #   'ExperimentName', 'TrialName', and 'TrialComponentDisplayName'.
    # Returns:
    #   Dict: dict for `sagemaker.session.Session.process` method
    .get_process_args = function(processor,
                                 inputs,
                                 outputs,
                                 experiment_config){
      # Initialize an empty dictionary for arguments to be passed to sagemaker_session.process.
      process_request_args = list()

      # Add arguments to the dictionary.
      process_request_args[["inputs"]] = lapply(inputs, function(input) {
        input$to_request_list()
      })

      process_request_args[["output_config"]] = list(
        "Outputs"= lapply(outputs, function(output) output$to_request_list())
      )
      if (!islistempty(processor$output_kms_key))
        process_request_args[["output_config"]][["KmsKeyId"]] = processor$output_kms_key
      # ensure NULL value is kept
      process_request_args["experiment_config"] = list(experiment_config)
      process_request_args[["job_name"]] = processor$.current_job_name

      process_request_args[["resources"]] = list(
        "ClusterConfig" = list(
          "InstanceType"= processor$instance_type,
          "InstanceCount"= processor$instance_count,
          "VolumeSizeInGB"= processor$volume_size_in_gb
        )
      )

      if(!islistempty(processor$volume_kms_key)){
        process_request_args[["resources"]][["ClusterConfig"]][["VolumeKmsKeyId"]] = processor$volume_kms_key
      }
      if(!islistempty(processor$max_runtime_in_seconds)){
        process_request_args[["stopping_condition"]] = list(
          "MaxRuntimeInSeconds"= processor$max_runtime_in_seconds)
      } else {
        # ensure NULL value is kept
        process_request_args["stopping_condition"] = list(NULL)
      }
      process_request_args[["app_specification"]] = list("ImageUri"= processor$image_uri)
      if (!islistempty(processor$arguments))
        process_request_args[["app_specification"]][["ContainerArguments"]] = processor$arguments
      if (!islistempty(processor$entrypoint))
        process_request_args[["app_specification"]][["ContainerEntrypoint"]] = processor$entrypoint

      # ensure NULL value is kept
      process_request_args["environment"] = list(processor$env)

      if (!islistempty(processor$network_config)){
        process_request_args[["network_config"]] = processor$network_config$to_request_list()
      } else {
        # ensure NULL value is kept
        process_request_args["network_config"] = list(NULL)
      }
      process_request_args[["role_arn"]] = processor$sagemaker_session$expand_role(processor$role)

      # ensure NULL value is kept
      process_request_args["tags"] = list(processor$tags)

      return(process_request_args)
    },

    # Used for Local Mode. Not yet implemented.
    # Args:
    #   input_url (str): input URL
    .is_local_channel = function(input_url){
      NotImplementedError$new()
    }
  )
)

#' @title ProcessingInput Class
#' @family Processor
#' @description Accepts parameters that specify an Amazon S3 input for a processing job and
#'              provides a method to turn those parameters into a dictionary.
#' @export
ProcessingInput = R6Class("ProcessingInput",
  public = list(

    #' @description Initializes a ``ProcessingInput`` instance. ``ProcessingInput`` accepts parameters
    #'              that specify an Amazon S3 input for a processing job and provides a method
    #'              to turn those parameters into a dictionary.
    #' @param source (str): The source for the input. If a local path is provided, it will
    #'              automatically be uploaded to S3 under:
    #'              "s3://<default-bucket-name>/<job-name>/input/<input-name>".
    #' @param destination (str): The destination of the input.
    #' @param input_name (str): The name for the input. If a name
    #'              is not provided, one will be generated (eg. "input-1").
    #' @param s3_data_type (str): Valid options are "ManifestFile" or "S3Prefix".
    #' @param s3_input_mode (str): Valid options are "Pipe" or "File".
    #' @param s3_data_distribution_type (str): Valid options are "FullyReplicated"
    #'              or "ShardedByS3Key".
    #' @param s3_compression_type (str): Valid options are "None" or "Gzip".
    #' @param s3_input (:class:`~sagemaker.dataset_definition.S3Input`)
    #'              Metadata of data objects stored in S3
    #' @param dataset_definition (:class:`~sagemaker.dataset_definition.DatasetDefinition`)
    #'              DatasetDefinition input
    #' @param app_managed (bool): Whether the input are managed by SageMaker or application
    initialize = function(source=NULL,
                          destination=NULL,
                          input_name=NULL,
                          s3_data_type=c("S3Prefix", "ManifestFile"),
                          s3_input_mode=c("File", "Pipe"),
                          s3_data_distribution_type=c("FullyReplicated", "ShardedByS3Key"),
                          s3_compression_type=c("None", "Gzip"),
                          s3_input=NULL,
                          dataset_definition=NULL,
                          app_managed=FALSE){
      self$source = source
      self$destination = destination
      self$input_name = input_name
      self$s3_data_type = match.arg(s3_data_type)
      self$s3_input_mode = match.arg(s3_input_mode)
      self$s3_data_distribution_type = match.arg(s3_data_distribution_type)
      self$s3_compression_type = match.arg(s3_compression_type)
      self$s3_input = s3_input
      self$dataset_definition = dataset_definition
      self$app_managed = app_managed
      private$.create_s3_input()
    },

    #' @description Generates a request dictionary using the parameters provided to the class.
    to_request_list = function(){
      # Create the request dictionary.
      s3_input_request = list(
        "InputName"= self$input_name,
        "AppManaged"=self$app_managed
      )

      if(!is.null(self$s3_input)){
        # Check the compression type, then add it to the dictionary.
        if (self$s3_compression_type == "Gzip"
            && self$s3_input_mode != "Pipe")
          ValueError$new("Data can only be gzipped when the input mode is Pipe.")
        s3_input_request[["S3Input"]] = S3Input$new()$to_paws(self$s3_input)
      }

      if (!is.null(self$dataset_definition))
        s3_input_request[["DatasetDefinition"]] = DatasetDefinition$new()$to_paws(
          self$dataset_definition)

      # Return the request dictionary.
      return (s3_input_request)
    },

    #' @description format class
    format = function(){
      format_class(self)
    }
  ),
  private = list(

    # Create and initialize S3Input.
    # When client provides S3Input, backfill other class memebers because they are used
    # in other places. When client provides other S3Input class memebers, create and
    # init S3Input.
    .create_s3_input = function(){
      if (!is.null(self$s3_input)){
        # backfill other class members
        self$source = self$s3_input$s3_uri
        self$destination = self$s3_input$local_path
        self$s3_data_type = self$s3_input$s3_data_type
        self$s3_input_mode = self$s3_input$s3_input_mode
        self$s3_data_distribution_type = self$s3_input$s3_data_distribution_type
      }else if (!is.null(self$source) && !is.null(self$destination)){
        self$s3_input = S3Input$new(
          s3_uri=self$source,
          local_path=self$destination,
          s3_data_type=self$s3_data_type,
          s3_input_mode=self$s3_input_mode,
          s3_data_distribution_type=self$s3_data_distribution_type,
          s3_compression_type=self$s3_compression_type
        )
      }
    }
  ),
  lock_objects = F
)

#' @title ProcessingOutput Class
#' @family Processor
#' @description Accepts parameters that specify an Amazon S3 output for a processing job and provides
#'              a method to turn those parameters into a dictionary.
#' @export
ProcessingOutput = R6Class("ProcessingOutput",
  public = list(
    #' @description Initializes a ``ProcessingOutput`` instance. ``ProcessingOutput`` accepts parameters that
    #'              specify an Amazon S3 output for a processing job and provides a method to turn
    #'              those parameters into a dictionary.
    #' @param source (str): The source for the output.
    #' @param destination (str): The destination of the output. If a destination
    #'              is not provided, one will be generated:
    #'              "s3://<default-bucket-name>/<job-name>/output/<output-name>".
    #' @param output_name (str): The name of the output. If a name
    #'              is not provided, one will be generated (eg. "output-1").
    #' @param s3_upload_mode (str): Valid options are "EndOfJob" or "Continuous".
    #'             s3_upload_mode (str): Valid options are "EndOfJob" or "Continuous".
    #' @param app_managed (bool): Whether the input are managed by SageMaker or application
    #' @param feature_store_output (:class:`~sagemaker.processing.FeatureStoreOutput`)
    #'             Configuration for processing job outputs of FeatureStore.
    initialize = function(source=NULL,
                          destination=NULL,
                          output_name=NULL,
                          s3_upload_mode=c("EndOfJob", "Continuous"),
                          app_managed=FALSE,
                          feature_store_output=NULL){
      self$source = source
      self$destination = destination
      self$output_name = output_name
      self$s3_upload_mode = match.arg(s3_upload_mode)
      self$app_managed = app_managed
      self$feature_store_output = feature_store_output
    },

    #' @description Generates a request dictionary using the parameters provided to the class.
    to_request_list = function(){
     # Create the request dictionary.
      # Create the request dictionary.
      s3_output_request = list(
        "OutputName"=self$output_name,
        "AppManaged"=self$app_managed
      )

      if (!is.null(self$source))
        s3_output_request[["S3Output"]] = list(
          "S3Uri"=self$destination,
          "LocalPath"=self$source,
          "S3UploadMode"=self$s3_upload_mode
        )

      if (!is.null(self$feature_store_output))
        s3_output_request[["FeatureStoreOutput"]] = FeatureStoreOutput$new()$to_paws(
          self$feature_store_output
        )

      # Return the request dictionary.
      return(s3_output_request)
    },

    #' @description format class
    format = function(){
      format_class(self)
    }
  ),
  lock_objects = F
)

#' @title RunArgs Class
#' @description Accepts parameters that correspond to ScriptProcessors.
#' @export
RunArgs = R6Class("RunArgs",
  public = list(

    #' @field code
    #' This can be an S3 URI or a local path to a file with the framework script to run
    code=NULL,

    #' @field inputs
    #' Input files for the processing job
    inputs=NULL,

    #' @field outputs
    #' Outputs for the processing job
    outputs=NULL,

    #' @field arguments
    #' A list of string arguments to be passed to a processing job
    arguments=NULL,

    #' @description An instance of this class is returned from the ``get_run_args()`` method on processors,
    #'             and is used for normalizing the arguments so that they can be passed to
    #'             :class:`~sagemaker.workflow.steps.ProcessingStep`
    #' @param code (str): This can be an S3 URI or a local path to a file with the framework
    #'             script to run.
    #' @param inputs (list[:class:`~sagemaker.processing.ProcessingInput`]): Input files for
    #'             the processing job. These must be provided as
    #'             :class:`~sagemaker.processing.ProcessingInput` objects (default: None).
    #' @param outputs (list[:class:`~sagemaker.processing.ProcessingOutput`]): Outputs for
    #'             the processing job. These can be specified as either path strings or
    #'             :class:`~sagemaker.processing.ProcessingOutput` objects (default: None).
    #' @param arguments (list[str]): A list of string arguments to be passed to a
    #'             processing job (default: None).
    initialize = function(code,
                          inputs=NULL,
                          outputs=NULL,
                          arguments=NULL){
      self$code=code
      self$inputs=inputs
      self$outputs=outputs
      self$arguments=arguments
    }
  )
)

#' @title Amazon SageMaker Feature Store class
#' @description Configuration for processing job outputs in Amazon SageMaker Feature Store
#' @export
FeatureStoreOutput = R6Class("FeatureStoreOutput",
  inherit = ApiObject,
  public = list(

    #' @field feature_group_name
    #' placeholder
    feature_group_name = NULL
  ),
  lock_objects = F
)

#' @title FrameworkProcessor class
#' @description Handles Amazon SageMaker processing tasks for jobs using a machine learning framework
#' @export
FrameworkProcessor = R6Class("FrameworkProcessor",
  inherit = ScriptProcessor,
  public = list(

    #' @field framework_entrypoint_command
    #'
    framework_entrypoint_command = list("/bin/bash"),

    #' @description Initializes a ``FrameworkProcessor`` instance.
    #'              The ``FrameworkProcessor`` handles Amazon SageMaker Processing tasks for jobs
    #'              using a machine learning framework, which allows for a set of Python scripts
    #'              to be run as part of the Processing Job.
    #' @param estimator_cls (type): A subclass of the :class:`~sagemaker.estimator.Framework`
    #'              estimator
    #' @param framework_version (str): The version of the framework. Value is ignored when
    #'              ``image_uri`` is provided.
    #' @param role (str): An AWS IAM role name or ARN. Amazon SageMaker Processing uses
    #'              this role to access AWS resources, such as data stored in Amazon S3.
    #' @param instance_count (int): The number of instances to run a processing job with.
    #' @param instance_type (str): The type of EC2 instance to use for processing, for
    #'              example, 'ml.c4.xlarge'.
    #' @param py_version (str): Python version you want to use for executing your
    #'              model training code. One of 'py2' or 'py3'. Defaults to 'py3'. Value
    #'              is ignored when ``image_uri`` is provided.
    #' @param image_uri (str): The URI of the Docker image to use for the
    #'              processing jobs (default: None).
    #' @param command ([str]): The command to run, along with any command-line flags
    #'              to *precede* the ```code script```. Example: ["python3", "-v"]. If not
    #'              provided, ["python"] will be chosen (default: None).
    #' @param volume_size_in_gb (int): Size in GB of the EBS volume
    #'              to use for storing data during processing (default: 30).
    #' @param volume_kms_key (str): A KMS key for the processing volume (default: None).
    #' @param output_kms_key (str): The KMS key ID for processing job outputs (default: None).
    #' @param code_location (str): The S3 prefix URI where custom code will be
    #'              uploaded (default: None). The code file uploaded to S3 is
    #'              'code_location/job-name/source/sourcedir.tar.gz'. If not specified, the
    #'              default ``code location`` is 's3://{sagemaker-default-bucket}'
    #' @param max_runtime_in_seconds (int): Timeout in seconds (default: None).
    #'              After this amount of time, Amazon SageMaker terminates the job,
    #'              regardless of its current status. If `max_runtime_in_seconds` is not
    #'              specified, the default value is 24 hours.
    #' @param base_job_name (str): Prefix for processing name. If not specified,
    #'              the processor generates a default job name, based on the
    #'              processing image name and current timestamp (default: None).
    #' @param sagemaker_session (:class:`~sagemaker.session.Session`):
    #'              Session object which manages interactions with Amazon SageMaker and
    #'              any other AWS services needed. If not specified, the processor creates
    #'              one using the default AWS configuration chain (default: None).
    #' @param env (dict[str, str]): Environment variables to be passed to
    #'              the processing jobs (default: None).
    #' @param tags (list[dict]): List of tags to be passed to the processing job
    #'              (default: None). For more, see
    #'              \url{https://docs.aws.amazon.com/sagemaker/latest/dg/API_Tag.html}.
    #' @param network_config (:class:`~sagemaker.network.NetworkConfig`):
    #'              A :class:`~sagemaker.network.NetworkConfig`
    #'              object that configures network isolation, encryption of
    #'              inter-container traffic, security group IDs, and subnets (default: None).
    initialize = function(estimator_cls,
                          framework_version,
                          role,
                          instance_count,
                          instance_type,
                          py_version="py3",
                          image_uri=NULL,
                          command=NULL,
                          volume_size_in_gb=30,
                          volume_kms_key=NULL,
                          output_kms_key=NULL,
                          code_location=NULL,
                          max_runtime_in_seconds=NULL,
                          base_job_name=NULL,
                          sagemaker_session=NULL,
                          env=NULL,
                          tags=NULL,
                          network_config=NULL){
      if (is.null(command))
        command = "python"

      self$estimator_cls = estimator_cls
      self$framework_version = framework_version
      self$py_version = py_version

      # 1. To finalize/normalize the image_uri or base_job_name, we need to create an
      #    estimator_cls instance.
      # 2. We want to make it easy for children of FrameworkProcessor to override estimator
      #    creation via a function (to create FrameworkProcessors for Estimators that may have
      #    different signatures - like HuggingFace or others in future).
      # 3. Super-class __init__ doesn't (currently) do anything with these params besides
      #    storing them
      #
      # Therefore we'll init the superclass first and then customize the setup after:
      super$initialize(
        role=role,
        image_uri=image_uri,
        command=command,
        instance_count=instance_count,
        instance_type=instance_type,
        volume_size_in_gb=volume_size_in_gb,
        volume_kms_key=volume_kms_key,
        output_kms_key=output_kms_key,
        max_runtime_in_seconds=max_runtime_in_seconds,
        base_job_name=base_job_name,
        sagemaker_session=sagemaker_session,
        env=env,
        tags=tags,
        network_config=network_config)

      # This subclass uses the "code" input for actual payload and the ScriptProcessor parent's
      # functionality for uploading just a small entrypoint script to invoke it.
      self$.CODE_CONTAINER_INPUT_NAME = "entrypoint"

      self$code_location = (
        if (!is.null(code_location) && endsWith(code_location, "/")) {
          substr(code_location, 1, nchar(code_location)-1)
        } else {
          code_location}
      )
      if (is.null(image_uri) || is.null(base_job_name)){
        # For these default configuration purposes, we don't need the optional args:
        est = private$.create_estimator()
        if (is.null(image_uri))
          self$image_uri = est$training_image_uri()
        if (is.null(base_job_name)){
          self$base_job_name = est$base_job_name %||% attr(estimator_cls, "_framework_name")
          if (is.null(base_job_name))
            base_job_name = "framework-processor"
        }
      }
    },

    #' @description This object contains the normalized inputs, outputs and arguments needed
    #'              when using a ``FrameworkProcessor`` in a :class:`~sagemaker.workflow.steps.ProcessingStep`.
    #' @param code (str): This can be an S3 URI or a local path to a file with the framework
    #'              script to run. See the ``code`` argument in
    #'              `sagemaker.processing.FrameworkProcessor.run()`.
    #' @param source_dir (str): Path (absolute, relative, or an S3 URI) to a directory wit
    #'              any other processing source code dependencies aside from the entrypoint
    #'              file (default: None). See the ``source_dir`` argument in
    #'              `sagemaker.processing.FrameworkProcessor.run()`
    #' @param dependencies (list[str]): A list of paths to directories (absolute or relative)
    #'              with any additional libraries that will be exported to the container
    #'              (default: []). See the ``dependencies`` argument in
    #'              `sagemaker.processing.FrameworkProcessor.run()`.
    #' @param git_config (dict[str, str]): Git configurations used for cloning files. See the
    #'              `git_config` argument in `sagemaker.processing.FrameworkProcessor.run()`.
    #' @param inputs (list[:class:`~sagemaker.processing.ProcessingInput`]): Input files for
    #'              the processing job. These must be provided as
    #'              :class:`~sagemaker.processing.ProcessingInput` objects (default: None).
    #' @param outputs (list[:class:`~sagemaker.processing.ProcessingOutput`]): Outputs for
    #'              the processing job. These can be specified as either path strings or
    #'              :class:`~sagemaker.processing.ProcessingOutput` objects (default: None).
    #' @param arguments (list[str]): A list of string arguments to be passed to a
    #'              processing job (default: None).
    #' @param job_name (str): Processing job name. If not specified, the processor generates
    #'              a default job name, based on the base job name and current timestamp.
    #' @return Returns a RunArgs object.
    get_run_args = function(code,
                            source_dir=NULL,
                            dependencies=NULL,
                            git_config=NULL,
                            inputs=NULL,
                            outputs=NULL,
                            arguments=NULL,
                            job_name=NULL){
      # When job_name is None, the job_name to upload code (+payload) will
      # differ from job_name used by run().
      ll = private$.pack_and_upload_code(
        code, source_dir, dependencies, git_config, job_name, inputs
      )
      names(ll) = c("s3_runproc_sh", "inputs", "job_name")

      return(RunArgs$new(
        ll$s3_runproc_sh,
        inputs=ll$inputs,
        outputs=outputs,
        arguments=arguments)
      )
    },

    #' @description Runs a processing job.
    #' @param code (str): This can be an S3 URI or a local path to a file with the
    #'              framework script to run.Path (absolute or relative) to the local
    #'              Python source file which should be executed as the entry point
    #'              to training. When `code` is an S3 URI, ignore `source_dir`,
    #'              `dependencies, and `git_config`. If ``source_dir`` is specified,
    #'              then ``code`` must point to a file located at the root of ``source_dir``.
    #' @param source_dir (str): Path (absolute, relative or an S3 URI) to a directory
    #'              with any other processing source code dependencies aside from the entry
    #'              point file (default: None). If ``source_dir`` is an S3 URI, it must
    #'              point to a tar.gz file. Structure within this directory are preserved
    #'              when processing on Amazon SageMaker (default: None).
    #' @param dependencies (list[str]): A list of paths to directories (absolute
    #'              or relative) with any additional libraries that will be exported
    #'              to the container (default: []). The library folders will be
    #'              copied to SageMaker in the same folder where the entrypoint is
    #'              copied. If 'git_config' is provided, 'dependencies' should be a
    #'              list of relative locations to directories with any additional
    #'              libraries needed in the Git repo (default: None).
    #' @param git_config (dict[str, str]): Git configurations used for cloning
    #'              files, including ``repo``, ``branch``, ``commit``,
    #'              ``2FA_enabled``, ``username``, ``password`` and ``token``. The
    #'              ``repo`` field is required. All other fields are optional.
    #'              ``repo`` specifies the Git repository where your training script
    #'              is stored. If you don't provide ``branch``, the default value
    #'              'master' is used. If you don't provide ``commit``, the latest
    #'              commit in the specified branch is used.
    #'              results in cloning the repo specified in 'repo', then
    #'              checkout the 'master' branch, and checkout the specified
    #'              commit.
    #'              ``2FA_enabled``, ``username``, ``password`` and ``token`` are
    #'              used for authentication. For GitHub (or other Git) accounts, set
    #'              ``2FA_enabled`` to 'True' if two-factor authentication is
    #'              enabled for the account, otherwise set it to 'False'. If you do
    #'              not provide a value for ``2FA_enabled``, a default value of
    #'              'False' is used. CodeCommit does not support two-factor
    #'              authentication, so do not provide "2FA_enabled" with CodeCommit
    #'              repositories.
    #'              For GitHub and other Git repos, when SSH URLs are provided, it
    #'              doesn't matter whether 2FA is enabled or disabled; you should
    #'              either have no passphrase for the SSH key pairs, or have the
    #'              ssh-agent configured so that you will not be prompted for SSH
    #'              passphrase when you do 'git clone' command with SSH URLs. When
    #'              HTTPS URLs are provided: if 2FA is disabled, then either token
    #'              or username+password will be used for authentication if provided
    #'              (token prioritized); if 2FA is enabled, only token will be used
    #'              for authentication if provided. If required authentication info
    #'              is not provided, python SDK will try to use local credentials
    #'              storage to authenticate. If that fails either, an error message
    #'              will be thrown.
    #'              For CodeCommit repos, 2FA is not supported, so '2FA_enabled'
    #'              should not be provided. There is no token in CodeCommit, so
    #'              'token' should not be provided too. When 'repo' is an SSH URL,
    #'              the requirements are the same as GitHub-like repos. When 'repo'
    #'              is an HTTPS URL, username+password will be used for
    #'              authentication if they are provided; otherwise, python SDK will
    #'              try to use either CodeCommit credential helper or local
    #'              credential storage for authentication.
    #' @param inputs (list[:class:`~sagemaker.processing.ProcessingInput`]): Input files for
    #'              the processing job. These must be provided as
    #'              :class:`~sagemaker.processing.ProcessingInput` objects (default: None).
    #' @param outputs (list[:class:`~sagemaker.processing.ProcessingOutput`]): Outputs for
    #'              the processing job. These can be specified as either path strings or
    #'              :class:`~sagemaker.processing.ProcessingOutput` objects (default: None).
    #' @param arguments (list[str]): A list of string arguments to be passed to a
    #'              processing job (default: None).
    #' @param wait (bool): Whether the call should wait until the job completes (default: True).
    #' @param logs (bool): Whether to show the logs produced by the job.
    #'              Only meaningful when wait is True (default: True).
    #' @param job_name (str): Processing job name. If not specified, the processor generates
    #'              a default job name, based on the base job name and current timestamp.
    #' @param experiment_config (dict[str, str]): Experiment management configuration.
    #'              Dictionary contains three optional keys:
    #'              'ExperimentName', 'TrialName', and 'TrialComponentDisplayName'.
    #' @param kms_key (str): The ARN of the KMS key that is used to encrypt the
    #'              user code file (default: None).
    run = function(code,
                   source_dir=NULL,
                   dependencies=NULL,
                   git_config=NULL,
                   inputs=NULL,
                   outputs=NULL,
                   arguments=NULL,
                   wait=TRUE,
                   logs=TRUE,
                   job_name=NULL,
                   experiment_config=NULL,
                   kms_key=NULL){
      ll = private$.pack_and_upload_code(
        code, source_dir, dependencies, git_config, job_name, inputs)
      names(ll) = c("s3_runproc_sh", "inputs", "job_name")
      # Submit a processing job.
      super$run(
        code=s3_runproc_sh,
        inputs=inputs,
        outputs=outputs,
        arguments=arguments,
        wait=wait,
        logs=logs,
        job_name=job_name,
        experiment_config=experiment_config,
        kms_key=kms_key)
    }
  ),

  private = list(

    # Instantiate the Framework Estimator that backs this Processor
    .create_estimator = function(entry_point="",
                                 source_dir=NULL,
                                 dependencies=NULL,
                                 git_config=NULL){
      return(self$estimator_cls(
        framework_version=self$framework_version,
        py_version=self.py_version,
        entry_point=entry_point,
        source_dir=source_dir,
        dependencies=dependencies,
        git_config=git_config,
        code_location=self$code_location,
        enable_network_isolation=FALSE,  # True -> uploads to input channel. Not what we want!
        image_uri=self$image_uri,
        role=self$role,
        # Estimator instance_count doesn't currently matter to FrameworkProcessor, and the
        # SKLearn Framework Estimator requires instance_type==1. So here we hard-wire it to 1,
        # but if it matters in future perhaps we could take self.instance_count here and have
        # SKLearnProcessor override this function instead:
        instance_count=1,
        instance_type=self$instance_type,
        sagemaker_session=self$sagemaker_session,
        debugger_hook_config=FALSE,
        disable_profiler=TRUE)
      )
    },

    # Pack local code bundle and upload to Amazon S3.
    .pack_and_upload_code = function(code,
                                     source_dir,
                                     dependencies,
                                     git_config,
                                     job_name,
                                     inputs){
      if (startsWith(code, "s3://"))
        return(list(code, inputs, job_name))

      if (is.null(job_name))
        job_name = private$.generate_current_job_name(job_name)

      estimator = private$.upload_payload(
        code,
        source_dir,
        dependencies,
        git_config,
        job_name)
      inputs = private$.patch_inputs_with_payload(
        inputs,
        estimator$.hyperparameters[["sagemaker_submit_directory"]])
      local_code = get_config_value("local.local_code", self$sagemaker_session$config)
      if (self$sagemaker_session$local_mode && local_code)
        RuntimeError$new(
          "SageMaker Processing Local Mode does not currently support 'local code' mode. ",
          "Please use a LocalSession created with disable_local_code=TRUE, or leave ",
          "sagemaker_session unspecified when creating your Processor to have one set up ",
          "automatically."
        )

      # Upload the bootstrapping code as s3://.../jobname/source/runproc.sh.
      entrypoint_s3_uri = gsub(estimator$uploaded_code$s3_prefix,
        "sourcedir.tar.gz",
        "runproc.sh"
      )
      script = estimator$uploaded_code$script_name
      s3_runproc_sh = S3Uploader$new()$upload_string_as_file_body(
        private$.generate_framework_script(script),
        desired_s3_uri=entrypoint_s3_uri,
        sagemaker_session=self$sagemaker_session
      )

      LOGGER$info("runproc.sh uploaded to %s", s3_runproc_sh)

      return(list(s3_runproc_sh, inputs, job_name))
    },

    # Generate the framework entrypoint file (as text) for a processing job.
    # This script implements the "framework" functionality for setting up your code:
    #   Untar-ing the sourcedir bundle in the ```code``` input; installing extra
    # runtime dependencies if specified; and then invoking the ```command``` and
    # ```code``` configured for the job.
    # Args:
    #   user_script (str): Relative path to ```code``` in the source bundle
    # - e.g. 'process.py'.
    .generate_framework_script = function(user_script){
      return(sprintf(
        paste(
          c('#!/bin/bash',
            'cd /opt/ml/pro,cessing/input/code/',
            'tar -xzf sourcedir.tar.gz',
            '# Exit on any error. SageMaker uses error code to mark failed job.',
            'set -e',
            'if [[ -f \'requirements.txt\' ]]; then',
            '    # Some py3 containers has typing, which may breaks pip install',
            '    pip uninstall --yes typing',
            '    pip install -r requirements.txt',
            'fi',
            '%s %s "$@"'), collapse ="\n"),
        paste(self$command, collapse = " "),
        user_script)
      )
    },

    # Upload payload sourcedir.tar.gz to S3.
    .upload_payload = function(entry_point,
                               source_dir,
                               dependencies,
                               git_config,
                               job_name){
      # A new estimator instance is required, because each call to ScriptProcessor.run() can
      # use different codes.
      estimator = private$.create_estimator(
        entry_point=entry_point,
        source_dir=source_dir,
        dependencies=dependencies,
        git_config=git_config)

      estimator$.prepare_for_training(job_name=job_name)
      LOGGER$info(
        "Uploaded %s to %s",
        estimator$source_dir,
        estimator$.hyperparameters[["sagemaker_submit_directory"]])
      return(estimator)
    },

    # Add payload sourcedir.tar.gz to processing input.
    # This method follows the same mechanism in ScriptProcessor.
    .patch_inputs_with_payload = function(inputs,
                                          s3_payload){
      # Follow the exact same mechanism that ScriptProcessor does, which
      # is to inject the S3 code artifact as a processing input. Note that
      # framework processor take-over /opt/ml/processing/input/code for
      # sourcedir.tar.gz, and let ScriptProcessor to place runproc.sh under
      # /opt/ml/processing/input/{self._CODE_CONTAINER_INPUT_NAME}.
      #
      # See:
      # - ScriptProcessor._CODE_CONTAINER_BASE_PATH, ScriptProcessor._CODE_CONTAINER_INPUT_NAME.
      # - https://github.com/aws/sagemaker-python-sdk/blob/ \
      #   a7399455f5386d83ddc5cb15c0db00c04bd518ec/src/sagemaker/processing.py#L425-L426

      if (is.null(inputs))
        inputs = list()
        inputs = c(inputs,
          ProcessingInput$new(
            input_name="code",
            source=s3_payload,
            destination="/opt/ml/processing/input/code/")
          )
      return(inputs)
    },

    # Framework processor override for setting processing job entrypoint.
    # Args:
    #   command ([str]): Ignored in favor of self.framework_entrypoint_command
    # user_script_name (str): A filename with an extension.
    .set_entrypoint = function(command,
                               user_script_name){
      user_script_location = fs::path(
        self$.CODE_CONTAINER_BASE_PATH, self$.CODE_CONTAINER_INPUT_NAME, user_script_name
      )
      self$entrypoint = c(self$framework_entrypoint_command, user_script_location)
    }
  )
)

