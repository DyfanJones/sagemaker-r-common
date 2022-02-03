# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/src/sagemaker/drift_check_baselines.py

#' @import R6

#' @title DriftCheckBaselines class
#' @description Accepts drift check baselines parameters for conversion to request dict.
#' @export
DriftCheckBaselines = R6Class("DriftCheckBaselines",
  public = list(

    #' @description Initialize a ``DriftCheckBaselines`` instance and turn parameters into dict.
    #' @param model_statistics (MetricsSource): A metric source object that represents
    #               model statistics (default: None).
    #' @param model_constraints (MetricsSource): A metric source object that represents
    #               model constraints (default: None).
    #' @param model_data_statistics (MetricsSource): A metric source object that represents
    #               model data statistics (default: None).
    #' @param model_data_constraints (MetricsSource): A metric source object that represents
    #               model data constraints (default: None).
    #' @param bias_config_file (FileSource): A file source object that represents bias config
    #               (default: None).
    #' @param bias_pre_training_constraints (MetricsSource):
    #               A metric source object that represents Pre-training constraints (default: None).
    #' @param bias_post_training_constraints (MetricsSource):
    #               A metric source object that represents Post-training constraits (default: None).
    #' @param explainability_constraints (MetricsSource):
    #               A metric source object that represents explainability constraints (default: None).
    #' @param explainability_config_file (FileSource): A file source object that represents
    #               explainability config (default: None).
    initialize = function(model_statistics=NULL,
                          model_constraints=NULL,
                          model_data_statistics=NULL,
                          model_data_constraints=NULL,
                          bias_config_file=NULL,
                          bias_pre_training_constraints=NULL,
                          bias_post_training_constraints=NULL,
                          explainability_constraints=NULL,
                          explainability_config_file=NULL){
      self$model_statistics = model_statistics
      self$model_constraints = model_constraints
      self$model_data_statistics = model_data_statistics
      self$model_data_constraints = model_data_constraints
      self$bias_config_file = bias_config_file
      self$bias_pre_training_constraints = bias_pre_training_constraints
      self$bias_post_training_constraints = bias_post_training_constraints
      self$explainability_constraints = explainability_constraints
      self$explainability_config_file = explainability_config_file
    },

    #' @description Generates a request dictionary using the parameters provided to the class.
    to_request_list = function(){
      drift_check_baselines_request = list()

      model_quality = list()
      model_quality[["Statistics"]] = self$model_statistics$to_request_list()
      model_quality[["Constraints"]] = self$model_constraints$to_request_list()
      if (!islistempty(model_quality))
        drift_check_baselines_request[["ModelQuality"]] = model_quality

      model_data_quality = list()
      model_data_quality[["Statistics"]] = self$model_data_statistics$to_request_list()
      model_data_quality[["Constraints"]] = self$model_data_constraints$to_request_list()
      if (!islistempty(model_data_quality))
        drift_check_baselines_request[["ModelDataQuality"]] = model_data_quality

      bias = list()
      bias[["ConfigFile"]] = self$bias_config_file$to_request_list()
      bias[["PreTrainingConstraints"]] = self$bias_pre_training_constraints$to_request_list()
      bias[["PostTrainingConstraints"]] = self$bias_post_training_constraints$to_request_list()
      if (!islistempty(bias))
        drift_check_baselines_request[["Bias"]] = bias

      explainability = list()
      explainability[["Constraints"]] = self$explainability_constraints$to_request_list()
      explainability[["ConfigFile"]] = self$explainability_config_file$to_request_list()
      if (!islistempty(explainability))
        drift_check_baselines_request[["Explainability"]] = explainability

      return(drift_check_baselines_request)
    }
  ),
  lock_objects=F
)
