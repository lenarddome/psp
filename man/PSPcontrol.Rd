\name{PSPcontrol}
\alias{PSPcontrol}
\title{Control the behaviour of the PSPglobal implementation}
\description{
    PSPcontrol allows modellers to define characteristics of the
    parameter space partitioning MCMC algorithm as implemented in PSPglobal.
}

\usage{
PSPcontrol(radius = 0.01, init = NULL, lower, upper,
           pop = 400, cl = NULL,
           param_names = NULL,
           cluster_names = NULL,
           iterations = 1000)
}

\arguments{
    \item{radius}{The radius of the unit hypershere with n-dimensions to sample from.
    Must be a double. Default is \code{0.1}.}
    \item{init}{A vector of parameters to use as the first jumpgin distribution.
        If \code{NULL} (default), parameter search starts from the center of the
        parameter space.}
    \item{lower, upper}{Vectors spercifiying the lower and upper boundaries of
        the parameter space for each parameter. The i-th element of lower and
        upper applies to the i-th parameter.}
    \item{pop}{The minimum population PSPglobal aims to produce for each ordinal
        pattern discovered. This can stop the parameter search early in case
        the population of each ordinal pattern are equal to or larger than \code{pop}.
        If you do not want to use this option, set it to \code{NULL} or \code{Inf}.
        Default is \code{400}.}
    \item{cl}{The number of cores to use for \code{\link{makeCluster}} from the
    \code{parallel} pacakge.}
    \item{param_names}{A character vector that includes the names of each parameter.
    If \code{NULL} (default), a character vector is generated with
    \code{"parameter_1", "parameter_2", "parameter_3", ...}}
    \item{cluster_names}{A character vector that includes the list of functions
    to be loaded into each parallel cluster. Default is \code{NULL}}.
    \item{iterations}{The number of global iterations for PSPglobal. Default is
        \code{1000}.}
}

\details{}

\value{

    Returns a control list suitable for \code{\link{PSPglobal}} with the above
    elements.

}

\seealso{
    \code{\link{save}}.
}
\examples{
## save all data
save(list = ls(), file= "all.RData")

## restore the saved values to the current environment
load("all.RData")

## restore the saved values to the workspace
load("all.RData", .GlobalEnv)
}
\keyword{file}

