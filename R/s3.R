# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/src/sagemaker/s3.py

#' @include utils.R
#' @include r_utils.R

#' @importFrom urltools url_parse
#' @importFrom fs path_join

#' @title validation check of s3 uri
#' @param x (str): character to validate if s3 uri or not
#' @export
is.s3_uri <- function(x) {
  if(is.null(x) || !is.character(x)) return(FALSE)
  regex <- '^s3://[a-z0-9\\.-]+(/(.*)?)?$'
  grepl(regex, x)
}

#' @title split s3 uri
#' @param uri (str): s3 uri to split into bucket and key
#' @export
split_s3_uri <- function(uri) {
  stopifnot(is.s3_uri(uri))
  parsed_s3 <- url_parse(uri)
  return(list(
    bucket = parsed_s3$domain,
    key = parsed_s3$path)
  )
}

#' @title Creates S3 uri paths
#' @description Returns the arguments joined by a slash ("/"), similarly to ``file.path()`` (on Unix).
#'              If the first argument is "s3://", then that is preserved.
#' @param ... : The strings to join with a slash.
#' @return charater: The joined string.
#' @return
#' @export
s3_path_join = function(...){
  args=list(...)
  if(grepl("^s3://", args[[1]])){
    path = trimws(args[2:length(args)], "left", "/")
    path = fs::path_join(c(args[[1]], path))
    return(gsub("s3:/", "s3://", path))
  }

  return(trimws(fs::path_join(args), "left", "/"))
}
