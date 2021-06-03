# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/src/sagemaker/metadata_properties.py

#' @import R6

#' @title Accepts metadata properties parameters for conversion to request dict.
#' @keywords internal
#' @export
MetadataProperties = R6Class(
  public = list(

    #' @description Initialize a ``MetadataProperties`` instance and turn parameters into dict.
    #' @param commit_id (str):
    #' @param repository (str):
    #' @param generated_by (str):
    #' @param project_id (str):
    initialize = function(commit_id=NULL,
                          repository=NULL,
                          generated_by=NULL,
                          project_id=NULL){
      self$commit_id = commit_id
      self$repository = repository
      self$generated_by = generated_by
      self$project_id = project_id
    },

    #' @description Generates a request dictionary using the parameters provided to the class.
    to_request_list = function(){
      metadata_properties_request = list()
      metadata_properties_request[["CommitId"]] = self$commit_id
      metadata_properties_request[["Repository"]] = self$repository
      metadata_properties_request[["GeneratedBy"]] = self$generated_by
      metadata_properties_request[["ProjectId"]] = self$project_id
      return(metadata_properties_request)
    },

    #' @description format class
    format = function(){
      format_class(self)
    }
  ),
  lock_objects=F
)
