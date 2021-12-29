# Class to mock R6 classes
# used for testing only
Mock <- R6::R6Class("Mock",
  public = list(
    initialize = function(name, ...){
      if(!missing(name)) class(self) <- append(name, class(self))
      args = list(...)
      # dynamically assign public methods
      sapply(names(args), function(i) self[[i]] = args[[i]])
    },
    .call_args = function(name, return_value=NULL, side_effect = NULL){
      self[[name]] = function(..., ..return_value = FALSE){
        args = list(...)

        if(..return_value)
          return(private[[paste0(".",name)]])

        private[[paste0(".",name)]] = args

        if(!is.null(side_effect))
          return(side_effect(...))

        return(return_value)
      }
    }
  ),
  private = list(
    .value=NULL
  ),
  lock_objects = F
)

iter <- function(...) {
  return_value=list(...)
  value <- 1
  function(...) {
    if (value <= length(return_value)){
      item = return_value[[value]]
      value <<- value + 1
      return(item)
    } else {
      return(NULL)
    }
  }
}

mock_fun = function(return_value=NULL, side_effect = NULL){
  input_kwargs = list()
  function(..., ..return_value = FALSE){
    args = list(...)

    if(..return_value)
      return(input_kwargs)

    input_kwargs <<- args

    if(!is.null(side_effect)){
      tmp_fun = function(...) side_effect
      return(tmp_fun(...))
    }
    return(return_value)
  }
}

