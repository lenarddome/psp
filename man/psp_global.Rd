\name{psp_global}
\alias{psp_global}
\title{Parameter Space Partitioning}

\description{
  An all-purpose implementation of the Parameter Space Partitioning MCMC
  Algorithm described by Pitt, Kim, Navarro, Myung (2006).
}

\usage{
psp_global(fn, control = psp_control(), ..., quiet = FALSE)
}

\arguments{
  \item{fn}{The ordinal function. It should take a numeric vector (parameter set)
      as its argument, and return an ordinal response pattern as character (e.g.
      "A > B"). NA values are not currently allowed.}
  \item{control}{a list of control parameters, see \code{psp_control}}
  \item{...}{Additional arguments passed to \code{fn}.}
  \item{quiet}{If \code{FALSE} (default), print the total number of patterns
      found up to the current iteration. If \code{TRUE}, do not print anything.}
}

\details{
    This function implements the Parameter Space Partitioning algorithm
    desribed by Pitt et al. (2006). The algorithm is as follows:

    0. Initialize parameter space.

    0. Select first set of parameters, and evaluate the model on this set. Its
    ordinal output will become the first ordinal pattern and the first region
    in the parameter space.

    1. Pick a random jumping distribution from for each ordinal pattern from the
    sampling region defined by a hypershere with a center of the last recorded
    parameter set for a given pattern.

    2. Evaluate model on all new parameter sets.

    3. Record new patterns and their corresponding parameter sets. If the
    parameter sets returns an already discovered pattern, add parameter set
    to their records. Return to Step 1.

    This process runs can run in parallel for each discovered pattern.

}

\value{

The output of function \code{psp} is a member of the \code{S3} class
of \code{PSP}. A \code{PSP} object is a list with the following items:

    \item{ps_partitions}{A \code{data.table} containing coordinates from the
    parameter space and their corresponding ordinal response pattern output by
    \code{fn}. Columns include (in this order): parameter coordinates,
    their ordinal pattern output by \code{fn}, the global iteration of the
    MCMC. Each row corresponds with the evaluation of a single set of
    parameters.}

    \item{ps_patterns}{A table with the ordinal patterns discovered and the
    population of their corresponding region - the number of parameter sets
    discovered to produce the ordinal pattern.}

    \item{ps_ordinal}{A list (if ordinal patterns are multidimensional objects)
    or character vector (if ordinal patterns are strings or other single values)
    with the ordinal patterns found. The place of the ordinal pattern
    corresponds to the names in ps_patterns.}

}

\keyword{computational modelling; parameter space; model evaluation}

\references{

    Pitt, M. A., Kim, W., Navarro, D. J., & Myung, J. I. (2006). Global model analysis by parameter space partitioning. Psychological Review, 113(1), 57.

    Weisstein, Eric W. "Hypersphere Point Picking." From MathWorld--A Wolfram Web Resource. https://mathworld.wolfram.com/HyperspherePointPicking.html

}

\examples{

library(psp)

#' euclidean distance
#'
#' @param a vector coordinate 1
#' @param b vector coordinate 2
#' @return euclidean distance between coordinates
euclidean <- function(a, b) sqrt(sum((a - b)^2))

# define center points for the 10 regions in a two-dimensional space
positions <- NULL
for (i in seq_len(2)) positions <- cbind(positions, sample(500, 10))

#' dummy hypercube model to test the PSP function
#' The model takes in a set of coordinates, calculates its distance from all
#' all of available coordinates, then return closest region number.
#' This model generalizes to n-dimensions
#'
#' @param x a vector of coordinates
#' @return The number of the region as character
#' @examples
#' model(runif(5))
model <- function(par) {
    areas <- NULL
    for (i in seq_along(par)) {
        range <- c(1, 0)
        if (i \%\% 2 == 0) {
            range <- c(0, 1)
        }
        areas <- cbind(areas,
                       seq(range[1], range[2], length.out = 500)[positions[,i]])
    }
    dist <- apply(areas, 1, function(x) euclidean(par, x))
    return(as.character(which.min(dist)))
}

# run Parameter Space Partitioning with some default settings
# Here we run the MCMC for 400 iterations, but the partitioning
# will stop if the population of all regions reach 200.
# Note that we have to load our utility function into
# the clusters, because PSPglobal is currently parallelized.
out <- psp_global(model, psp_control(lower = rep(0, 2),
                                   upper = rep(1, 2),
                                   init = rep(0.5, 2),
                                   radius = rep(0.25, 2),
                                   pop = 100,
                                   parallel = FALSE,
                                   iterations = 100))

print(out)

}
