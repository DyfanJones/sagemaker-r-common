# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/tests/unit/test_utils.py

BUCKET_WITHOUT_WRITING_PERMISSION = "s3://bucket-without-writing-permission"

NAME = "base_name"
BUCKET_NAME = "some_bucket"

test_that("test get config value",{
  config = list("local"=list("region_name"="us-west-2", "port"="123"), "other"=list("key"=1))

  expect_equal(get_config_value("local.region_name", config), "us-west-2")
  expect_equal(get_config_value("local", config), list(
    "region_name"="us-west-2",
    "port"="123")
  )

  expect_null(get_config_value("does_not.exist", config))
  expect_null(get_config_value("other.key", NULL))
})

test_that("test get short version", {
  expect_equal(get_short_version("1.13.1"), "1.13")
  expect_equal(get_short_version("1.13"), "1.13")
})

test_that("test name from image", {
  image = "image:latest"
  max_length = 32
  out = name_from_image(image, max_length=max_length)
  expect_true(nchar(out) < max_length)
})

test_that("test name from base", {
  out = name_from_base(NAME, short=F)
  expect_true(grepl("^(.+)-(\\d{4}-\\d{2}-\\d{2}-\\d{2}-\\d{2}-\\d{2}-\\d{3})", out))
})

test_that("test name from base short", {
  out = name_from_base(NAME, short=T)
  expect_true(grepl("^(.+)-(\\d{6}-\\d{4})", out))
})

test_that("test unique name from base", {
  expect_true(grepl("base-\\d{10}-[a-f0-9]{4}", unique_name_from_base("base")))
})

test_that("test unique name from base truncated", {
  expect_true(grepl("real-\\d{10}-[a-f0-9]{4}",
    unique_name_from_base("really-long-name", max_length=20)))
})

test_that("test base from name", {
  name = "mxnet-training-2020-06-29-15-19-25-475"
  expect_equal(base_from_name(name), "mxnet-training")

  name = "sagemaker-pytorch-200629-1611"
  expect_equal(base_from_name(name), "sagemaker-pytorch")
})

MESSAGE = "message"
STATUS = "status"
TRAINING_JOB_DESCRIPTION_1 = list(
  "SecondaryStatusTransitions"=list(list("StatusMessage"=MESSAGE, "Status"=STATUS))
)
TRAINING_JOB_DESCRIPTION_2 = list(
  "SecondaryStatusTransitions"=list(list("StatusMessage"="different message", "Status"=STATUS))
)

TRAINING_JOB_DESCRIPTION_EMPTY = list("SecondaryStatusTransitions"=list())


test_that("test secondary training status changed true", {
  changed = secondary_training_status_changed(
    TRAINING_JOB_DESCRIPTION_1, TRAINING_JOB_DESCRIPTION_2
  )
  expect_true(changed)
})

test_that("test secondary training status changed false", {
  changed = secondary_training_status_changed(
    TRAINING_JOB_DESCRIPTION_1, TRAINING_JOB_DESCRIPTION_1
  )
  expect_false(changed)
})

test_that("test secondary training status changed prev missing", {
  changed = secondary_training_status_changed(TRAINING_JOB_DESCRIPTION_1, list())
  expect_true(changed)
})

test_that("test secondary training status changed prev none", {
  changed = secondary_training_status_changed(TRAINING_JOB_DESCRIPTION_1, NULL)
  expect_true(changed)
})

test_that("test secondary training status changed current missing", {
  changed = secondary_training_status_changed(list(), TRAINING_JOB_DESCRIPTION_1)
  expect_false(changed)
})

test_that("test secondary training status changed empty", {
  changed = secondary_training_status_changed(
    TRAINING_JOB_DESCRIPTION_EMPTY, TRAINING_JOB_DESCRIPTION_1
  )
  expect_false(changed)
})

test_that("test secondary training status message status changed", {
  now = Sys.time()
  TRAINING_JOB_DESCRIPTION_1[["LastModifiedTime"]] = now
  expected = sprintf("%s %s - %s",
    strftime(now, format="%Y-%m-%d %H:%M:%S", tz="UTC"),
    STATUS,
    MESSAGE
  )
  expect_equal(
    secondary_training_status_message(
      TRAINING_JOB_DESCRIPTION_1, TRAINING_JOB_DESCRIPTION_EMPTY
    ),
    expected
  )
})

test_that("test secondary training status message status not changed",{
  now = Sys.time()
  TRAINING_JOB_DESCRIPTION_1[["LastModifiedTime"]] = now
  expected = sprintf("%s %s - %s",
    strftime(now, format="%Y-%m-%d %H:%M:%S", tz="UTC"),
    STATUS,
    MESSAGE
  )
  expect_equal(
    secondary_training_status_message(
      TRAINING_JOB_DESCRIPTION_1, TRAINING_JOB_DESCRIPTION_2
    ),
    expected
  )
})

test_that("test secondary training status message prev missing", {
  now = Sys.time()
  TRAINING_JOB_DESCRIPTION_1[["LastModifiedTime"]] = now
  expected = sprintf("%s %s - %s",
    strftime(now, format="%Y-%m-%d %H:%M:%S", tz="UTC"),
    STATUS,
    MESSAGE
  )
  expect_equal(
    secondary_training_status_message(
      TRAINING_JOB_DESCRIPTION_1, list()
    ),
    expected
  )
})

test_that("test download folder", {
  paws_mock = Mock$new("PawsSession", region_name = "us-east-1")
  paws_mock$call_args("client")
  session = Session$new(paws_session=paws_mock, sagemaker_client=Mock$new())
  s3_mock = Mock$new("s3")
  s3_mock$call_args("get_object", list(Body = charToRaw("dummy")))
  s3_mock$call_args("list_objects_v2", list(
      Contents = list(
        list(Key = "prefix/train/train_data.csv"),
        list(Key = "prefix/train/validation_data.csv")
      ),
      ContinuationToken = character(0)
    )
  )
  session$s3 = s3_mock

  download_folder(BUCKET_NAME, "/prefix","/tmp", session)

  expect_true(file.exists(file.path("/tmp", "prefix")))

  download_folder(BUCKET_NAME, "/prefix/","/tmp", session)

  expect_true(file.exists(file.path("/tmp", "train", "train_data.csv")))
  expect_true(file.exists(file.path("/tmp", "train", "validation_data.csv")))

  fs::file_delete(c(
    file.path("/tmp", "prefix"),
    file.path("/tmp", "train","train_data.csv"),
    file.path("/tmp", "train","validation_data.csv")
    )
  )
})

test_that("test download folder points to single file", {
  paws_mock = Mock$new("PawsSession", region_name = "us-east-1")
  paws_mock$call_args("client")
  session = Session$new(paws_session=paws_mock, sagemaker_client=Mock$new())
  s3_mock = Mock$new("s3")
  s3_mock$call_args("get_object", list(Body = charToRaw("dummy")))
  session$s3 = s3_mock

  download_folder(BUCKET_NAME, "/prefix/train/train_data.csv","/tmp", session)

  expect_true(file.exists(file.path("/tmp", "train_data.csv")))

  fs::file_delete(file.path("/tmp", "train_data.csv"))
})

test_that("test download file", {
  paws_mock = Mock$new("PawsSession", region_name = "us-east-1")
  paws_mock$call_args("client")
  session = Session$new(paws_session=paws_mock, sagemaker_client=Mock$new())
  s3_mock = Mock$new("s3")
  s3_mock$call_args("get_object", list(Body = charToRaw("dummy")))
  session$s3 = s3_mock

  download_file(
    BUCKET_NAME, "/prefix/path/file.tar.gz", "/tmp/file.tar.gz", session
  )

  expect_true(file.exists(file.path("/tmp", "file.tar.gz")))

  fs::file_delete(file.path("/tmp", "file.tar.gz"))
})

test_that("test create tar file with provided path", {
  temp_dir = "dummy"
  dir.create(temp_dir)
  writeLines("dummy", file.path(temp_dir, "file_a"))
  writeLines("dummy", file.path(temp_dir, "file_b"))
  writeLines("dummy", file.path(temp_dir, "file_c"))

  file_list = c(file.path(temp_dir, "file_a"), file.path(temp_dir, "file_b"))

  out = create_tar_file(file_list, target="my/custom/path.tar.gz")

  expect_true(file.exists("my/custom/path.tar.gz"))

  untar(out, exdir = "temp")

  expect_equal(list.files("temp"), basename(file_list))

  fs::file_delete(out)
  fs::dir_delete("temp")
  fs::dir_delete("dummy")
})

test_that("test create tar file with provided path", {
  temp_dir = "dummy"
  dir.create(temp_dir)
  writeLines("dummy", file.path(temp_dir, "file_a"))
  writeLines("dummy", file.path(temp_dir, "file_b"))

  file_list = c(file.path(temp_dir, "file_a"), file.path(temp_dir, "file_b"))

  out = create_tar_file(file_list)

  expect_true(file.exists(out))

  untar(out, exdir = "temp")

  expect_equal(list.files("temp"), basename(file_list))

  fs::file_delete(out)
  fs::dir_delete("temp")
  fs::dir_delete("dummy")
})
