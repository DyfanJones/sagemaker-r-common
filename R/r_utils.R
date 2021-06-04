#' @import R6

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
  fun_name <- utils::getFromNamespace(fun, pkg)
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
write_bin <- function(
  obj,
  filename,
  chunk_size = 2L ^ 20L) {

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
  total_size <- length(obj)
  split_vec <- seq(1, total_size, chunk_size)

  con <- file(filename, "a+b")
  on.exit(close(con))

  if (length(split_vec) == 1)
    writeBin(obj,con)
  else
    sapply(split_vec, function(x){writeBin(obj[x:min(total_size,(x+chunk_size-1))],con)})
  invisible(TRUE)
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
#' @param self (R6Class):
#' @keywords internal
#' @export
format_class <- function(self){
  sprintf(
    "<%s::%s at %s>\n",
    getPackageName(),
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

