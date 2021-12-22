\name{PSP-methods}
\alias{print.PSP}
\title{Various methods for the generic S3 class \code{PSP}.}
\usage{
    \method{print}{PSP}(x, \dots)
}
\arguments{
    \item{x}{Object with PSP class}
    \item{\dots}{Additional parameters passed to relevant generic function,
        e.g. \code{print}.}
}
\description{
    The \code{PSP} class is a general S3 class for representing output of a
    parameter space partitioning algorithm as produced by \code{psp_global}.
    These are the various methods built for the \code{PSP} class.
}
\details{
    See \code{\link{psp_global}} for the description of items stored in \code{PSP}.
}
\seealso{
    \code{\link{psp_global}}, \code{\link{print}}
}
