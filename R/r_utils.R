#' @import R6
#' @importFrom utils getFromNamespace help

`%||%` <- function(x, y) if (is.null(x)) return(y) else return(x)

get_aws_env <- function(x) {
  x <- Sys.getenv(x)
  if (nchar(x) == 0) return(NULL) else return(x)
}

#' @title Get methods from other packages
#' @description This function allows to use soft dependencies.
#' @keywords internal
#' @param fun function to export
#' @param pkg package to method from
#' @export
pkg_method <- function(fun, pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(fun,' requires the ', pkg,' package, please install it first and try again',
         call. = F)}
  fun_name <- getFromNamespace(fun, pkg)
  return(fun_name)
}

get_profile_name <- pkg_method("get_profile_name", "paws.common")
get_region <- pkg_method("get_region", "paws.common")

#' @title Checks is R6 is a sub class
#' @param subclass (R6):
#' @param cls (R6):
#' @keywords internal
#' @export
IsSubR6Class <- function(subclass, cls) {
  if(is.null(subclass)) return(NULL)
  if (!is.R6Class(subclass))
    stop("subclass is not a R6ClassGenerator.", call. = F)
  parent <- subclass$get_inherit()
  cls %in% c(subclass$classname, IsSubR6Class(parent))
}

#' @title Write large raw connections in chunks
#' @param obj (raw): raw connection or raw vector
#' @param filename (str):
#' @param chunk_size (int):
#' @keywords internal
#' @export
write_bin <- function(obj,
                      filename,
                      chunk_size = 2^31 - 2) {

  # if readr is available then use readr::write_file else loop writeBin
  if (pkg_env$readr$available){
    # to avoid readr trying to unzip files and causing potential errors
    pos <- regexpr("\\.([[:alnum:]]+)$", filename)
    l = (
      if(pos > -1L)
        list(file = substring(filename, 1, pos-1L), ext = substring(filename, pos + 1L))
      else list(file = filename)
    )
    pkg_env$readr$methods$write_file(obj, l$file)
    file.rename(l$file, paste(l, collapse = "."))
    return(invisible(TRUE))
  }
  base_write_raw(obj, filename, chunk_size)
  return(invisible(TRUE))
}

base_write_raw <- function(obj,
                           filename,
                           chunk_size = 2^31-2){ # Only 2^31 - 1 bytes can be written in a single call
  # Open for reading and appending.
  con <- file(filename, "a+b")
  on.exit(close(con))

  # If R version is 4.0.0 + then don't need to chunk writeBin
  # https://github.com/HenrikBengtsson/Wishlist-for-R/issues/97
  if (getRversion() > R_system_version("4.0.0")){
    writeBin(obj,con)
  } else {
    max_len <- length(obj)
    start <- seq(1, max_len, chunk_size)
    end <- c(start[-1]-1, max_len)

    if (length(start) == 1) {
      writeBin(obj,con)
    } else {
      sapply(seq_along(start), function(i){writeBin(obj[start[i]:end[i]],con)})}
  }
}

#' @title If api call fails retry call
#' @param expr (code): AWS code to rety
#' @param retry (int): number of retries
#' @keywords internal
#' @export
retry_api_call <- function(expr, retry = 5){

  # if number of retries is equal to 0 then retry is skipped
  if (retry == 0) {
    resp <- tryCatch(eval.parent(substitute(expr)),
                     error = function(e) e)
  }

  for (i in seq_len(retry)) {
    resp <- tryCatch(eval.parent(substitute(expr)),
                     error = function(e) e)

    if(inherits(resp, "http_500")){

      # stop retry if statement is an invalid request
      if (grepl("InvalidRequestException", resp)) {stop(resp)}

      backoff_len <- runif(n=1, min=0, max=(2^i - 1))

      message(resp, "Request failed. Retrying in ", round(backoff_len, 1), " seconds...")

      Sys.sleep(backoff_len)
    } else {break}
  }

  if (inherits(resp, "error")) stop(resp)

  resp
}

#' @title Check if list is empty
#' @param obj (list):
#' @keywords internal
#' @export
islistempty = function(obj) {(is.null(obj) || length(obj) == 0)}

#' @title split string
#' @param str (str): string to split
#' @param split (str): string used for splitting.
#' @keywords internal
#' @export
split_str <- function(str, split = ",") unlist(strsplit(str, split = split))

#' @title Format of R6 classes
#' @param self ([R6::R6Class])
#' @keywords internal
#' @export
format_class <- function(self){
  sprintf(
    "<%s at %s>\n",
    class(self)[1],
    data.table::address(self))
}

#' @title Create Enum "like" environments
#' @param ... (obj): parameters to be create into an Enum like environment
#' @param .class (str):
#' @keywords internal
#' @export
Enum <- function(..., .class=NULL) {
  kwargs = list(...)
  env = list2env(kwargs, parent = emptyenv())
  lockEnvironment(env, bindings = TRUE)
  subclass <- Filter(Negate(is.null) ,c(.class, "Enum"))
  class(env) <- c(subclass, class(env))
  return(env)
}

#' @export
print.Enum <- function(x, ...){
  l_env = as.list(x)
  values = paste(names(x), shQuote(unname(l_env)), sep = ": ")
  cat(sprintf("<Enum environment: %s>\n", data.table::address(x)))
  cat("Values:\n")
  cat(paste("  -", values, collapse = "\n"))
}

#' @title Split string from the right
#' @param str : string to be split
#' @param separator (str): Method splits string starting from the right (default `\\.`)
#' @param maxsplit (number): The maxsplit defines the maximum number of splits.
#' @export
rsplit <- function(str, separator="\\.", maxsplit) {
  vec = unlist(strsplit(str, separator))
  len = length(vec)
  px = (length(vec) - maxsplit)
  c(paste(vec[1:px], collapse=separator), vec[(px+1):len])
}

#' @title Check if list is named
#' @param x : object
#' @export
is_list_named = function(x){
  inherits(x, "list") && length(names(x)) > 0
}

paws_error_code <- function(error){
  return(error[["error_response"]][["__type"]] %||% error[["error_response"]][["Code"]])
}

to_str <- function(obj, ...){
  UseMethod("to_str")
}

to_str.default <- function(obj, ...){
  as.character(obj)
}

to_str.list <- function(obj, ...){
  jsonlite::toJSON(obj, auto_unbox = F)
}

to_str.numeric <- function(obj, ...){
  format(obj, scientific = F)
}

# Correctly mimic python append method for list
# Full credit to package rlist: https://github.com/renkun-ken/rlist/blob/2692e064fc7b6cc7fe7079b3762df37bc25b3dbd/R/list.insert.R#L26-L44
list.append = function (.data, ...) {
  if (is.list(.data)) c(.data, list(...)) else c(.data, ..., recursive = FALSE)
}

#' @title Helper function to return help documentation for sagemaker R6 classes.
#' @param cls (R6::R6Class): R6 class
#' @param pkg_name (str): package name to get documentation
#' @export
cls_help = function(cls){
  cls_name = class(cls)[[1]]
  cls_env = tryCatch({
    get(cls_name)$parent_env
  }, error = function(e){
    NULL
  })
  pkg_name = if(is.null(cls_env)) NULL else get0(".packageName", envir = cls_env, inherits = FALSE)
  if(is.null(pkg_name)) {
    utils::help((cls_name))
  } else {
    utils::help((cls_name), (pkg_name))
  }
}

pkg_name = function(){
  env <- topenv(environment())
  get0(".packageName", envir = env, inherits = FALSE)
}
