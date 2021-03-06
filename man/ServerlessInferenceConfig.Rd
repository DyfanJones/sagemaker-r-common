% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/serverless_serverless_inference_config.R
\name{ServerlessInferenceConfig}
\alias{ServerlessInferenceConfig}
\title{Configuration object passed in when deploying models to Amazon SageMaker Endpoints.}
\description{
This object specifies configuration related to serverless endpoint. Use this configuration
             when trying to create serverless endpoint and make serverless inference
}
\section{Public fields}{
\if{html}{\out{<div class="r6-fields">}}
\describe{
\item{\code{memory_size_in_mb}}{The memory size of your serverless endpoint.}

\item{\code{max_concurrency}}{The maximum number of concurrent invocations your serverless endpoint can process}
}
\if{html}{\out{</div>}}
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-ServerlessInferenceConfig-new}{\code{ServerlessInferenceConfig$new()}}
\item \href{#method-ServerlessInferenceConfig-to_request_list}{\code{ServerlessInferenceConfig$to_request_list()}}
\item \href{#method-ServerlessInferenceConfig-format}{\code{ServerlessInferenceConfig$format()}}
\item \href{#method-ServerlessInferenceConfig-clone}{\code{ServerlessInferenceConfig$clone()}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ServerlessInferenceConfig-new"></a>}}
\if{latex}{\out{\hypertarget{method-ServerlessInferenceConfig-new}{}}}
\subsection{Method \code{new()}}{
Initialize a ServerlessInferenceConfig object for serverless inference configuration.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ServerlessInferenceConfig$new(memory_size_in_mb = 2048, max_concurrency = 5)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{memory_size_in_mb}}{(int): Optional. The memory size of your serverless endpoint.
Valid values are in 1 GB increments: 1024 MB, 2048 MB, 3072 MB, 4096 MB,
5120 MB, or 6144 MB. If no value is provided, Amazon SageMaker will choose
the default value for you. (Default: 2048)}

\item{\code{max_concurrency}}{(int): Optional. The maximum number of concurrent invocations
your serverless endpoint can process. If no value is provided, Amazon
SageMaker will choose the default value for you. (Default: 5)}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ServerlessInferenceConfig-to_request_list"></a>}}
\if{latex}{\out{\hypertarget{method-ServerlessInferenceConfig-to_request_list}{}}}
\subsection{Method \code{to_request_list()}}{
Generates a request dictionary using the parameters provided to the class.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ServerlessInferenceConfig$to_request_list()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ServerlessInferenceConfig-format"></a>}}
\if{latex}{\out{\hypertarget{method-ServerlessInferenceConfig-format}{}}}
\subsection{Method \code{format()}}{
Format class
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ServerlessInferenceConfig$format()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ServerlessInferenceConfig-clone"></a>}}
\if{latex}{\out{\hypertarget{method-ServerlessInferenceConfig-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ServerlessInferenceConfig$clone(deep = FALSE)}\if{html}{\out{</div>}}
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
