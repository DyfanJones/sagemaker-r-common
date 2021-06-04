# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/src/sagemaker/deprecations.py


V2_URL = "https://sagemaker.readthedocs.io/en/stable/v2.html"

.warn <- function(msg){
  full_msg = sprintf("%s to align with python sagemaker>=2.\nSee: %s for details.", msg, V2_URL)
  warning(full_msg, call. = F)
  LOGGER$warn(full_msg)
}

#' @title Raise a warning for a no-op in sagemaker>=2
#' @param phrase: the prefix phrase of the warning message.
#' @export
removed_warning <- function(phrase){
  .warn(sprintf("%s is a no-op", phrase))
}

#' @title Raise a warning for a rename in sagemaker>=2
#' @param phrase: the prefix phrase of the warning message.
#' @export
renamed_warning <- function(phrase){
  .warn(sprintf("%s has been renamed", phrase))
}

#' @title Checks if the deprecated argument is in kwargs
#' @description Raises warning, if present.
#' @param old_name: name of deprecated argument
#' @param new_name: name of the new argument
#' @param value: value associated with new name, if supplied
#' @param kwargs: keyword arguments dict
#' @return value of the keyword argument, if present
#' @export
renamed_kwargs <- function(old_name,
                           new_name,
                           value,
                           kwargs){
  if(old_name %in% names(renamed_kwargs)){
    value = kwargs[[old_name]] %||% value
    eval.parent(substitute({kwargs[[new_name]] = value}))
    renamed_warning(old_name)}
  return(value)
}

#' @title Checks if the deprecated argument is populated.
#' @description Raises warning, if not None.
#' @param name: name of deprecated argument
#' @param arg: the argument to check
#' @export
remove_arg <- function(name,
                       arg = NULL){
  if(!is.null(arg)){
    removed_warning(name)
  }
}

#' @title Checks if the deprecated argument is in kwargs
#' @description Raises warning, if present.
#' @param name: name of deprecated argument
#' @param kwargs: keyword arguments dict
#' @export
removed_kwargs <- function(name,
                           kwargs){
  if (name %in% names(kwargs))
    removed_warning(name)
}

#' @title Wrap a function with a deprecation warning.
#' @param func: Function to wrap in a deprecation warning.
#' @param name: The name that has been deprecated.
#' @return The modified function
#' @export
deprecated_function <- function(func, name){
  deprecate <- function(...){
    renamed_warning(sprintf("The %s", name))
    return(do.call(func, list(...)))
  }
  return(deprecate)
}
