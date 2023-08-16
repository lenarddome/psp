\name{pspGlobal}
\alias{pspGlobal}
\title{Parameter Space Partitioning}

\description{
  An all-purpose C++ implementation of the Parameter Space Partitioning MCMC
  Algorithm described by Pitt, Kim, Navarro, Myung (2006).
}

\usage{
pspGlobal(model, discretize, control, save = FALSE, path = ".",
          extension = ".csv", quiet = FALSE)
}

\arguments{
  \item{model}{ It should take a numeric vector (parameter set)
   as its argument, and return a numeric vector of continuous variables.}
  \item{discretize}{The inequality matrix constructor. It should take a numberic
   vector of probabilities. It must return a matrix in a \code{matrix} format
   with `type=double`. NA values are note allowed, see Note 1.}
  \item{control}{A \code{list()} of control arguments that tunes the behaviour
   of the parameter space partitioning routine. See Details for more information
   on what to include.}
  \item{save}{if \code{save = TRUE}, all evaluated parameters will be saved to
   disk. The deafult is \code{FALSE}.}
  \item{path}{If `save = TRUE`, the path to the file that will store all
   evaluated parameters and continuous model outputs. The default path is the
   current working directory. Evaluated parameters and continuous model outputs
   are save separately, see Details.}
  \item{extension}{If `save = TRUE`, the extension of the file that will store
   all evaluated parameters and continuous model outputs. The default extension
   is \code{.csv}.}
  \item{quiet}{If \code{FALSE} (default), print the number of the current
   iteration. If \code{TRUE}, do not print anything.}
}

\details{

    \bold{Overview:}

    This function implements the Parameter Space Partitioning algorithm
    desribed by Pitt et al. (2006). The brief overview of the algorithm is as follows:

    0. Initialize parameter space.

    0. Select first set of parameters, and evaluate the model on this set. Its
    ordinal output will become the first ordinal pattern and the first region
    in the parameter space.

    1. Pick a random jumping distribution from for each ordinal pattern from the
    sampling region defined by a hypershere with a center of the last recorded
    parameter set for a given pattern. Clamp parameter values with their
    respective lower and upper bounds.

    2. Evaluate model on all new parameter sets.

    3. Record new patterns and their corresponding parameter sets. If the
    parameter sets returns an already discovered pattern, add parameter set
    to their records. Return to Step 1.

    \bold{Tuning the behaviour of the algorithm via \code{control}:}

    This behaviour is further tuned by `control`, which needs to contain a list of the following values:

    \code{population}{The number of parameter sets in each ordinal region,
        which serves as a threshold above which pspGlobal will not generate
        a new jumping distribution for a given ordinal pattern.}
    \code{iterations}{The number of global iterations. It has to be an integer. If emph{population} is not set or the regions have population less then the upper bound on their size, the function will stop after the set number of \emph{iterations}.}
    \code{lower, upper}{Vectors specifiying the lower and upper boundaries of
        the parameter space for each parameter. The i-th element of lower and
        upper bounds applies to the i-th parameter.}
    \code{init}{A marix of parameters to use as the first jumping distribution. 
        Each row contains the parameter set, whereas columns correspond to 
        freely varying paarameters of the model.}
    \code{radius}{The radius of the hypershere with n-dimensions to sample from.
        Must be of type double. If you are unsure what to set here, set it to 1.}
    \code{parameter_names}{A character vector that includes the names of each parameter.
        The order of elements should correspond to the order of parameter columns in
        init.}
    \code{dimensionality}{A single integer that specifies the number of
         dimensions for the inequality matrix. The inequality matrix is a strict
         upper triangular matrix. The number of rows and columns is equal to each
         other.}
    \code{responses}{It is an integer that specifies the number of continuous
        variables the model output before the ordinal function is applied. See Note 2.}

    \strong{Saving files to disk:}

    The evaluated parameter sets and their corresponding continuous model outputs
    are saved to disk if \code{save = TRUE}. The evaluated parameter sets are saved in
    a file with the name \code{path_parameters} and the extension specified,
    whereas continuous model outputs are saved in a file with the name \code{path_continuous}
    and the extension specified.

    }

\value{

The output is a list with the following items:

    \item{ordinal_patterns}{A 3D array with the ordinal patterns found.
    The place of the ordinal pattern corresponds to ordinal_counts.}

    \item{ordinal_counts}{A table with the ordinal patterns discovered and the
    population of their corresponding region - the number of parameter sets
    discovered to produce the ordinal pattern.}

    \item{iterations}{Number of iterations completed before reaching set
    threshold.}

}

\keyword{computational modelling; parameter space partitioning; model evaluation}

\references{

    Dome, L. (n.d.) psp: an n-dimensional parameter space partitioning tool to explore model behaviour. \emph{Manuscript in preparation}.

    Dome, L., Wills, A. J. (n.d.) g-distance: Prediction, accommodation, and \emph{a priori} likelihood in formal psychological theorizing. \emph{Manuscript in preparation}.

    Pitt, M. A., Kim, W., Navarro, D. J., & Myung, J. I. (2006). Global model analysis by parameter space partitioning. Psychological Review, 113(1), 57.

    Weisstein, Eric W. "Hypersphere Point Picking." From MathWorld--A Wolfram Web Resource. https://mathworld.wolfram.com/HyperspherePointPicking.html

}

\note{

1. NA values are usually a result of some parameter combination falling outside of what the model implementation can handle. It is best handled outside of the PSP routine, e.g. during the inequality matrix construction. For example, if NA is detected in the matrix, change all values to 99 before returning the output.
2. Ideally, responses and dimensionality should be the same, but we can imagine a scenario where the dimensionality of the inequality matrix will be smaller than the number of responses. For example, when continuous variables compressed into a more compact format via clustering. 

}
