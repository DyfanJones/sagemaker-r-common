# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/src/sagemaker/model_metrics.py

#' @title ModelMetrics class
#' @description Accepts model metrics parameters for conversion to request dict.
#' @export
ModelMetrics = R6Class("ModelMetrics",
  public = list(

    #' @description Initialize a ``ModelMetrics`` instance and turn parameters into dict.
    #' @param model_statistics (MetricsSource): A metric source object that represents
    #'              model statistics (default: None).
    #' @param model_constraints (MetricsSource): A metric source object that represents
    #'              model constraints (default: None).
    #' @param model_data_statistics (MetricsSource): A metric source object that represents
    #'              model data statistics (default: None).
    #' @param model_data_constraints (MetricsSource): A metric source object that represents
    #'              model data constraints (default: None).
    #' @param bias (MetricsSource): A metric source object that represents bias report
    #'              (default: None).
    #' @param explainability (MetricsSource): A metric source object that represents
    #'              explainability report (default: None).
    #' @param bias_pre_training (MetricsSource): A metric source object that represents
    #'              Pre-training report (default: None).
    #' @param bias_post_training (MetricsSource): A metric source object that represents
    #'              Post-training report (default: None).
    initialize = function(model_statistics=NULL,
                          model_constraints=NULL,
                          model_data_statistics=NULL,
                          model_data_constraints=NULL,
                          bias=NULL,
                          explainability=NULL,
                          bias_pre_training=NULL,
                          bias_post_training=NULL){
      self$model_statistics = model_statistics
      self$model_constraints = model_constraints
      self$model_data_statistics = model_data_statistics
      self$model_data_constraints = model_data_constraints
      self$bias = bias
      self$bias_pre_training = bias_pre_training
      self$bias_post_training = bias_post_training
      self$explainability = explainability
    },

    #' @description Generates a request dictionary using the parameters provided to the class.
    to_request_list = function(){
      model_metrics_request = list()

      model_quality = list()
      model_quality[["Statistics"]] = self.model_statistics._to_request_dict()
      model_quality[["Constraints"]] = self.model_constraints._to_request_dict()
      if (!islistempty(model_quality))
        model_metrics_request[["ModelQuality"]] = model_quality

      model_data_quality = list()
      model_data_quality[["Statistics"]] = self.model_data_statistics._to_request_dict()
      model_data_quality[["Constraints"]] = self.model_data_constraints._to_request_dict()
      if (!islistempty(model_data_quality))
        model_metrics_request[["ModelDataQuality"]] = model_data_quality

      bias = list()
      bias[["Report"]] = self.bias._to_request_dict()
      bias[["PreTrainingReport"]] = self.bias_pre_training._to_request_dict()
      bias[["PostTrainingReport"]] = self.bias_post_training._to_request_dict()
      model_metrics_request[["Bias"]] = bias

      explainability = list()
      explainability[["Report"]] = self.explainability._to_request_dict()
      model_metrics_request[["Explainability"]] = explainability

      return(model_metrics_request)
    }
  ),
  lock_objects=T
)

#' @title MetricsSource class
#' @description Accepts metrics source parameters for conversion to request dict.
#' @export
MetricsSource = R6Class("MetricsSource",
  public = list(

    #' @description Initialize a ``MetricsSource`` instance and turn parameters into dict.
    #' @param content_type (str): Specifies the type of content in S3 URI
    #' @param s3_uri (str): The S3 URI of the metric
    #' @param content_digest (str): The digest of the metric (default: None)
    initialize = function(content_type,
                          s3_uri,
                          content_digest=NULL){
      self$content_type = content_type
      self$s3_uri = s3_uri
      self$content_digest = content_digest
    },

    #' @description Generates a request dictionary using the parameters provided to the class.
    to_request_list = function(){
      metrics_source_request = list("ContentType"=self$content_type, "S3Uri"=self$s3_uri)
      metrics_source_request[["ContentDigest"]] = self$content_digest
      return(metrics_source_request)
    }
  ),
  lock_objects=F
)

#' @title FileSource
#' @description Accepts file source parameters for conversion to request dict.
#' @export
FileSource = R6Class("FileSource",
  public = list(

    #' @description Initialize a ``FileSource`` instance and turn parameters into dict.
    #' @param s3_uri (str): The S3 URI of the metric
    #' @param content_digest (str): The digest of the metric (default: None)
    #' @param content_type (str): Specifies the type of content in S3 URI (default: None)
    initialize = function(s3_uri,
                          content_digest=NULL,
                          content_type=NULL){
      self$content_type = content_type
      self$s3_uri = s3_uri
      self$content_digest = content_digest
    },

    #' @description Generates a request dictionary using the parameters provided to the class.
    to_request_list = function(){
      file_source_request = list("S3Uri"=self$s3_uri)
      file_source_request[["ContentDigest"]] = self$content_digest
      file_source_request[["ContentType"]] = self$content_type
      return(file_source_request)
    }
  ),
  lock_object=F
)
