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
  expect_equal(get_short_version("1.13") == "1.13")
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
  s3_mock$call_args("get_object", rawToChar("dummy"))
  session$s3 = s3_mock


})




@patch("os.makedirs")
def test_download_folder(makedirs):
  boto_mock = MagicMock(name="boto_session")
  session = sagemaker.Session(boto_session=boto_mock, sagemaker_client=MagicMock())
s3_mock = boto_mock.resource("s3")

obj_mock = Mock()
s3_mock.Object.return_value = obj_mock

def obj_mock_download(path):
  # Mock the S3 object to raise an error when the input to download_file
  # is a "folder"
  if path in ("/tmp/", os.path.join("/tmp", "prefix")):
  raise botocore.exceptions.ClientError(
    error_response={"Error": {"Code": "404", "Message": "Not Found"}},
    operation_name="HeadObject",
  )
else:
  return Mock()

obj_mock.download_file.side_effect = obj_mock_download

train_data = Mock()
validation_data = Mock()

train_data.bucket_name.return_value = BUCKET_NAME
train_data.key = "prefix/train/train_data.csv"
validation_data.bucket_name.return_value = BUCKET_NAME
validation_data.key = "prefix/train/validation_data.csv"

s3_files = [train_data, validation_data]
s3_mock.Bucket(BUCKET_NAME).objects.filter.return_value = s3_files

# all the S3 mocks are set, the test itself begins now.
sagemaker.utils.download_folder(BUCKET_NAME, "/prefix", "/tmp", session)

obj_mock.download_file.assert_called()
calls = [
  call(os.path.join("/tmp", "train", "train_data.csv")),
  call(os.path.join("/tmp", "train", "validation_data.csv")),
]
obj_mock.download_file.assert_has_calls(calls)
assert s3_mock.Object.call_count == 3

s3_mock.reset_mock()
obj_mock.reset_mock()

# Test with a trailing slash for the prefix.
sagemaker.utils.download_folder(BUCKET_NAME, "/prefix/", "/tmp", session)
obj_mock.download_file.assert_called()
obj_mock.download_file.assert_has_calls(calls)
assert s3_mock.Object.call_count == 2

