\name{PSPglobal}
\alias{PSPglobal}
\title{Parameter Space Partitioning}

\description{
  An all-purpose implementation of the Parameter Space Partitioning MCMC 
  Algorithm described by Pitt, Kim, Navarro, Myung (2006).
}

\usage{
PSPglobal(fn, control = PSPcontrol())
}

\arguments{
  \item{fn}{The ordinal function. It should take a numeric vector (parameter set)
      as its argument, and return an ordinal response pattern as character (e.g.
      "A > B"). NA values are allowed, but are discouraged.}
  \item{control}{a list of control parameters, see \code{\link{PSPcontrol}}}
}

\details{}

\value{

Return a list with the following items:

    \item{ps_partitions}{A data frame containing the Parameter Space Partitions
    and their corresponding ordinal response patterns output by \code{fn}. Columns
    include in this order: parameter coordinates, their ordinal pattern output
    by \code{fn}, the global iteration of the MCMC. Each row corresponds
    with the evaluation of a single set of parameters.}
    \item{ps_patterns}{A table with the ordinal patterns discovered and the
    population of their corresponding region - the number of parameter set
    discovered to produce the ordinal pattern.}

}

\seealso{
  \code{\link{PSPcontrol}}.
}

\keyword{computational modelling; parameter space; model evaluation}

\references{

    Pitt, M. A., Kim, W., Navarro, D. J., & Myung, J. I. (2006). Global model analysis by parameter space partitioning. Psychological Review, 113(1), 57.

    Weisstein, Eric W. "Hypersphere Point Picking." From MathWorld--A Wolfram Web Resource. https://mathworld.wolfram.com/HyperspherePointPicking.html

}
