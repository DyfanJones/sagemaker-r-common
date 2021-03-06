% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/clarify.R
\name{ImageConfig}
\alias{ImageConfig}
\title{Config object for handling images}
\description{
Config object for handling images

Config object for handling images
}
\section{Super class}{
\code{\link[sagemaker.common:ExplainabilityConfig]{sagemaker.common::ExplainabilityConfig}} -> \code{ImageConfig}
}
\section{Public fields}{
\if{html}{\out{<div class="r6-fields">}}
\describe{
\item{\code{image_config}}{Image config}
}
\if{html}{\out{</div>}}
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-ImageConfig-new}{\code{ImageConfig$new()}}
\item \href{#method-ImageConfig-get_image_config}{\code{ImageConfig$get_image_config()}}
\item \href{#method-ImageConfig-clone}{\code{ImageConfig$clone()}}
}
}
\if{html}{\out{
<details open><summary>Inherited methods</summary>
<ul>
<li><span class="pkg-link" data-pkg="sagemaker.common" data-topic="ExplainabilityConfig" data-id="format"><a href='../../sagemaker.common/html/ExplainabilityConfig.html#method-ExplainabilityConfig-format'><code>sagemaker.common::ExplainabilityConfig$format()</code></a></li>
<li><span class="pkg-link" data-pkg="sagemaker.common" data-topic="ExplainabilityConfig" data-id="get_explainability_config"><a href='../../sagemaker.common/html/ExplainabilityConfig.html#method-ExplainabilityConfig-get_explainability_config'><code>sagemaker.common::ExplainabilityConfig$get_explainability_config()</code></a></li>
</ul>
</details>
}}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ImageConfig-new"></a>}}
\if{latex}{\out{\hypertarget{method-ImageConfig-new}{}}}
\subsection{Method \code{new()}}{
Initializes all configuration parameters needed for SHAP CV explainability
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ImageConfig$new(
  model_type,
  num_segments = NULL,
  feature_extraction_method = NULL,
  segment_compactness = NULL,
  max_objects = NULL,
  iou_threshold = NULL,
  context = NULL
)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{model_type}}{(str): Specifies the type of CV model. Options:
(IMAGE_CLASSIFICATION | OBJECT_DETECTION).}

\item{\code{num_segments}}{(None or int): Clarify uses SKLearn's SLIC method for image segmentation
to generate features/superpixels. num_segments specifies approximate
number of segments to be generated. Default is None. SLIC will default to
100 segments.}

\item{\code{feature_extraction_method}}{(NULL or str): method used for extracting features from the
image.ex. "segmentation". Default is segmentation.}

\item{\code{segment_compactness}}{(NULL or float): Balances color proximity and space proximity.
Higher values give more weight to space proximity, making superpixel
shapes more square/cubic. We recommend exploring possible values on a log
scale, e.g., 0.01, 0.1, 1, 10, 100, before refining around a chosen value.}

\item{\code{max_objects}}{(NULL or int): maximum number of objects displayed. Object detection
algorithm may detect more than max_objects number of objects in a single
image. The top max_objects number of objects according to confidence score
will be displayed.}

\item{\code{iou_threshold}}{(NULL or float): minimum intersection over union for the object
bounding box to consider its confidence score for computing SHAP values [0.0, 1.0].
This parameter is used for the object detection case.}

\item{\code{context}}{(NULL or float): refers to the portion of the image outside of the bounding box.
Scale is [0.0, 1.0]. If set to 1.0, whole image is considered, if set to
0.0 only the image inside bounding box is considered.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ImageConfig-get_image_config"></a>}}
\if{latex}{\out{\hypertarget{method-ImageConfig-get_image_config}{}}}
\subsection{Method \code{get_image_config()}}{
Returns the image config part of an analysis config dictionary.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ImageConfig$get_image_config()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ImageConfig-clone"></a>}}
\if{latex}{\out{\hypertarget{method-ImageConfig-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ImageConfig$clone(deep = FALSE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{deep}}{Whether to make a deep clone.}
}
\if{html}{\out{</div>}}
}
}
}
