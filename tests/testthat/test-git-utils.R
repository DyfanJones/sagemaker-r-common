# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/tests/unit/test_git_utils.py

REPO_DIR = "/tmp/repo_dir"
PUBLIC_GIT_REPO = "https://github.com/aws/sagemaker-python-sdk.git"
PUBLIC_BRANCH = "test-branch-git-config"
PUBLIC_COMMIT = "ae15c9d7d5b97ea95ea451e4662ee43da3401d73"
PRIVATE_GIT_REPO_SSH = "git@github.com:testAccount/private-repo.git"
PRIVATE_GIT_REPO = "https://github.com/testAccount/private-repo.git"
PRIVATE_BRANCH = "test-branch"
PRIVATE_COMMIT = "329bfcf884482002c05ff7f44f62599ebc9f445a"
CODECOMMIT_REPO = "https://git-codecommit.us-west-2.amazonaws.com/v1/repos/test-repo/"
CODECOMMIT_REPO_SSH = "ssh://git-codecommit.us-west-2.amazonaws.com/v1/repos/test-repo/"
CODECOMMIT_BRANCH = "master"

rm_temp_dir = function(dir = REPO_DIR){
  if(fs::dir_exists(dir))
    fs::dir_delete(dir)
}

test_that("test git clone repo succeed", {
  skip_on_cran()
  rm_temp_dir()

  mockery::stub(git_clone_repo, "fs::is_file", TRUE)
  mockery::stub(git_clone_repo, "fs::is_dir", TRUE)
  mockery::stub(git_clone_repo, "fs::dir_exists", TRUE)
  mockery::stub(git_clone_repo, "tempfile", REPO_DIR)
  git_config = list("repo"=PUBLIC_GIT_REPO, "branch"=PUBLIC_BRANCH, "commit"=PUBLIC_COMMIT)
  entry_point = "entry_point"
  source_dir = "source_dir"
  dependencies = list("foo", "bar")
  ret = git_clone_repo(git_config, entry_point, source_dir, dependencies)
  expect_equal(ret$entry_point, entry_point)
  expect_equal(ret$source_dir, "/tmp/repo_dir/source_dir")
  expect_equal(ret$dependencies, list("/tmp/repo_dir/foo", "/tmp/repo_dir/bar"))
  fs::dir_delete(REPO_DIR)
})

test_that("test git clone repo repo not provided", {
  skip_on_cran()
  rm_temp_dir()

  git_config = list("branch"=PUBLIC_BRANCH, "commit"=PUBLIC_COMMIT)
  entry_point = "entry_point_that_does_not_exist"
  source_dir = "source_dir"
  dependencies = list("foo", "bar")
  expect_error(
    git_clone_repo(git_config, entry_point, source_dir, dependencies),
    "Please provide a repo for git_config."
  )
})

test_that("test git clone repo git argument wrong format", {
  skip_on_cran()
  rm_temp_dir()

  git_config = list(
    "repo"=PUBLIC_GIT_REPO,
    "branch"=PUBLIC_BRANCH,
    "commit"=PUBLIC_COMMIT,
    "token"=42
  )
  entry_point = "entry_point"
  source_dir = "source_dir"
  dependencies = list("foo", "bar")
  expect_error(
    git_clone_repo(git_config, entry_point, source_dir, dependencies),
    "'token' must be a string."
  )
})

test_that("test git clone repo branch not exist", {
  skip_on_cran()
  rm_temp_dir()

  git_config = list("repo"=PUBLIC_GIT_REPO, "branch"="banana", "commit"=PUBLIC_COMMIT)
  entry_point = "entry_point"
  source_dir = "source_dir"
  dependencies = list("foo", "bar")
  expect_error(git_clone_repo(git_config, entry_point, source_dir, dependencies))
})

test_that("test git clone repo commit not exist", {
  skip_on_cran()
  rm_temp_dir()

  mockery::stub(git_clone_repo, "tempfile", REPO_DIR)
  git_config = list("repo"=PUBLIC_GIT_REPO, "branch"=PUBLIC_BRANCH, "commit"="banana")
  entry_point = "entry_point"
  source_dir = "source_dir"
  dependencies = list("foo", "bar")
  expect_error(git_clone_repo(git_config, entry_point, source_dir, dependencies))
})

test_that("test git clone repo entry point not exist", {
  skip_on_cran()
  rm_temp_dir()

  mockery::stub(git_clone_repo, "fs::is_file", FALSE)
  mockery::stub(git_clone_repo, "fs::is_dir", TRUE)
  mockery::stub(git_clone_repo, "fs::dir_exists", TRUE)
  mockery::stub(git_clone_repo, "tempfile", REPO_DIR)
  git_config = list("repo"=PUBLIC_GIT_REPO, "branch"=PUBLIC_BRANCH, "commit"=PUBLIC_COMMIT)
  entry_point = "entry_point_that_does_not_exist"
  source_dir = "source_dir"
  dependencies = list("foo", "bar")
  expect_error(
    git_clone_repo(git_config, entry_point, source_dir, dependencies),
    "Entry point does not exist in the repo."
  )
})

test_that("test git clone repo source dir not exist", {
  skip_on_cran()
  rm_temp_dir()

  mockery::stub(git_clone_repo, "fs::is_file", TRUE)
  mockery::stub(git_clone_repo, "fs::is_dir", FALSE)
  mockery::stub(git_clone_repo, "fs::dir_exists", TRUE)
  mockery::stub(git_clone_repo, "tempfile", REPO_DIR)
  git_config = list("repo"=PUBLIC_GIT_REPO, "branch"=PUBLIC_BRANCH, "commit"=PUBLIC_COMMIT)
  entry_point = "entry_point"
  source_dir = "source_dir_that_does_not_exist"
  dependencies = list("foo", "bar")
  expect_error(
    git_clone_repo(git_config, entry_point, source_dir, dependencies),
    "Source directory does not exist in the repo."
  )
})

test_that("test git clone repo dependencies not exist", {
  skip_on_cran()
  rm_temp_dir()

  git_config = list("repo"=PUBLIC_GIT_REPO, "branch"=PUBLIC_BRANCH, "commit"=PUBLIC_COMMIT)
  entry_point = "entry_point"
  source_dir = "source_dir"
  dependencies = list("foo", "dep_that_does_not_exist")
  expect_error(
    git_clone_repo(git_config, entry_point, source_dir, dependencies),
    "does not exist in the repo."
  )
})
