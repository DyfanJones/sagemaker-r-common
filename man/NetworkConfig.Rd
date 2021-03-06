% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/network.R
\name{NetworkConfig}
\alias{NetworkConfig}
\title{NetworkConfig class}
\description{
Accepts network configuration parameters and provides a method to turn these parameters
             into a dictionary.
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-NetworkConfig-new}{\code{NetworkConfig$new()}}
\item \href{#method-NetworkConfig-to_request_list}{\code{NetworkConfig$to_request_list()}}
\item \href{#method-NetworkConfig-format}{\code{NetworkConfig$format()}}
\item \href{#method-NetworkConfig-clone}{\code{NetworkConfig$clone()}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-NetworkConfig-new"></a>}}
\if{latex}{\out{\hypertarget{method-NetworkConfig-new}{}}}
\subsection{Method \code{new()}}{
Initialize a ``NetworkConfig`` instance. NetworkConfig accepts network configuration
             parameters and provides a method to turn these parameters into a dictionary.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{NetworkConfig$new(
  enable_network_isolation = FALSE,
  security_group_ids = NULL,
  subnets = NULL,
  encrypt_inter_container_traffic = NULL
)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{enable_network_isolation}}{(bool): Boolean that determines whether to enable
network isolation.}

\item{\code{security_group_ids}}{([str]): A list of strings representing security group IDs.}

\item{\code{subnets}}{([str]): A list of strings representing subnets.}

\item{\code{encrypt_inter_container_traffic}}{(bool): Boolean that determines whether to
encrypt inter-container traffic. Default value is None.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-NetworkConfig-to_request_list"></a>}}
\if{latex}{\out{\hypertarget{method-NetworkConfig-to_request_list}{}}}
\subsection{Method \code{to_request_list()}}{
Generates a request dictionary using the parameters provided to the class.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{NetworkConfig$to_request_list()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-NetworkConfig-format"></a>}}
\if{latex}{\out{\hypertarget{method-NetworkConfig-format}{}}}
\subsection{Method \code{format()}}{
format class
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{NetworkConfig$format()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-NetworkConfig-clone"></a>}}
\if{latex}{\out{\hypertarget{method-NetworkConfig-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{NetworkConfig$clone(deep = FALSE)}\if{html}{\out{</div>}}
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
