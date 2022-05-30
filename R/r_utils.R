#' @import R6
#' @import sagemaker.core
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

# ascii code converter developed from:
# https://www.r-bloggers.com/2011/03/ascii-code-table-in-r/
str_to_ascii_code <- function(str) {
  lapply(str, function(x) strtoi(charToRaw(x),16L))
}

ascii_code_to_str <- function(obj){
  vapply(obj, function(x) {rawToChar(as.raw(x))}, FUN.VALUE = character(1))
}

listenv.extend = function(x, y){
  lapply(1:length(y), function(i){x[[length(x) + 1]] <- y[[i]]})
  return(invisible(NULL))
}
listenv.append = function (x, y) {
  x[[length(x) + 1]] <- y
}

modifyListenv <- function (x, val, keep.null = FALSE) {
  stopifnot(
    inherits(x, "listenv") || is.list(x),
    inherits(val, "listenv") || is.list(val)
  )
  xnames <- names(x)
  vnames <- names(val)[nzchar(names(val))]
  if (keep.null) {
    for (v in vnames) {
      if (v %in% xnames
          && is.list(x[[v]])
          && (is.list(val[[v]]) || inherits(val[[v]], "listenv"))) {
        x[v] <- list(modifyListenv(x[[v]], val[[v]], keep.null = keep.null))
      } else if (v %in% xnames
                 && inherits(x[[v]], "listenv")
                 && (is.list(val[[v]]) || inherits(val[[v]], "listenv"))) {
        modifyListenv(x[[v]], val[[v]], keep.null = keep.null)
      } else {
        x[v] <- list(val[[v]])
      }
    }
  } else {
    for (v in vnames) {
      if (v %in% xnames
          && is.list(x[[v]])
          && (is.list(val[[v]]) || inherits(val[[v]], "listenv"))) {
        x[[v]] <- modifyListenv(x[[v]], val[[v]], keep.null = keep.null)
      } else if (v %in% xnames
                 && inherits(x[[v]], "listenv")
                 && (is.list(val[[v]]) || inherits(val[[v]], "listenv"))) {
        modifyListenv(x[[v]], val[[v]], keep.null = keep.null)
      } else {
        x[[v]] <- val[[v]]
      }
    }
  }
  return(x)
}

get_region <- pkg_method("get_region", "paws.common")
