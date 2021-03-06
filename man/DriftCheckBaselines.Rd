% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/drift_check_baselines.R
\name{DriftCheckBaselines}
\alias{DriftCheckBaselines}
\title{DriftCheckBaselines class}
\description{
Accepts drift check baselines parameters for conversion to request dict.
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-DriftCheckBaselines-new}{\code{DriftCheckBaselines$new()}}
\item \href{#method-DriftCheckBaselines-to_request_list}{\code{DriftCheckBaselines$to_request_list()}}
\item \href{#method-DriftCheckBaselines-clone}{\code{DriftCheckBaselines$clone()}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-DriftCheckBaselines-new"></a>}}
\if{latex}{\out{\hypertarget{method-DriftCheckBaselines-new}{}}}
\subsection{Method \code{new()}}{
Initialize a ``DriftCheckBaselines`` instance and turn parameters into dict.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{DriftCheckBaselines$new(
  model_statistics = NULL,
  model_constraints = NULL,
  model_data_statistics = NULL,
  model_data_constraints = NULL,
  bias_config_file = NULL,
  bias_pre_training_constraints = NULL,
  bias_post_training_constraints = NULL,
  explainability_constraints = NULL,
  explainability_config_file = NULL
)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{model_statistics}}{(MetricsSource): A metric source object that represents}

\item{\code{model_constraints}}{(MetricsSource): A metric source object that represents}

\item{\code{model_data_statistics}}{(MetricsSource): A metric source object that represents}

\item{\code{model_data_constraints}}{(MetricsSource): A metric source object that represents}

\item{\code{bias_config_file}}{(FileSource): A file source object that represents bias config}

\item{\code{bias_pre_training_constraints}}{(MetricsSource):}

\item{\code{bias_post_training_constraints}}{(MetricsSource):}

\item{\code{explainability_constraints}}{(MetricsSource):}

\item{\code{explainability_config_file}}{(FileSource): A file source object that represents}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-DriftCheckBaselines-to_request_list"></a>}}
\if{latex}{\out{\hypertarget{method-DriftCheckBaselines-to_request_list}{}}}
\subsection{Method \code{to_request_list()}}{
Generates a request dictionary using the parameters provided to the class.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{DriftCheckBaselines$to_request_list()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-DriftCheckBaselines-clone"></a>}}
\if{latex}{\out{\hypertarget{method-DriftCheckBaselines-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{DriftCheckBaselines$clone(deep = FALSE)}\if{html}{\out{</div>}}
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
