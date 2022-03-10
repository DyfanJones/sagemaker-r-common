# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/src/sagemaker/clarify.py

#' @include r_utils.R
#' @include processing.R

#' @import R6
#' @import sagemaker.core
#' @import jsonlite
#' @importFrom stats setNames

#' @title DataConfig Class
#' @description Config object related to configurations of the input and output dataset.
#' @export
DataConfig = R6Class("DataConfig",
  public = list(

    #' @field s3_data_input_path
    #' Dataset S3 prefix/object URI.
    s3_data_input_path = NULL,

    #' @field s3_output_path
    #' S3 prefix to store the output.
    s3_output_path = NULL,

    #' @field s3_analysis_config_output_path
    #' S3 prefix to store the analysis_config output.
    s3_analysis_config_output_path = NULL,

    #' @field s3_data_distribution_type
    #' Valid options are "FullyReplicated" or "ShardedByS3Key".
    s3_data_distribution_type = NULL,

    #' @field s3_compression_type
    #' Valid options are "None" or "Gzip".
    s3_compression_type = NULL,

    #' @field label
    #' Target attribute of the model required by bias metrics
    label = NULL,

    #' @field headers
    #' A list of column names in the input dataset.
    headers = NULL,

    #' @field features
    #' JSONPath for locating the feature columns
    features = NULL,

    #' @field analysis_config
    #' Analysis config dictionary
    analysis_config = NULL,

    #' @description Initializes a configuration of both input and output datasets.
    #' @param s3_data_input_path (str): Dataset S3 prefix/object URI.
    #' @param s3_output_path (str): S3 prefix to store the output.
    #' @param s3_analysis_config_output_path (str): S3 prefix to store the analysis_config output
    #'              If this field is None, then the s3_output_path will be used
    #'              to store the analysis_config output
    #' @param label (str): Target attribute of the model required by bias metrics (optional for SHAP)
    #'              Specified as column name or index for CSV dataset, or as JSONPath for JSONLines.
    #' @param headers (list[str]): A list of column names in the input dataset.
    #' @param features (str): JSONPath for locating the feature columns for bias metrics if the
    #'              dataset format is JSONLines.
    #' @param dataset_type (str): Format of the dataset. Valid values are "text/csv" for CSV
    #'              and "application/jsonlines" for JSONLines.
    #' @param s3_data_distribution_type (str): Valid options are "FullyReplicated" or
    #'              "ShardedByS3Key".
    #' @param s3_compression_type (str): Valid options are "None" or "Gzip".
    #' @param joinsource (str): The name or index of the column in the dataset that acts as an
    #'              identifier column (for instance, while performing a join). This column is only
    #'              used as an identifier, and not used for any other computations. This is an
    #'              optional field in all cases except when the dataset contains more than one file,
    #'              and `save_local_shap_values` is set to true in SHAPConfig.
    initialize = function(s3_data_input_path,
                          s3_output_path,
                          s3_analysis_config_output_path=NULL,
                          label=NULL,
                          headers=NULL,
                          features=NULL,
                          dataset_type=c("text/csv", "application/jsonlines", "application/x-parquet", "application/x-image"),
                          s3_data_distribution_type="FullyReplicated",
                          s3_compression_type=c("None", "Gzip"),
                          joinsource=NULL){
      self$s3_data_input_path = s3_data_input_path
      self$s3_output_path = s3_output_path
      self$s3_analysis_config_output_path = s3_analysis_config_output_path
      if (s3_data_distribution_type != "FullyReplicated"){
        LOGGER$warn(paste(
          "s3_data_distribution_type parameter, set to %s, is being ignored. Only",
          "valid option is FullyReplicated"),
          s3_data_distribution_type
        )
      }
      self$s3_data_distribution_type = "FullyReplicated"
      self$s3_compression_type = match.arg(s3_compression_type)
      self$label = label
      self$headers = headers
      self$features = features
      self$analysis_config = list(
        "dataset_type"= match.arg(dataset_type))
      self$analysis_config[["features"]] = features
      self$analysis_config[["headers"]] = headers
      self$analysis_config[["label"]] = label
      self$analysis_config[["joinsource_name_or_index"]] = joinsource
    },

    #' @description Returns part of an analysis config dictionary.
    get_config = function(){
      return(self$analysis_config)
    },

    #' @description format class
    format = function(){
      return(format_class(self))
    }
  )
)

#' @title BiasConfig Class
#' @description Config object related to bias configurations of the input dataset.
#' @export
BiasConfig = R6Class("BiasConfig",
  public = list(

    #' @field analysis_config
    #' Analysis config dictionary
    analysis_config = NULL,

    #' @description Initializes a configuration of the sensitive groups in the dataset.
    #' @param label_values_or_threshold (Any): List of label values or threshold to indicate positive
    #'              outcome used for bias metrics.
    #' @param facet_name (str): Sensitive attribute in the input data for which we like to compare
    #'              metrics.
    #' @param facet_values_or_threshold (list): Optional list of values to form a sensitive group or
    #'              threshold for a numeric facet column that defines the lower bound of a sensitive
    #'              group. Defaults to considering each possible value as sensitive group and
    #'              computing metrics vs all the other examples.
    #' @param group_name (str): Optional column name or index to indicate a group column to be used
    #'              for the bias metric 'Conditional Demographic Disparity in Labels - CDDL' or
    #'              'Conditional Demographic Disparity in Predicted Labels - CDDPL'.
    initialize = function(label_values_or_threshold,
                          facet_name,
                          facet_values_or_threshold=NULL,
                          group_name=NULL){
      if (is.list(facet_name)) {
        if(length(facet_name) == 0) ValueError$new("Please provide at least one facet")
        if (is.null(facet_values_or_threshold)){
          facet_list = list(setNames(as.list(facet_name), rep("name_or_index", length(facet_name))))
        } else if (length(facet_values_or_threshold) == length(facet_name)){
          facet_list = list()
          for (i in seq_along(facet_name)) {
            facet = list("name_or_index"=facet_name[i])
            if (!is.null(facet_values_or_threshold)) {
              facet[["value_or_threshold"]] = facet_values_or_threshold[[i]]
              facet_list = list.append(facet_list, facet)
            }
          }
        } else {
          ValueError$new(
            "The number of facet names doesn't match the number of facet values"
          )
        }
      } else {
        facet = list("name_or_index"= facet_name)
        facet[["value_or_threshold"]] = facet_values_or_threshold
        facet_list = list(facet)
      }
      self$analysis_config = list(
        "label_values_or_threshold"= label_values_or_threshold,
        "facet"= facet_list)
      self$analysis_config[["group_variable"]] = group_name
    },

    #' @description Returns part of an analysis config dictionary.
    get_config = function(){
      self$analysis_config
    },

    #' @description format class
    format = function(){
      return(format_class(self))
    }
  )
)

#' @title Model Config
#' @description Config object related to a model and its endpoint to be created.
#' @export
ModelConfig = R6Class("ModelConfig",
  public = list(

    #' @field predictor_config
    #' Predictor dictionary of the analysis config
    predictor_config = NULL,

    #' @description Initializes a configuration of a model and the endpoint to be created for it.
    #' @param model_name (str): Model name (as created by 'CreateModel').
    #' @param instance_count (int): The number of instances of a new endpoint for model inference.
    #' @param instance_type (str): The type of EC2 instance to use for model inference,
    #'              for example, 'ml.c5.xlarge'.
    #' @param accept_type (str): The model output format to be used for getting inferences with the
    #'              shadow endpoint. Valid values are "text/csv" for CSV and "application/jsonlines".
    #'              Default is the same as content_type.
    #' @param content_type (str): The model input format to be used for getting inferences with the
    #'              shadow endpoint. Valid values are "text/csv" for CSV and "application/jsonlines".
    #'              Default is the same as dataset format.
    #' @param content_template (str): A template string to be used to construct the model input from
    #'              dataset instances. It is only used when "model_content_type" is
    #'              "application/jsonlines". The template should have one and only one placeholder
    #'              $features which will be replaced by a features list for to form the model inference
    #'              input.
    #' @param custom_attributes (str): Provides additional information about a request for an
    #'              inference submitted to a model hosted at an Amazon SageMaker endpoint. The
    #'              information is an opaque value that is forwarded verbatim. You could use this
    #'              value, for example, to provide an ID that you can use to track a request or to
    #'              provide other metadata that a service endpoint was programmed to process. The value
    #'              must consist of no more than 1024 visible US-ASCII characters as specified in
    #'              Section 3.3.6. Field Value Components (
    #'              \url{https://tools.ietf.org/html/rfc7230#section-3.2.6}) of the Hypertext Transfer
    #'              Protocol (HTTP/1.1).
    #' @param accelerator_type (str): The Elastic Inference accelerator type to deploy to the model
    #'              endpoint instance for making inferences to the model, see
    #'              \url{https://docs.aws.amazon.com/sagemaker/latest/dg/ei.html}.
    #' @param endpoint_name_prefix (str): The endpoint name prefix of a new endpoint. Must follow
    #'              pattern "^[a-zA-Z0-9](-\*[a-zA-Z0-9]".
    initialize = function(model_name,
                          instance_count,
                          instance_type,
                          accept_type=NULL,
                          content_type=NULL,
                          content_template=NULL,
                          custom_attributes=NULL,
                          accelerator_type=NULL,
                          endpoint_name_prefix=NULL){
      self$predictor_config = list(
        "model_name"= model_name,
        "instance_type"= instance_type,
        "initial_instance_count"= instance_count)

      if (!is.null(endpoint_name_prefix)){
        if(!grepl("^[a-zA-Z0-9](-*[a-zA-Z0-9])", endpoint_name_prefix))
          ValueError$new(
            "Invalid endpoint_name_prefix.",
            " Please follow pattern ^[a-zA-Z0-9](-*[a-zA-Z0-9]).")
        self$predictor_config[["endpoint_name_prefix"]] = endpoint_name_prefix
      }
      if (!is.null(accept_type)){
        if (!(accept_type %in% c("text/csv", "application/jsonlines"))){
          ValueError$new(sprintf("Invalid accept_type %s.", accept_type),
            " Please choose text/csv or application/jsonlines.")
          }
        self$predictor_config[["accept_type"]] = accept_type
      }
      if (!is.null(content_type)){
        if (!(content_type %in% c("text/csv", "application/jsonlines"))){
          ValueError$new(sprintf("Invalid content_type %s.", content_type),
               " Please choose text/csv or application/jsonlines.")
          }
        self$predictor_config[["content_type"]] = content_type
      }
      if (!is.null(content_template)){
        if (!grepl("$features", content_template)){
          ValueError$new(sprintf("Invalid content_template %s.", content_template),
               " Please include a placeholder $features.")
        }
        self$predictor_config[["content_template"]] = content_template
      }
      self$predictor_config[["custom_attributes"]] = custom_attributes
      self$predictor_config[["accelerator_type"]] = accelerator_type
    },

    #' @description Returns part of the predictor dictionary of the analysis config.
    get_predictor_config = function(){
      return(self$predictor_config)
    },

    #' @description format class
    format = function(){
      return(format_class(self))
    }
  )
)

#' @title ModelPredictedLabelConfig Class
#' @description Config object to extract a predicted label from the model output.
#' @export
ModelPredictedLabelConfig = R6Class("ModelPredictedLabelConfig",
  public = list(

    #' @field label
    #' Predicted label of the same type as the label in the dataset
    label = NULL,

    #' @field probability
    #' Optional index or JSONPath location in the model
    probability = NULL,

    #' @field probability_threshold
    #' An optional value for binary prediction task
    probability_threshold = NULL,

    #' @field predictor_config
    #' Predictor dictionary of the analysis config.
    predictor_config = NULL,

    #' @description Initializes a model output config to extract the predicted label.
    #'              The following examples show different parameter configurations depending on the endpoint:
    #'     \itemize{
    #'        \item{Regression Task: The model returns the score, e.g. 1.2. we don't need to specify
    #'              anything. For json output, e.g. \code{list('score'=1.2)} we can set `'label='score''`}
    #'        \item{Binary classification:}
    #'        \item{The model returns a single probability and we would like to classify as 'yes'
    #'              those with a probability exceeding 0.2.
    #'              We can set `'probability_threshold=0.2, label_headers='yes''`.}
    #'        \item{The model returns \code{list('probability'=0.3)}, for which we would like to apply a
    #'              threshold of 0.5 to obtain a predicted label in \code{list(0, 1)}. In this case we can set
    #'              `'label='probability''`.}
    #'        \item{The model returns a tuple of the predicted label and the probability.
    #'              In this case we can set `'label=0'`.}
    #'        \item{Multiclass classification:}
    #'        \item{The model returns
    #'              \code{list('labels'= c('cat', 'dog', 'fish'), 'probabilities'=c(0.35, 0.25, 0.4))}.
    #'              In this case we would set the `'probability='probabilities''` and
    #'              `'label='labels''` and infer the predicted label to be `'fish.'`}
    #'        \item{The model returns \code{list('predicted_label'='fish', 'probabilities'=c(0.35, 0.25, 0.4]))}.
    #'              In this case we would set the `'label='predicted_label''`.}
    #'        \item{The model returns \code{c(0.35, 0.25, 0.4)}. In this case, we can set
    #'              `'label_headers=['cat','dog','fish']'` and infer the predicted label to be `'fish.'`}
    #'        }
    #' @param label (str or [integer] or list[integer]): Optional index or JSONPath location in the model
    #'              output for the prediction. In case, this is a predicted label of the same type as
    #'              the label in the dataset no further arguments need to be specified.
    #' @param probability (str or [integer] or list[integer]): Optional index or JSONPath location in the model
    #'              output for the predicted scores.
    #' @param probability_threshold (float): An optional value for binary prediction tasks in which
    #'              the model returns a probability, to indicate the threshold to convert the
    #'              prediction to a boolean value. Default is 0.5.
    #' @param label_headers (list): List of label values - one for each score of the ``probability``.
    initialize =function(label=NULL,
                         probability=NULL,
                         probability_threshold=NULL,
                         label_headers=NULL){
      self$label = label
      self$probability = probability
      self$probability_threshold = probability_threshold
      if (!is.null(probability_threshold)){
        tryCatch({
          as.numeric(probability_threshold)},
          error = function(e){
            TypeError$new(sprintf("Invalid probability_threshold %s. ", probability_threshold),
                 "Please choose one that can be cast to float.")
        })
      }
      self$predictor_config = list()
      self$predictor_config[["label"]] =  label
      self$predictor_config[["probability"]] = probability
      self$predictor_config[["label_headers"]] = label_headers
    },

    #' @description Returns probability_threshold, predictor config.
    get_predictor_config = function(){
      return(list(self$probability_threshold, self$predictor_config))
    },

    #' @description format class
    format = function(){
      return(format_class(self))
    }
  )
)

#' @title ExplainabilityConfig Class
#' @description Abstract config class to configure an explainability method.
#' @export
ExplainabilityConfig = R6Class("ExplainabilityConfig",
  public = list(

    #' @description Returns config.
    get_explainability_config = function(){
      return(NULL)
    },

    #' @description format class
    format = function(){
      return(format_class(self))
    }
  )
)

#' @title Config class for Partial Dependence Plots (PDP).
#' @description If PDP is requested, the Partial Dependence Plots will be included in the report, and the
#' corresponding values will be included in the analysis output.
#' @export
PDPConfig = R6Class("PDPConfig",
  inherit = ExplainabilityConfig,
  public = list(

    #' @field pdp_config
    #' PDP Config
    pdp_config = NULL,

    #' @description Initializes config for PDP.
    #' @param features (None or list): List of features names or indices for which partial dependence
    #'              plots must be computed and plotted. When ShapConfig is provided, this parameter is
    #'              optional as Clarify will try to compute the partial dependence plots for top
    #'              feature based on SHAP attributions. When ShapConfig is not provided, 'features'
    #'              must be provided.
    #' @param grid_resolution (int): In case of numerical features, this number represents that
    #'              number of buckets that range of values must be divided into. This decides the
    #'              granularity of the grid in which the PDP are plotted.
    #' @param top_k_features (int): Set the number of top SHAP attributes to be selected to compute
    #'              partial dependence plots.
    initialize = function(features=NULL,
                          grid_resolution=15,
                          top_k_features=10){
      self$pdp_config = list("grid_resolution"=grid_resolution, "top_k_features"=top_k_features)
      if (!is.null(features))
        self$pdp_config["features"] = features
    },

    #' @description Returns config.
    get_explainability_config = function(){
      return (list("pdp"=self$pdp_config))
    }
  )
)

#' @title Config object to handle text features.
#' @description The SHAP analysis will break down longer text into chunks (e.g. tokens, sentences, or paragraphs
#'              ) and replace them with the strings specified in the baseline for that feature. The shap value
#'              of a chunk then captures how much replacing it affects the prediction.
#' @export
TextConfig = R6Class("TextConfig",
  inherit = ExplainabilityConfig,
  public = list(

    #' @field text_config
    #' Text Config
    text_config = NULL,

    #' @description Initializes a text configuration.
    #' @param granularity (str): Determines the granularity in which text features are broken down
    #'              to, can be "token", "sentence", or "paragraph". Shap values are computed for these units.
    #' @param language (str): Specifies the language of the text features, can be "chinese", "danish",
    #'              "dutch", "english", "french", "german", "greek", "italian", "japanese", "lithuanian",
    #'              "multi-language", "norwegian bokmal", "polish", "portuguese", "romanian", "russian",
    #'              "spanish", "afrikaans", "albanian", "arabic", "armenian", "basque", "bengali", "bulgarian",
    #'              "catalan", "croatian", "czech", "estonian", "finnish", "gujarati", "hebrew", "hindi",
    #'              "hungarian", "icelandic", "indonesian", "irish", "kannada", "kyrgyz", "latvian", "ligurian",
    #'              "luxembourgish", "macedonian", "malayalam", "marathi", "nepali", "persian", "sanskrit",
    #'              "serbian", "setswana", "sinhala", "slovak", "slovenian", "swedish", "tagalog", "tamil",
    #'              "tatar", "telugu", "thai", "turkish", "ukrainian", "urdu", "vietnamese", "yoruba". Use
    #'              "multi-language" for a mix of mulitple languages.
    initialize = function(granularity,
                          language){
      if (!(granularity %in% private$.SUPPORTED_GRANULARITIES))
        ValueError$new(
          sprintf("Invalid granularity %s. Please choose among ", granularity),
          paste(private$.SUPPORTED_GRANULARITIES, collapse=", ")
        )
      if (!(str_to_ascii_code(language) %in% private$.SUPPORTED_LANGUAGES))
        ValueError$new(
          sprintf("Invalid language %s. Please choose among ", language),
          paste(ascii_code_to_str(private$SUPPORTED_LANGUAGES), collapse=", ")
        )
      self$text_config = list(
        "granularity"=granularity,
        "language"=language
      )
    },

    #' @description Returns part of an analysis config dictionary.
    get_text_config = function(){
      return(list(self$text_config))
    }
  ),
  private = list(
    .SUPPORTED_GRANULARITIES = c("token", "sentence", "paragraph"),

    # Use Ascii Code due to CRAN warning message:
    # Portable packages must use only ASCII characters in their R code,
    # except perhaps in comments.
    .SUPPORTED_LANGUAGES = list(
      c(99, 104, 105, 110, 101, 115, 101),
      c(100, 97, 110, 105, 115, 104),
      c(100, 117, 116, 99, 104),
      c(101, 110, 103, 108, 105, 115, 104),
      c(102, 114, 101, 110, 99, 104),
      c(103, 101, 114, 109, 97, 110),
      c(103, 114, 101, 101, 107),
      c(105, 116, 97, 108, 105, 97, 110),
      c(106, 97, 112, 97, 110, 101, 115, 101),
      c(108, 105, 116, 104, 117, 97, 110, 105, 97, 110),
      c(109, 117, 108, 116, 105, 45, 108, 97, 110, 103, 117, 97, 103, 101),
      c(110, 111, 114, 119, 101, 103, 105, 97, 110, 32, 98, 111, 107, 109, 195, 165, 108),
      c(112, 111, 108, 105, 115, 104),
      c(112, 111, 114, 116, 117, 103, 117, 101, 115, 101),
      c(114, 111, 109, 97, 110, 105, 97, 110),
      c(114, 117, 115, 115, 105, 97, 110),
      c(115, 112, 97, 110, 105, 115, 104),
      c(97, 102, 114, 105, 107, 97, 97, 110, 115),
      c(97, 108, 98, 97, 110, 105, 97, 110),
      c(97, 114, 97, 98, 105, 99),
      c(97, 114, 109, 101, 110, 105, 97, 110),
      c(98, 97, 115, 113, 117, 101),
      c(98, 101, 110, 103, 97, 108, 105),
      c(98, 117, 108, 103, 97, 114, 105, 97, 110),
      c(99, 97, 116, 97, 108, 97, 110),
      c(99, 114, 111, 97, 116, 105, 97, 110),
      c(99, 122, 101, 99, 104),
      c(101, 115, 116, 111, 110, 105, 97, 110),
      c(102, 105, 110, 110, 105, 115, 104),
      c(103, 117, 106, 97, 114, 97, 116, 105),
      c(104, 101, 98, 114, 101, 119),
      c(104, 105, 110, 100, 105),
      c(104, 117, 110, 103, 97, 114, 105, 97, 110),
      c(105, 99, 101, 108, 97, 110, 100, 105, 99),
      c(105, 110, 100, 111, 110, 101, 115, 105, 97, 110),
      c(105, 114, 105, 115, 104),
      c(107, 97, 110, 110, 97, 100, 97),
      c(107, 121, 114, 103, 121, 122),
      c(108, 97, 116, 118, 105, 97, 110),
      c(108, 105, 103, 117, 114, 105, 97, 110),
      c(108, 117, 120, 101, 109, 98, 111, 117, 114, 103, 105, 115, 104),
      c(109, 97, 99, 101, 100, 111, 110, 105, 97, 110),
      c(109, 97, 108, 97, 121, 97, 108, 97, 109),
      c(109, 97, 114, 97, 116, 104, 105),
      c(110, 101, 112, 97, 108, 105),
      c(112, 101, 114, 115, 105, 97, 110),
      c(115, 97, 110, 115, 107, 114, 105, 116),
      c(115, 101, 114, 98, 105, 97, 110),
      c(115, 101, 116, 115, 119, 97, 110, 97),
      c(115, 105, 110, 104, 97, 108, 97),
      c(115, 108, 111, 118, 97, 107),
      c(115, 108, 111, 118, 101, 110, 105, 97, 110),
      c(115, 119, 101, 100, 105, 115, 104),
      c(116, 97, 103, 97, 108, 111, 103),
      c(116, 97, 109, 105, 108),
      c(116, 97, 116, 97, 114),
      c(116, 101, 108, 117, 103, 117),
      c(116, 104, 97, 105),
      c(116, 117, 114, 107, 105, 115, 104),
      c(117, 107, 114, 97, 105, 110, 105, 97, 110),
      c(117, 114, 100, 117),
      c(118, 105, 101, 116, 110, 97, 109, 101, 115, 101),
      c(121, 111, 114, 117, 98, 97)
    )
  )
)

#' @title Config object for handling images
#' @export
ImageConfig = R6Class("ImageConfig",
  inherit = ExplainabilityConfig,
  public = list(

    #' @field image_config
    #' Image config
    image_config = NULL,

    #' @description Initializes all configuration parameters needed for SHAP CV explainability
    #' @param model_type (str): Specifies the type of CV model. Options:
    #'              (IMAGE_CLASSIFICATION | OBJECT_DETECTION).
    #' @param num_segments (None or int): Clarify uses SKLearn's SLIC method for image segmentation
    #'              to generate features/superpixels. num_segments specifies approximate
    #'              number of segments to be generated. Default is None. SLIC will default to
    #'              100 segments.
    #' @param feature_extraction_method (NULL or str): method used for extracting features from the
    #'              image.ex. "segmentation". Default is segmentation.
    #' @param segment_compactness (NULL or float): Balances color proximity and space proximity.
    #'              Higher values give more weight to space proximity, making superpixel
    #'              shapes more square/cubic. We recommend exploring possible values on a log
    #'              scale, e.g., 0.01, 0.1, 1, 10, 100, before refining around a chosen value.
    #' @param max_objects (NULL or int): maximum number of objects displayed. Object detection
    #'              algorithm may detect more than max_objects number of objects in a single
    #'              image. The top max_objects number of objects according to confidence score
    #'              will be displayed.
    #' @param iou_threshold (NULL or float): minimum intersection over union for the object
    #'              bounding box to consider its confidence score for computing SHAP values [0.0, 1.0].
    #'              This parameter is used for the object detection case.
    #' @param context (NULL or float): refers to the portion of the image outside of the bounding box.
    #'              Scale is [0.0, 1.0]. If set to 1.0, whole image is considered, if set to
    #'              0.0 only the image inside bounding box is considered.
    initialize = function(model_type,
                          num_segments=NULL,
                          feature_extraction_method=NULL,
                          segment_compactness=NULL,
                          max_objects=NULL,
                          iou_threshold=NULL,
                          context=NULL){
      self$image_config = list()

      if (!(model_type %in% c("OBJECT_DETECTION", "IMAGE_CLASSIFICATION")))
        ValueError$new(
          "Clarify SHAP only supports object detection and image classification methods. ",
          "Please set model_type to OBJECT_DETECTION or IMAGE_CLASSIFICATION."
        )
      self$image_config[["model_type"]] = model_type
      self$image_config[["num_segments"]] = num_segments
      self$image_config[["feature_extraction_method"]] = feature_extraction_method
      self$image_config[["segment_compactness"]] = segment_compactness
      self$image_config[["max_objects"]] = max_objects
      self$image_config[["iou_threshold"]] = iou_threshold
      self$image_config[["context"]] = context
    },

    #' @description Returns the image config part of an analysis config dictionary.
    get_image_config = function(){
      return (list(self$image_config))
    }
  )
)

#' @title SHAPConfig Class
#' @description Config class of SHAP.
#' @export
SHAPConfig = R6Class("SHAPConfig",
  inherit = ExplainabilityConfig,
  public = list(

    #' @field shap_config
    #' Shap Config
    shap_config = NULL,

    #' @description Initializes config for SHAP.
    #' @param baseline (str or list): A list of rows (at least one) or S3 object URI to be used as
    #'              the baseline dataset in the Kernel SHAP algorithm. The format should be the same
    #'              as the dataset format. Each row should contain only the feature columns/values
    #'              and omit the label column/values.
    #' @param num_samples (int): Number of samples to be used in the Kernel SHAP algorithm.
    #'              This number determines the size of the generated synthetic dataset to compute the
    #'              SHAP values.
    #' @param agg_method (str): Aggregation method for global SHAP values. Valid values are
    #'              "mean_abs" (mean of absolute SHAP values for all instances),
    #'              "median" (median of SHAP values for all instances) and
    #'              "mean_sq" (mean of squared SHAP values for all instances).
    #' @param use_logit (bool): Indicator of whether the logit function is to be applied to the model
    #'              predictions. Default is False. If "use_logit" is true then the SHAP values will
    #'              have log-odds units.
    #' @param save_local_shap_values (bool): Indicator of whether to save the local SHAP values
    #'              in the output location. Default is True.
    #' @param seed (int): seed value to get deterministic SHAP values. Default is NULL.
    #' @param num_clusters (NULL or int): If a baseline is not provided, Clarify automatically
    #'              computes a baseline dataset via a clustering algorithm (K-means/K-prototypes).
    #'              num_clusters is a parameter for this algorithm. num_clusters will be the resulting
    #'              size of the baseline dataset. If not provided, Clarify job will use a default value.
    #' @param text_config (:class:`~sagemaker.clarify.TextConfig`): Config to handle text features.
    #'              Default is NULL
    #' @param image_config (:class:`~sagemaker.clarify.ImageConfig`): Config to handle image features.
    #'              Default is NULL
    initialize = function(baseline,
                          num_samples,
                          agg_method = c("mean_abs", "median", "mean_sq"),
                          use_logit=FALSE,
                          save_local_shap_values=TRUE,
                          seed=NULL,
                          num_clusters=NULL,
                          text_config=NULL,
                          image_config=NULL){
      agg_method = match.arg(agg_method)
      if (!is.null(num_clusters) && !is.null(baseline))
        ValueError$new(
          "Baseline and num_clusters cannot be provided together. ",
          "Please specify one of the two."
        )
      self$shap_config = list(
        "use_logit"=use_logit,
        "save_local_shap_values"=save_local_shap_values
      )
      self$shap_config[["baseline"]] = baseline
      self$shap_config[["num_samples"]] = num_samples
      self$shap_config[["agg_method"]] = agg_method
      self$shap_config[["seed"]] = seed
      self$shap_config[["num_clusters"]] = num_clusters

      if (!is.null(text_config))
        self$shap_config[["text_config"]] = text_config$get_text_config()
      if (!save_local_shap_values)
        LOGGER$warn(paste(
          "Global aggregation is not yet supported for text features.",
          "Consider setting save_local_shap_values=True to inspect local text",
          "explanations.")
        )
      if (!is.null(image_config))
        self$shap_config[["image_config"]] = image_config$get_image_config()
    },

    #' @description Returns config.
    get_explainability_config = function(){
      return(list("shap"=self$shap_config))
    }
  )
)

#' @title SageMakerClarifyProcessor Class
#' @description Handles SageMaker Processing task to compute bias metrics and explain a model.
#' @export
SageMakerClarifyProcessor = R6Class("SageMakerClarifyProcessor",
  inherit = sagemaker.common::Processor,
  public = list(

    #' @field job_name_prefix
    #' Processing job name prefix
    job_name_prefix = NULL,

    #' @description Initializes a ``Processor`` instance, computing bias metrics and model explanations.
    #' @param role (str): An AWS IAM role name or ARN. Amazon SageMaker Processing
    #'              uses this role to access AWS resources, such as
    #'              data stored in Amazon S3.
    #' @param instance_count (int): The number of instances to run
    #'              a processing job with.
    #' @param instance_type (str): The type of EC2 instance to use for
    #'              processing, for example, 'ml.c4.xlarge'.
    #' @param volume_size_in_gb (int): Size in GB of the EBS volume
    #'              to use for storing data during processing (default: 30).
    #' @param volume_kms_key (str): A KMS key for the processing
    #'              volume (default: None).
    #' @param output_kms_key (str): The KMS key ID for processing job outputs (default: None).
    #' @param max_runtime_in_seconds (int): Timeout in seconds (default: None).
    #'              After this amount of time, Amazon SageMaker terminates the job,
    #'              regardless of its current status. If `max_runtime_in_seconds` is not
    #'              specified, the default value is 24 hours.
    #' @param sagemaker_session (:class:`~sagemaker.session.Session`):
    #'              Session object which manages interactions with Amazon SageMaker and
    #'              any other AWS services needed. If not specified, the processor creates
    #'              one using the default AWS configuration chain.
    #' @param env (dict[str, str]): Environment variables to be passed to
    #'              the processing jobs (default: None).
    #' @param tags (list[dict]): List of tags to be passed to the processing job
    #'              (default: None). For more, see
    #'              https://docs.aws.amazon.com/sagemaker/latest/dg/API_Tag.html.
    #' @param network_config (:class:`~sagemaker.network.NetworkConfig`):
    #'              A :class:`~sagemaker.network.NetworkConfig`
    #'              object that configures network isolation, encryption of
    #'              inter-container traffic, security group IDs, and subnets.
    #' @param job_name_prefix (str): Processing job name prefix.
    #' @param version (str): Clarify version want to be used.
    initialize = function(role,
                          instance_count,
                          instance_type,
                          volume_size_in_gb=30,
                          volume_kms_key=NULL,
                          output_kms_key=NULL,
                          max_runtime_in_seconds=NULL,
                          sagemaker_session=NULL,
                          env=NULL,
                          tags=NULL,
                          network_config=NULL,
                          job_name_prefix=NULL,
                          version=NULL){
      container_uri = ImageUris$new()$retrieve("clarify", sagemaker_session$paws_region_name,version)
      self$job_name_prefix = job_name_prefix
      super$initialize(
        role,
        container_uri,
        instance_count,
        instance_type,
        NULL,  # We manage the entrypoint.
        volume_size_in_gb,
        volume_kms_key,
        output_kms_key,
        max_runtime_in_seconds,
        NULL,  # We set method-specific job names below.
        sagemaker_session,
        env,
        tags,
        network_config)
    },

    #' @description Overriding the base class method but deferring to specific run_* methods.
    run = function(){
      NotImplementedError$new(
        "Please choose a method of run_pre_training_bias, run_post_training_bias or ",
        "run_explainability.")
    },

    #' @description Runs a ProcessingJob to compute the requested bias 'methods' of the input data.
    #'              Computes the requested methods that compare 'methods' (e.g. fraction of examples) for the
    #'              sensitive group vs the other examples.
    #' @param data_config (:class:`~sagemaker.clarify.DataConfig`): Config of the input/output data.
    #' @param data_bias_config (:class:`~sagemaker.clarify.BiasConfig`): Config of sensitive groups.
    #' @param methods (str or list[str]): Selector of a subset of potential metrics:
    #' \itemize{
    #'    \item{`CI` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-ci.html}}
    #'    \item{`DPL` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-dpl.html}}
    #'    \item{`KL` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-kl.html}}
    #'    \item{`JS` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-js.html}}
    #'    \item{`LP` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-lp.html}}
    #'    \item{`TVD` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-tvd.html}}
    #'    \item{`KS` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-ks.html}}
    #'    \item{`CDDL` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-cdd.html}}
    #' }
    #'              Defaults to computing all.
    #' @param wait (bool): Whether the call should wait until the job completes (default: True).
    #' @param logs (bool): Whether to show the logs produced by the job.
    #'              Only meaningful when ``wait`` is True (default: True).
    #' @param job_name (str): Processing job name. If not specified, a name is composed of
    #'              "Clarify-Pretraining-Bias" and current timestamp.
    #' @param kms_key (str): The ARN of the KMS key that is used to encrypt the
    #'              user code file (default: None).
    #' @param experiment_config (dict[str, str]): Experiment management configuration.
    #'              Dictionary contains three optional keys:
    #'              'ExperimentName', 'TrialName', and 'TrialComponentDisplayName'.
    run_pre_training_bias = function(data_config,
                                     data_bias_config,
                                     methods="all",
                                     wait=TRUE,
                                     logs=TRUE,
                                     job_name=NULL,
                                     kms_key=NULL,
                                     experiment_config=NULL){
      analysis_config = data_config$get_config()
      analysis_config.update(data_bias_config$get_config())
      analysis_config[["methods"]] = list("pre_training_bias"= list("methods"= methods))
      if (is.null(job_name)){
        if (!is.null(self$job_name_prefix)) {
          job_name = name_from_base(self$job_name_prefix)
        } else {
        job_name = name_from_base("Clarify-Pretraining-Bias")}
      }
      private$.run(data_config, analysis_config, wait, logs, job_name, kms_key)
    },

    #' @description Runs a ProcessingJob to compute the requested bias 'methods' of the model predictions.
    #'              Spins up a model endpoint, runs inference over the input example in the
    #'              's3_data_input_path' to obtain predicted labels. Computes a the requested methods that
    #'              compare 'methods' (e.g. accuracy, precision, recall) for the sensitive group vs the other
    #'              examples.
    #' @param data_config (:class:`~sagemaker.clarify.DataConfig`): Config of the input/output data.
    #' @param data_bias_config (:class:`~sagemaker.clarify.BiasConfig`): Config of sensitive groups.
    #' @param model_config (:class:`~sagemaker.clarify.ModelConfig`): Config of the model and its
    #'              endpoint to be created.
    #' @param model_predicted_label_config (:class:`~sagemaker.clarify.ModelPredictedLabelConfig`):
    #'              Config of how to extract the predicted label from the model output.
    #' @param methods (str or list[str]): Selector of a subset of potential metrics:
    #' \itemize{
    #'    \item{`CI` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-ci.html}}
    #'    \item{`DPL` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-dpl.html}}
    #'    \item{`KL` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-kl.html}}
    #'    \item{`JS` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-js.html}}
    #'    \item{`LP` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-lp.html}}
    #'    \item{`TVD` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-tvd.html}}
    #'    \item{`KS` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-ks.html}}
    #'    \item{`CDDL` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-cdd.html}}
    #' }
    #'              Defaults to computing all.
    #' @param wait (bool): Whether the call should wait until the job completes (default: True).
    #' @param logs (bool): Whether to show the logs produced by the job.
    #'              Only meaningful when ``wait`` is True (default: True).
    #' @param job_name (str): Processing job name. If not specified, a name is composed of
    #'              "Clarify-Posttraining-Bias" and current timestamp.
    #' @param kms_key (str): The ARN of the KMS key that is used to encrypt the
    #'              user code file (default: None).
    #' @param experiment_config (dict[str, str]): Experiment management configuration.
    #'              Dictionary contains three optional keys:
    #'              'ExperimentName', 'TrialName', and 'TrialComponentDisplayName'.
    run_post_training_bias = function(data_config,
                                      data_bias_config,
                                      model_config,
                                      model_predicted_label_config,
                                      methods="all",
                                      wait=TRUE,
                                      logs=TRUE,
                                      job_name=NULL,
                                      kms_key=NULL,
                                      experiment_config=NULL){
      analysis_config = data_config$get_config()
      analysis_config = modifyList(analysis_config, data_bias_config$get_config())

      ll = setNames(
        model_predicted_label_config$get_predictor_config(),
        c("probability_threshold", "predictor_config")
      )

      ll$predictor_config = modifyList(ll$predictor_config, model_config$get_predictor_config())
      analysis_config[["methods"]] = list("post_training_bias"= list("methods"= methods))
      analysis_config[["predictor"]] = ll$predictor_config
      ll$probability_threshold[["probability_threshold"]] = analysis_config
      if (is.null(job_name)){
        if(!is.null(self$job_name_prefix)){
          job_name = name_from_base(self$job_name_prefix)
        } else {
          job_name = name_from_base("Clarify-Posttraining-Bias")
        }
      }
      private$.run(data_config, analysis_config, wait, logs, job_name, kms_key)
    },

    #' @description Runs a ProcessingJob to compute the requested bias 'methods' of the model predictions.
    #'              Spins up a model endpoint, runs inference over the input example in the
    #'              's3_data_input_path' to obtain predicted labels. Computes a the requested methods that
    #'              compare 'methods' (e.g. accuracy, precision, recall) for the sensitive group vs the other
    #'              examples.
    #' @param data_config (:class:`~sagemaker.clarify.DataConfig`): Config of the input/output data.
    #' @param bias_config (:class:`~sagemaker.clarify.BiasConfig`): Config of sensitive groups.
    #' @param model_config (:class:`~sagemaker.clarify.ModelConfig`): Config of the model and its
    #'              endpoint to be created.
    #' @param model_predicted_label_config (:class:`~sagemaker.clarify.ModelPredictedLabelConfig`):
    #'              Config of how to extract the predicted label from the model output.
    #' @param pre_training_methods (str or list[str]): Selector of a subset of potential metrics:
    #' \itemize{
    #'    \item{`CI` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-ci.html}}
    #'    \item{`DPL` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-dpl.html}}
    #'    \item{`KL` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-kl.html}}
    #'    \item{`JS` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-js.html}}
    #'    \item{`LP` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-lp.html}}
    #'    \item{`TVD` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-tvd.html}}
    #'    \item{`KS` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-ks.html}}
    #'    \item{`CDDL` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-cdd.html}}
    #' }
    #'              Defaults to computing all.
    #' @param post_training_methods (str or list[str]): Selector of a subset of potential metrics:
    #' \itemize{
    #'    \item{`DPPL` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-dppl.html}}
    #'    \item{`DI` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-di.html}}
    #'    \item{`DCA` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-dca.html}}
    #'    \item{`DCR` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-dcr.html}}
    #'    \item{`RD` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-rd.html}}
    #'    \item{`DAR` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-dar.html}}
    #'    \item{`DRR` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-drr.html}}
    #'    \item{`AD` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-ad.html}}
    #'    \item{`CDDPL` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-cddpl.html}}
    #'    \item{`TE` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-te.html}}
    #'    \item{`FT` \url{https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-post-training-bias-metric-ft.html}}
    #' }
    #'              Defaults to computing all.
    #' @param wait (bool): Whether the call should wait until the job completes (default: True).
    #' @param logs (bool): Whether to show the logs produced by the job.
    #'              Only meaningful when ``wait`` is True (default: True).
    #' @param job_name (str): Processing job name. If not specified, a name is composed of
    #'              "Clarify-Bias" and current timestamp.
    #' @param kms_key (str): The ARN of the KMS key that is used to encrypt the
    #'              user code file (default: None).
    #' @param experiment_config (dict[str, str]): Experiment management configuration.
    #'              Dictionary contains three optional keys:
    #'              'ExperimentName', 'TrialName', and 'TrialComponentDisplayName'.
    run_bias = function(data_config,
                        bias_config,
                        model_config,
                        model_predicted_label_config=NULL,
                        pre_training_methods="all",
                        post_training_methods="all",
                        wait=TRUE,
                        logs=TRUE,
                        job_name=NULL,
                        kms_key=NULL,
                        experiment_config=NULL){
      analysis_config = data_config$get_config()
      analysis_config = modifyList(analysis_config, bias_config$get_config())
      analysis_config[["predictor"]] = model_config$get_predictor_config()
      if (!is.null(model_predicted_label_config)){
        ll = model_predicted_label_config$get_predictor_config()
        names(ll) = c("probability_threshold", "predictor_config")
        if (!islistempty(ll$predictor_config))
          analysis_config[["predictor"]] = modifyList(analysis_config[["predictor"]], ll$predictor_config)
        if (!islistempty(ll$probability_threshold))
          analysis_config[["probability_threshold"]] = ll$probability_threshold
      }
      analysis_config[["methods"]] = list(
        "pre_training_bias"= list("methods"= pre_training_methods),
        "post_training_bias"= list("methods"= post_training_methods))
      if (is.null(job_name)){
        if(!is.null(self$job_name_prefix)){
          job_name = name_from_base(self$job_name_prefix)
        } else {
          job_name = name_from_base("Clarify-Bias")
        }
      }
      private$.run(data_config, analysis_config, wait, logs, job_name, kms_key)
    },

    #' @description Runs a ProcessingJob computing for each example in the input the feature importance.
    #'              Currently, only SHAP is supported as explainability method.
    #'              Spins up a model endpoint.
    #'              For each input example in the 's3_data_input_path' the SHAP algorithm determines
    #'              feature importance, by creating 'num_samples' copies of the example with a subset
    #'              of features replaced with values from the 'baseline'.
    #'              Model inference is run to see how the prediction changes with the replaced features.
    #'              If the model output returns multiple scores importance is computed for each of them.
    #'              Across examples, feature importance is aggregated using 'agg_method'.
    #' @param data_config (:class:`~sagemaker.clarify.DataConfig`): Config of the input/output data.
    #' @param model_config (:class:`~sagemaker.clarify.ModelConfig`): Config of the model and its
    #'              endpoint to be created.
    #' @param explainability_config (:class:`~sagemaker.clarify.ExplainabilityConfig`): Config of the
    #'              specific explainability method. Currently, only SHAP is supported.
    #' @param model_scores :  Index or JSONPath location in the model output for the predicted scores
    #'              to be explained. This is not required if the model output is a single score.
    #' @param wait (bool): Whether the call should wait until the job completes (default: True).
    #' @param logs (bool): Whether to show the logs produced by the job.
    #'              Only meaningful when ``wait`` is True (default: True).
    #' @param job_name (str): Processing job name. If not specified, a name is composed of
    #'              "Clarify-Explainability" and current timestamp.
    #' @param kms_key (str): The ARN of the KMS key that is used to encrypt the
    #'              user code file (default: None).
    #' @param experiment_config (dict[str, str]): Experiment management configuration.
    #'              Dictionary contains three optional keys:
    #'              'ExperimentName', 'TrialName', and 'TrialComponentDisplayName'.
    run_explainability = function(data_config,
                                  model_config,
                                  explainability_config,
                                  model_scores=NULL,
                                  wait=TRUE,
                                  logs=TRUE,
                                  job_name=NULL,
                                  kms_key=NULL,
                                  experiment_config=NULL){
      analysis_config = data_config$get_config()
      predictor_config = model_config$get_predictor_config()
      if (inherits(model_scores, "ModelPredictedLabelConfig")){
        ll = model_scores$get_predictor_config()
        names(ll) = c("probability_threshold", "predicted_label_config")
        analysis_config[["probability_threshold"]] = ll$probability_threshold
        predictor_config = modifyList(predictor_config, ll$predicted_label_config)
      } else {
        model_scores[["label"]] = predictor_config
      }
      if (is.null(job_name)){
        if (!is.null(self$job_name_prefix)){
          job_name = name_from_base(self$job_name_prefix)
        } else {
          job_name = name_from_base("Clarify-Explainability")
        }
      }
      private$.run(data_config, analysis_config, wait, logs, job_name, kms_key)
    }
  ),
  private = list(
    .CLARIFY_DATA_INPUT = "/opt/ml/processing/input/data",
    .CLARIFY_CONFIG_INPUT = "/opt/ml/processing/input/config",
    .CLARIFY_OUTPUT = "/opt/ml/processing/output",

    # Runs a ProcessingJob with the Sagemaker Clarify container and an analysis config.
    # Args:
    #   data_config (:class:`~sagemaker.clarify.DataConfig`): Config of the input/output data.
    # analysis_config (dict): Config following the analysis_config.json format.
    # wait (bool): Whether the call should wait until the job completes (default: True).
    # logs (bool): Whether to show the logs produced by the job.
    # Only meaningful when ``wait`` is True (default: True).
    # job_name (str): Processing job name.
    # kms_key (str): The ARN of the KMS key that is used to encrypt the
    # user code file (default: None).
    .run = function(data_config,
                    analysis_config,
                    wait,
                    logs,
                    job_name,
                    kms_key){
      analysis_config[["methods"]][["report"]] = list("name"="report", "title"="Analysis Report")

      tmpdirname = tempdir()
      on.exit(unlink(tmpdirname, recursive = T))
      analysis_config_file = file.path(tmpdirname, "analysis_config.json")
      write_json(analysis_config, analysis_config_file, auto_unbox = T)

      s3_analysis_config_file = .upload_analysis_config(
        analysis_config_file,
        data_config$s3_output_path,
        self$sagemaker_session,
        kms_key
      )

      config_input = ProcessingInput$new(
        input_name="analysis_config",
        source=analysis_config_file,
        destination=private$.CLARIFY_CONFIG_INPUT,
        s3_data_type="S3Prefix",
        s3_input_mode="File",
        s3_compression_type="None")

      data_input = ProcessingInput$new(
        input_name="dataset",
        source=data_config$s3_data_input_path,
        destination=private$.CLARIFY_DATA_INPUT,
        s3_data_type="S3Prefix",
        s3_input_mode="File",
        s3_data_distribution_type=data_config$s3_data_distribution_type,
        s3_compression_type=data_config$s3_compression_type)

      result_output = ProcessingOutput$new(
        source=private$.CLARIFY_OUTPUT,
        destination=data_config$s3_output_path,
        output_name="analysis_result",
        s3_upload_mode="EndOfJob")

      super$run(
        inputs=list(data_input, config_input),
        outputs=list(result_output),
        wait=wait,
        logs=logs,
        job_name=job_name,
        kms_key=kms_key)
    }
  )
)

#' @title Uploads the local analysis_config_file to the s3_output_path.
#' @param analysis_config_file (str): File path to the local analysis config file.
#' @param s3_output_path (str): S3 prefix to store the analysis config file.
#' @param sagemaker_session (:class:`~sagemaker.session.Session`):
#'              Session object which manages interactions with Amazon SageMaker and
#'              any other AWS services needed. If not specified, the processor creates
#'              one using the default AWS configuration chain.
#' @param kms_key (str): The ARN of the KMS key that is used to encrypt the
#'              user code file (default: None).
#' @return The S3 uri of the uploaded file.
#' @noRd
#' @export
.upload_analysis_config = function(analysis_config_file,
                                   s3_output_path,
                                   sagemaker_session,
                                   kms_key){
  return(S3Uploader$new()$upload(
    local_path=analysis_config_file,
    desired_s3_uri=s3_output_path,
    sagemaker_session=sagemaker_session,
    kms_key=kms_key)
  )
}
