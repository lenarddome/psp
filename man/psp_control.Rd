\name{psp_control}
\alias{psp_control}
\title{Control the behaviour of the psp_global implementation}
\description{
    \code{psp_control} allows users to define characteristics of the
    parameter space partitioning MCMC algorithm as implemented in
    \code{psp_global}.
}

\usage{
psp_control(radius = 0.1, init = NULL, lower, upper,
           pop = 400, cl = NULL,
           param_names = NULL,
           parallel = TRUE,
           cluster_names = NULL,
           iterations = 1000)
}

\arguments{
    \item{radius}{The radius of the hypershere with n-dimensions to sample from.
    Must be a double. Default is 0.1.}
    \item{init}{A vector of parameters to use as the first jumping distribution.
        If \code{NULL} (default), parameter search starts from the center of the
        parameter space.}
    \item{lower, upper}{Vectors specifiying the lower and upper boundaries of
        the parameter space for each parameter. The i-th element of lower and
        upper bounds applies to the i-th parameter.}
    \item{pop}{The minimum population psp_global aims to find for each ordinal
        pattern discovered. This can stop the parameter search early in case
        the population of all ordinal pattern are equal to or larger than \code{pop}.
        If you do not want to use this option, set it to \code{NULL} or \code{Inf}.
        Default is \code{400}.}
    \item{parallel}{If TRUE (default), uses the parallel package to run
        evaluations of jumping distributions for each chain parallel.}
    \item{cl}{If parallel is TRUE, the number of cores to use for 
        \code{makeCluster} from the \pkg{parallel} package. If null
        (default), use all cores.}
    \item{param_names}{A character vector that includes the names of each
       parameter. If \code{NULL} (default), a character vector is generated with
    parameter_1, parameter_2, parameter_3", ...}
    \item{cluster_names}{A character vector that includes the list of functions
    to be loaded into each cluster. Default is \code{NULL}}.
    \item{iterations}{The number of global iterations for psp_global. Default is
        1000.}
}

\value{

    Returns a control list suitable for \code{\link{psp_global}} with the above
    elements.

}

\seealso{
    \code{\link{psp_global}}.
}

\examples{
# two parameter model
psp_control(lower = rep(0, 2), upper = rep(1, 2), init = rep(0.5, 2),
           radius = rep(0.25, 2), cluster_names = NULL, 
           parallel = FALSE, iterations = 500)
}
