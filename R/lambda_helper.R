# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/src/sagemaker/session.py

#' @include r_utils.R

#' @import fs
#' @import paws
#' @import R6
#' @importFrom zip zip

#' @title Lambda class
#' @description Contains lambda boto3 wrappers to Create, Update, Delete and Invoke Lambda functions.
#' @export
Lambda = R6Class("Lambda",
  public = list(

    #' @description Constructs a Lambda instance.
    #'              This instance represents a Lambda function and provides methods for updating,
    #'              deleting and invoking the function.
    #'              This class can be used either for creating a new Lambda function or using an existing one.
    #'              When using an existing Lambda function, only the function_arn argument is required.
    #'              When creating a new one the function_name, execution_role_arn and handler arguments
    #'              are required, as well as either script or zipped_code_dir.
    #' @param function_arn (str): The arn of the Lambda function.
    #' @param function_name (str): The name of the Lambda function.
    #'              Function name must be provided to create a Lambda function.
    #' @param execution_role_arn (str): The role to be attached to Lambda function.
    #' @param zipped_code_dir (str): The path of the zipped code package of the Lambda function.
    #' @param s3_bucket (str): The bucket where zipped code is uploaded.
    #'              If not provided, default session bucket is used to upload zipped_code_dir.
    #' @param script (str): The path of Lambda function script for direct zipped upload
    #' @param handler (str): The Lambda handler. The format for handler should be
    #'              file_name.function_name. For ex: if the name of the Lambda script is
    #'              hello_world.py and Lambda function definition in that script is
    #' @param lambda_handler(event, context), the handler should be hello_world.lambda_handler
    #' @param session (sagemaker.session.Session): Session object which manages interactions
    #'              with Amazon SageMaker APIs and any other AWS services needed.
    #'              If not specified, new session is created.
    #' @param timeout (int): Timeout of the Lambda function in seconds. Default is 120 seconds.
    #' @param memory_size (int): Memory of the Lambda function in megabytes. Default is 128 MB.
    #' @param runtime (str): Runtime of the Lambda function. Default is set to python3.8.
    initialize = function(function_arn=NULL,
                          function_name=NULL,
                          execution_role_arn=NULL,
                          zipped_code_dir=NULL,
                          s3_bucket=NULL,
                          script=NULL,
                          handler=NULL,
                          session=NULL,
                          timeout=120,
                          memory_size=128,
                          runtime="python3.8"){
      stopifnot(
        is.null(function_arn) || is.character(function_arn),
        is.null(function_name) || is.character(function_name),
        is.null(execution_role_arn) || is.character(execution_role_arn),
        is.null(zipped_code_dir) || is.character(zipped_code_dir),
        is.null(s3_bucket) || is.character(s3_bucket),
        is.null(script) || is.character(script),
        is.null(handler) || is.character(handler),
        is.null(session) || inherits(session, "Session"),
        is.numeric(timeout) || is.integer(timeout),
        is.numeric(memory_size) || is.integer(memory_size),
        is.character(runtime)
      )
      self$function_arn = function_arn
      self$function_name = function_name
      self$zipped_code_dir = zipped_code_dir
      self$s3_bucket = s3_bucket
      self$script = script
      self$handler = handler
      self$execution_role_arn = execution_role_arn
      self$session = session %||% Session$new()
      self$timeout = timeout
      self$memory_size = memory_size
      self$runtime = runtime
      if (is.null(function_arn) && is.null(function_name))
        ValueError$new("Either function_arn or function_name must be provided.")

      if (!is.null(function_name)){
        if (!is.null(execution_role_arn))
          ValueError$new("execution_role_arn must be provided.")
        if (!is.null(zipped_code_dir) && is.null(script))
          ValueError$new("Either zipped_code_dir or script must be provided.")
        if (!is.null(zipped_code_dir) && !is.null(script))
          ValueError$new("Provide either script or zipped_code_dir, not both.")
        if (is.null(handler))
          ValueError$new("Lambda handler must be provided.")
      }
    },

    #' @description Method to create a lambda function.
    #' @return boto3 response from Lambda's create_function method.
    create = function(){
      lambda_client = self$session$lambda_client %||% paws::lambda(self$session$paws_credentials)

      if (is.null(self$function_name))
        ValueError$new("FunctionName must be provided to create a Lambda function.")

      if (!is.null(self$script)) {
        code = list("ZipFile"=private$.zip_lambda_code(self$script))
      } else {
        bucket = self$s3_bucket %||% self$session$default_bucket()
        key = private$.upload_to_s3(
          function_name=self$function_name,
          zipped_code_dir=self$zipped_code_dir,
          s3_bucket=bucket
        )
        code = list("S3Bucket"=bucket, "S3Key"=key)
      }

      tryCatch(
        response = lambda_client$create_function(
          FunctionName=self$function_name,
          Runtime=self$runtime,
          Handler=self$handler,
          Role=self$execution_role_arn,
          Code=code,
          Timeout=self$timeout,
          MemorySize=self$memory_size
        ),
        error = function(e){
          ValueError$new(e$message)
        }
      )
    },

    #' @description Method to update a lambda function.
    #' @return: paws response from Lambda's update_function method.
    update = function(){
      lambda_client = self$session$lambda_client %||% paws::lambda(self$session$paws_credentials)
      if (!is.null(self$script)){
        tryCatch({
          response = lambda_client$update_function_code(
            FunctionName=self$function_name, ZipFile=private$.zip_lambda_code(self$script)
          )
          return(response)
        }, error = function(e){
          ValueError$new(e$message)
        })
      } else {
        tryCatch({
          response = lambda_client$update_function_code(
            FunctionName=(self$function_name %||% self$function_arn),
            S3Bucket=self$s3_bucket,
            S3Key=private$.upload_to_s3(
              function_name=self$function_name,
              zipped_code_dir=self$zipped_code_dir,
              s3_bucket=self$s3_bucket)
          )
          return(response)
        }, error = function(e){
          ValueError$new(e$message)
        })
      }
    },

    #' @description Method to invoke a lambda function.
    #' @return paws response from Lambda's invoke method.
    invoke = function(){
      lambda_client = self$session$lambda_client %||% paws::lambda(self$session$paws_credentials)
      tryCatch({
        response = lambda_client$delete_function(
          FunctionName=self$function_name %||% self$function_arn
        )
        return(response)
      }, error = function(e){
        ValueError$new(e$message)
      })
    }
  ),
  private = list(

    # Upload the zipped code to S3 bucket provided in the Lambda instance.
    # Lambda instance must have a path to the zipped code folder and a S3 bucket to upload
    # the code. The key will lambda/function_name/code and the S3 URI where the code is
    # uploaded is in this format: s3://bucket_name/lambda/function_name/code.
    # Returns: the S3 key where the code is uploaded.
    .upload_to_s3 = function(function_name, zipped_code_dir, s3_bucket){
      key = sprintf("%s/%s/%s", "lambda", function_name, "code")
      obj = readBin(zipped_code_dir, "raw", n = fs::file_size(zipped_code_dir))
      self$session$s3$put_object(obj, s3_bucket, key)
      return(key)
    },

    # This method zips the lambda function script.
    # Lambda function script is provided in the lambda instance and reads that zipped file.
    # Returns: A buffer of zipped lambda function script.
    .zip_lambda_code = function(script){
      temp_file = fs::file_temp(ext = "zip")
      on.exit(unlink(temp_file))
      zip::zip(temp_file, script)
      return(readBin(temp_file, "raw", n = fs::file_size(temp_file)))
    }
  )
)
