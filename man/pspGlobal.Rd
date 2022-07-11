\name{pspGlobal}
\alias{pspGlobal}
\title{Parameter Space Partitioning}

\description{
  An all-purpose implementation of the Parameter Space Partitioning MCMC
  Algorithm described by Pitt, Kim, Navarro, Myung (2006).
}

\usage{
pspGlobal(model, control, save, path, quiet = FALSE)
}

\arguments{
  \item{model}{The ordinal function. It should take a numeric vector (parameter set)
      as its argument, and return an inequality matrix in a `data.matrix` format with `type=double`. NA values are allowed, see Note 1.}
  \item{control}{A `list()` of control arguments that tunes the behaviour of the parameter space partitioning routine. See Details for more information on what to include.}
  \item{save}{Whether you want all evaluated parameters to be saved to the disk.}
  \item{path}{If `save = TRUE`, the path to the file that will store all evaluated parameters.}
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
    parameter set for a given pattern. Clamp parameter values with their respective lower and upper bounds.

    2. Evaluate model on all new parameter sets.

    3. Record new patterns and their corresponding parameter sets. If the
    parameter sets returns an already discovered pattern, add parameter set
    to their records. Return to Step 1.

    This behaviour is further tuned by `control`, which needs to contain the following values:

}

\value{

The output is a list with the following items:

    \item{ordinal_patterns}{A table with the ordinal patterns discovered and the
    population of their corresponding region - the number of parameter sets
    discovered to produce the ordinal pattern.}

    \item{ordinal_counts}{A list (if ordinal patterns are multidimensional objects)
    or character vector (if ordinal patterns are strings or other single values)
    with the ordinal patterns found. The place of the ordinal pattern
    corresponds to the names in ps_patterns.}

}

\keyword{computational modelling; parameter space partitioning; model evaluation}

\references{

    Pitt, M. A., Kim, W., Navarro, D. J., & Myung, J. I. (2006). Global model analysis by parameter space partitioning. Psychological Review, 113(1), 57.

    Weisstein, Eric W. "Hypersphere Point Picking." From MathWorld--A Wolfram Web Resource. https://mathworld.wolfram.com/HyperspherePointPicking.html

}

\note{

1. NA values are usually a result of some parameter combination falling outside of what the model implementation can handle. It is best handled outside of the psp routine, during the inequality matrix construction. For example, if NA is detected in the matrix, change all values to 99 before returning the output.

}
