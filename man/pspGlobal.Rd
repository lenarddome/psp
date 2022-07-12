\name{pspGlobal}
\alias{pspGlobal}
\title{Parameter Space Partitioning}

\description{
  An all-purpose RcppArmadillo implementation of the Parameter Space Partitioning MCMC
  Algorithm described by Pitt, Kim, Navarro, Myung (2006).
}

\usage{
pspGlobal(model, control, save = FALSE, path = ".", quiet = FALSE)
}

\arguments{
  \item{model}{The ordinal function. It should take a numeric vector (parameter set)
      as its argument, and return an inequality matrix (Dome & Wills, n.d.) in a \code{matrix} format with `type=double`. NA values are allowed, see Note 2.}
  \item{control}{A \code{list()} of control arguments that tunes the behaviour of the parameter space partitioning routine. See Details for more information on what to include.}
  \item{save}{if \code{save = TRUE}, all evaluated parameters will be saved to disk. The deafult is \code{FALSE}.}
  \item{path}{If `save = TRUE`, the path to the file that will store all evaluated parameters. The default path is the current working directory.}
  \item{quiet}{If \code{FALSE} (default), print the number of the current iteration. If \code{TRUE}, do not print anything.}
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

    \code{population}{The number of parameter sets in each ordinal region, which serves as a threshold above which pspGlobal will not generate a new jumping distribution for a given ordinal pattern.}
    \code{iterations}{The number of global iterations.}
    \code{lower, upper}{Vectors specifiying the lower and upper boundaries of
        the parameter space for each parameter. The i-th element of lower and
        upper bounds applies to the i-th parameter.}
    \code{init}{A vector of parameters to use as the first jumping
        distribution.}
    \code{radius}{The radius of the hypershere with n-dimensions to sample from.
    Must be of type double.}
    \code{param_names}{A character vector that includes the names of each parameter.}

}

\value{

The output is a list with the following items:

    \item{ordinal_patterns}{A table with the ordinal patterns discovered and the
    population of their corresponding region - the number of parameter sets
    discovered to produce the ordinal pattern.}

    \item{ordinal_counts}{A 3D array with the ordinal patterns found.
    The place of the ordinal pattern corresponds to ordinal_patterns.}

}

\keyword{computational modelling; parameter space partitioning; model evaluation}

\references{

    Dome, L., Wills, A. J. (n.d.) g-distance: Prediction, accommodation, and \emph{a priori} likelihood in formal psychological theorizing. \emph{Manuscript in preparation}.

    Pitt, M. A., Kim, W., Navarro, D. J., & Myung, J. I. (2006). Global model analysis by parameter space partitioning. Psychological Review, 113(1), 57.

    Weisstein, Eric W. "Hypersphere Point Picking." From MathWorld--A Wolfram Web Resource. https://mathworld.wolfram.com/HyperspherePointPicking.html

}

\note{

1. NA values are usually a result of some parameter combination falling outside of what the model implementation can handle. It is best handled outside of the psp routine, e.g. during the inequality matrix construction. For example, if NA is detected in the matrix, change all values to 99 before returning the output.

}
