\name{psp_control}
\alias{psp_control}
\title{Control the behaviour of the psp_global implementation}
\description{
    \code{psp_control} allows users to define characteristics of the
    parameter space partitioning MCMC algorithm as implemented in
    \code{psp_global}.
}

\usage{
psp_control(radius = 0.1, init, lower, upper,
           pop = 400, cl = NULL,
           param_names = NULL,
           parallel = FALSE,
           cluster_names = NULL,
           export_objects = NULL,
           export_libs = NULL,
           iterations = 1000)
}

\arguments{
    \item{radius}{The radius of the hypershere with n-dimensions to sample from.
    Must be a double or a numeric vector, where elements correspond to
    parameters in `init, lower, upper`. Default is 0.1.}
    \item{init}{A vector of parameters to use as the first jumping
        distribution.}
    \item{lower, upper}{Vectors specifiying the lower and upper boundaries of
        the parameter space for each parameter. The i-th element of lower and
        upper bounds applies to the i-th parameter.}
    \item{pop}{The minimum population psp_global aims to find for each ordinal
        pattern discovered. This can stop the parameter search early in case
        the population of all ordinal pattern are equal to or larger than
        \code{pop}. If you do not want to use this option, set it to \code{NULL}
        or \code{Inf}. Default is \code{400}.}
    \item{parallel}{If TRUE, uses the parallel package to run evaluations of
        jumping distributions for each chain parallel. Default value is
        \code{FALSE}.}
    \item{cl}{If parallel is TRUE, the number of cores to use for
        \code{makeCluster} from the \pkg{parallel} package. If null
        (default), use all cores.}
    \item{param_names}{A character vector that includes the names of each
       parameter. If \code{NULL} (default), a character vector is generated with
       parameter_1, parameter_2, parameter_3, ...}
    \item{cluster_names}{Maintained for backwards-compatibility. See
      \code{export_objects} below.}
    \item{export_objects}{A character vector that includes all of the objects
      to be loaded into each cluster. It is handled by
      \code{parallel::clusterExports}. Default is \code{NULL}.}
    \item{export_libs}{A character vector that includes all the packages to
    be loaded into each cluster. It is handled by
      \code{parallel::clusterExports}. Default is \code{NULL}.}
    \item{iterations}{The number of global iterations for psp_global. Default is
        1000.}
}

\value{

    Returns a control list suitable for \code{psp_global} with the above
    elements.

}

\examples{
# two parameter model
psp_control(lower = rep(0, 2), upper = rep(1, 2), init = rep(0.5, 2),
           radius = rep(0.25, 2), cluster_names = NULL,
           parallel = FALSE, iterations = 500)
}
