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
