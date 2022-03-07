# sagemaker.common 0.2.0
## Architecture change:
* Import `clarify.R` file from package `sagemaker.mlcore` to reduce `sagemaker.mlcore` size from `5Mb` to `3.7Mb`.

## Minor Change:
* `TextConfig` class uses `ascii-code` instead of characters due to `non-ascii` characters come in supported languages.

# sagemaker.common 0.1.1
## Bug Fix:
* `ProcessingJob` method `prepare_app_specification`, `prepare_output_config` returns config list

# sagemaker.common 0.1.0

* Added a `NEWS.md` file to track changes to the package.
