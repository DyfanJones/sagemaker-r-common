% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/debugger_metrics_config.R
\name{PythonProfilingConfig}
\alias{PythonProfilingConfig}
\title{PythonProfilingConfig Class}
\description{
The configuration for framework metrics to be collected for Python profiling.
}
\section{Super class}{
\code{\link[sagemaker.common:MetricsConfigBase]{sagemaker.common::MetricsConfigBase}} -> \code{PythonProfilingConfig}
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-PythonProfilingConfig-new}{\code{PythonProfilingConfig$new()}}
\item \href{#method-PythonProfilingConfig-clone}{\code{PythonProfilingConfig$clone()}}
}
}
\if{html}{\out{
<details open><summary>Inherited methods</summary>
<ul>
<li><span class="pkg-link" data-pkg="sagemaker.common" data-topic="MetricsConfigBase" data-id="format"><a href='../../sagemaker.common/html/MetricsConfigBase.html#method-MetricsConfigBase-format'><code>sagemaker.common::MetricsConfigBase$format()</code></a></li>
<li><span class="pkg-link" data-pkg="sagemaker.common" data-topic="MetricsConfigBase" data-id="to_json_string"><a href='../../sagemaker.common/html/MetricsConfigBase.html#method-MetricsConfigBase-to_json_string'><code>sagemaker.common::MetricsConfigBase$to_json_string()</code></a></li>
</ul>
</details>
}}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-PythonProfilingConfig-new"></a>}}
\if{latex}{\out{\hypertarget{method-PythonProfilingConfig-new}{}}}
\subsection{Method \code{new()}}{
Choose a Python profiler: cProfile or Pyinstrument.
             Specify target steps or a target duration to profile.
             If no parameter is specified,
             it profiles based on profiling configurations
             preset by the \code{profile_default_steps} parameter,
             which is set to `True` by default.
             If you specify the following parameters,
             then the \code{profile_default_steps} parameter
             will be ignored.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{PythonProfilingConfig$new(
  start_step = NULL,
  num_steps = NULL,
  start_unix_time = NULL,
  duration = NULL,
  profile_default_steps = FALSE,
  python_profiler = PythonProfiler$CPROFILE,
  cprofile_timer = cProfileTimer$TOTAL_TIME
)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{start_step}}{(int): The step to start profiling. The default is step 9.}

\item{\code{num_steps}}{(int): The number of steps to profile. The default is for 3 steps.}

\item{\code{start_unix_time}}{(int): The Unix time to start profiling.}

\item{\code{duration}}{(float): The duration in seconds to profile.}

\item{\code{profile_default_steps}}{(bool): Indicates whether the default configuration
should be used. If set to `True`, Python profiling will be done
at step 9, 10, and 11 of training, using cProfiler
and collecting metrics based on the total time, cpu time,
and off cpu time for these three steps respectively.
The default is ``True``.}

\item{\code{python_profiler}}{(PythonProfiler): The Python profiler to use to collect
python profiling stats. Available options are ``"cProfile"``
and ``"Pyinstrument"``. The default is ``"cProfile"``.
Instead of passing the string values, you can also use the enumerator util,
:class:`~sagemaker.debugger.utils.PythonProfiler`,
to choose one of the available options.}

\item{\code{cprofile_timer}}{(cProfileTimer): The timer to be used by cProfile when collecting
python profiling stats. Available options are ``"total_time"``, ``"cpu_time"``,
and ``"off_cpu_time"``. The default is ``"total_time"``.
If you choose Pyinstrument, this parameter is ignored.
Instead of passing the string values, you can also use the enumerator util,
:class:`~sagemaker.debugger.utils.cProfileTimer`,
to choose one of the available options.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-PythonProfilingConfig-clone"></a>}}
\if{latex}{\out{\hypertarget{method-PythonProfilingConfig-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{PythonProfilingConfig$clone(deep = FALSE)}\if{html}{\out{</div>}}
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
