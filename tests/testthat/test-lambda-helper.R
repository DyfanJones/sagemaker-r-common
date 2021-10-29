BUCKET_NAME = "mybucket"
REGION = "us-west-2"
LAMBDA_ARN = "arn:aws:lambda:us-west-2:123456789012:function:test_function"
FUNCTION_NAME = "test_function"
EXECUTION_ROLE = "arn:aws:iam::123456789012:role/execution_role"
SCRIPT = "test_function.py"
HANDLER = "test_function.lambda_handler"
ZIPPED_CODE_DIR = "code.zip"
S3_BUCKET = "sagemaker-us-west-2-123456789012"
S3_KEY = sprintf("%s/%s/%s","lambda", FUNCTION_NAME, "code")
# DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")

paws_mock = Mock$new(name = "PawsSession", region_name = REGION)
sagemaker_session = Mock$new(
  name="Session",
  paws_credentials=paws_mock,
  paws_region_name=REGION,
  config=NULL,
  local_mode=FALSE,
  s3 = NULL
)

describe = list("ModelArtifacts"= list("S3ModelArtifacts"= "s3://m/m.tar.gz"))
describe_compilation = list("ModelArtifacts"= list("S3ModelArtifacts"= "s3://m/model_c5.tar.gz"))
sagemaker_session$sagemaker$describe_training_job = Mock$new()$return_value(describe)
sagemaker_session$wait_for_compilation_job = Mock$new()$return_value(describe_compilation)
sagemaker_session$default_bucket = Mock$new(name="default_bucket")$return_value(BUCKET_NAME, .min_var = 0)
sagemaker_session$wait_for_job = Mock$new()$return_value(NULL)
sagemaker_session$train <- Mock$new()$return_value(list(TrainingJobArn = "sagemaker-chainer-dummy"))
sagemaker_session$logs_for_job <- Mock$new()$return_value(NULL)
sagemaker_session$create_model <- Mock$new()$return_value("sagemaker-chainer")
sagemaker_session$endpoint_from_production_variants <- Mock$new()$return_value("sagemaker-chainer-endpoint")
sagemaker_session$s3$put_object <- Mock$new()$return_value(NULL)
sagemaker_session$call_args("compile_model")

s3_client =  Mock$new(region_name = sagemaker_session$paws_region_name)
s3_client$call_args("put_object")
sagemaker_session$s3 = s3_client

lambda_client =  Mock$new(region_name = sagemaker_session$paws_region_name)
lambda_client$call_args("create_function")
lambda_client$call_args("update_function_code")
sagemaker_session$lambda_client = lambda_client

test_that("test lambda object with arn happycase", {
  lambda_obj = Lambda$new(function_arn=LAMBDA_ARN, session=sagemaker_session)
  expect_equal(lambda_obj$function_arn, LAMBDA_ARN)
})

test_that("test lambda object with name happycase1", {
  lambda_obj = Lambda$new(
    function_name=FUNCTION_NAME,
    execution_role_arn=EXECUTION_ROLE,
    script=SCRIPT,
    handler=HANDLER,
    session=sagemaker_session
  )

  expect_equal(lambda_obj$function_name, FUNCTION_NAME)
  expect_equal(lambda_obj$execution_role_arn, EXECUTION_ROLE)
  expect_equal(lambda_obj$script, SCRIPT)
  expect_equal(lambda_obj$handler, HANDLER)
  expect_equal(lambda_obj$timeout, 120)
  expect_equal(lambda_obj$memory_size, 128)
  expect_equal(lambda_obj$runtime, "python3.8")
})

test_that("test lambda object with name happycase2", {
  lambda_obj = Lambda$new(
    function_name=FUNCTION_NAME,
    execution_role_arn=EXECUTION_ROLE,
    zipped_code_dir=ZIPPED_CODE_DIR,
    s3_bucket=S3_BUCKET,
    handler=HANDLER,
    session=sagemaker_session
  )

  expect_equal(lambda_obj$function_name, FUNCTION_NAME)
  expect_equal(lambda_obj$execution_role_arn, EXECUTION_ROLE)
  expect_equal(lambda_obj$zipped_code_dir, ZIPPED_CODE_DIR)
  expect_equal(lambda_obj$s3_bucket, S3_BUCKET)
  expect_equal(lambda_obj$handler, HANDLER)
  expect_equal(lambda_obj$timeout, 120)
  expect_equal(lambda_obj$memory_size, 128)
  expect_equal(lambda_obj$runtime, "python3.8")
})

test_that("test lambda object with no name and arn error", {
  expect_error(
    Lambda$new(
      execution_role_arn=EXECUTION_ROLE,
      script=SCRIPT,
      handler=HANDLER,
      session=sagemaker_session
    ),
    "Either function_arn or function_name must be provided"
  )
})

test_that("test lambda object no code error", {
  expect_error(
    Lambda$new(
      function_name=FUNCTION_NAME,
      execution_role_arn=EXECUTION_ROLE,
      handler=HANDLER,
      session=sagemaker_session
    ),
    "Either zipped_code_dir or script must be provided"
  )
})

test_that("test lambda object both script and code dir error", {
  expect_error(
    Lambda$new(
      function_name=FUNCTION_NAME,
      execution_role_arn=EXECUTION_ROLE,
      script=SCRIPT,
      zipped_code_dir=ZIPPED_CODE_DIR,
      handler=HANDLER,
      session=sagemaker_session
    ),
    "Provide either script or zipped_code_dir, not both."
  )
})

test_that("test lambda object no handler error", {
  expect_error(
    Lambda$new(
      function_name=FUNCTION_NAME,
      execution_role_arn=EXECUTION_ROLE,
      zipped_code_dir=ZIPPED_CODE_DIR,
      s3_bucket=S3_BUCKET,
      session=sagemaker_session
    ),
    "Lambda handler must be provided."
  )
})

test_that("test lambda object no execution role error", {
  expect_error(
    Lambda$new(
      function_name=FUNCTION_NAME,
      zipped_code_dir=ZIPPED_CODE_DIR,
      s3_bucket=S3_BUCKET,
      handler=HANDLER,
      session=sagemaker_session
    ),
    "execution_role_arn must be provided."
  )
})

# helper function
.zip_lambda_code = function(script){
  temp_file = fs::file_temp(ext = "zip")
  on.exit(unlink(temp_file))
  zip::zip(temp_file, script)
  return(readBin(temp_file, "raw", n = fs::file_size(temp_file)))
}

test_that("test create lambda happycase1", {
  fs::file_touch(SCRIPT)
  lambda_obj = Lambda$new(
    function_name=FUNCTION_NAME,
    execution_role_arn=EXECUTION_ROLE,
    script=SCRIPT,
    handler=HANDLER,
    session=sagemaker_session
  )

  lambda_obj$create()

  code = list(ZipFile=.zip_lambda_code(SCRIPT))

  expect_equal(
    sagemaker_session$lambda_client$create_function(),
    list(
      FunctionName = FUNCTION_NAME,
      Runtime="python3.8",
      Handler=HANDLER,
      Role=EXECUTION_ROLE,
      Code=code,
      Timeout=120,
      MemorySize=128
    )
  )

  fs::file_delete(SCRIPT)
})

test_that("test create lambda happycase2", {
  zip::zip(ZIPPED_CODE_DIR, fs::file_touch(SCRIPT))
  lambda_obj = Lambda$new(
    function_name=FUNCTION_NAME,
    execution_role_arn=EXECUTION_ROLE,
    zipped_code_dir=ZIPPED_CODE_DIR,
    s3_bucket=S3_BUCKET,
    handler=HANDLER,
    session=sagemaker_session,
  )

  lambda_obj$create()

  code = list("S3Bucket"=lambda_obj$s3_bucket, "S3Key"=S3_KEY)

  expect_equal(
    sagemaker_session$lambda_client$create_function(),
    list(
      FunctionName = FUNCTION_NAME,
      Runtime="python3.8",
      Handler=HANDLER,
      Role=EXECUTION_ROLE,
      Code=code,
      Timeout=120,
      MemorySize=128
    )
  )

  fs::file_delete(c(SCRIPT, ZIPPED_CODE_DIR))
})

test_that("test create lambda no function name_error",{
  zip::zip(ZIPPED_CODE_DIR, fs::file_touch(SCRIPT))
  lambda_obj = Lambda$new(
    function_arn=LAMBDA_ARN,
    execution_role_arn=EXECUTION_ROLE,
    zipped_code_dir=ZIPPED_CODE_DIR,
    s3_bucket=S3_BUCKET,
    handler=HANDLER,
    session=sagemaker_session
  )

  expect_error(
    lambda_obj$create(),
    "FunctionName must be provided to create a Lambda function"
  )
  fs::file_delete(c(SCRIPT, ZIPPED_CODE_DIR))
})

test_that("test create lambda client error",{
  zip::zip(ZIPPED_CODE_DIR, fs::file_touch(SCRIPT))
  lambda_obj = Lambda$new(
    function_name=FUNCTION_NAME,
    execution_role_arn=EXECUTION_ROLE,
    zipped_code_dir=ZIPPED_CODE_DIR,
    s3_bucket=S3_BUCKET,
    handler=HANDLER,
    session=sagemaker_session
  )

  sagemaker_session$lambda_client$create_function = Mock$new()$side_effect(
    function(...) stop(structure(list(message = "Function already exists"), class = c("error", "condition")))
  )

  expect_error(
    lambda_obj$create(),
    "Function already exists"
  )
  fs::file_delete(c(SCRIPT, ZIPPED_CODE_DIR))
})

test_that("test update lambda happycase1",{
  fs::file_touch(SCRIPT)
  lambda_obj = Lambda$new(
    function_name=FUNCTION_NAME,
    execution_role_arn=EXECUTION_ROLE,
    script=SCRIPT,
    handler=HANDLER,
    session=sagemaker_session
  )

  lambda_obj$update()

  expect_equal(
    sagemaker_session$lambda_client$update_function_code(),
    list(
      FunctionName=FUNCTION_NAME,
      ZipFile=.zip_lambda_code(SCRIPT)
    )
  )

  fs::file_delete(SCRIPT)
})

test_that("test update lambda happycase2",{
  zip::zip(ZIPPED_CODE_DIR, fs::file_touch(SCRIPT))
  lambda_obj = Lambda$new(
    function_arn=LAMBDA_ARN,
    execution_role_arn=EXECUTION_ROLE,
    zipped_code_dir=ZIPPED_CODE_DIR,
    s3_bucket=S3_BUCKET,
    handler=HANDLER,
    session=sagemaker_session
  )

  lambda_obj$update()

  expect_equal(
    sagemaker_session$lambda_client$update_function_code(),
    list(
      FunctionName=LAMBDA_ARN,
      S3Bucket=S3_BUCKET,
      S3Key=character(0)
    )
  )

  fs::file_delete(c(SCRIPT, ZIPPED_CODE_DIR))
})

test_that("test invoke lambda happycase",{
  lambda_obj = Lambda$new(function_arn=LAMBDA_ARN, session=sagemaker_session)

  lambda_obj$invoke()

  expect_error(
    lambda_obj$update(),
    "Cannot update code"
  )

  fs::file_delete(SCRIPT)
})
