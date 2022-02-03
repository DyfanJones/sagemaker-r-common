#' @import R6
#' @importFrom utils getFromNamespace help
#' @importFrom urltools url_parse

`%||%` <- function(x, y) if (is.null(x)) return(y) else return(x)

get_aws_env <- function(x) {
  x <- Sys.getenv(x)
  if (nchar(x) == 0) return(NULL) else return(x)
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

pkg_name = function(){
  env <- topenv(environment())
  get0(".packageName", envir = env, inherits = FALSE)
}

parse_url = function(url){
  url = ifelse(is.null(url) | is.logical(url) , "", url)
  url = ifelse(grepl("/", url), url, sprintf("/%s", url))
  urltools::url_parse(url)
}
