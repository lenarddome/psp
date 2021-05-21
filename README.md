# PSP

Parameter Space Partitioning MCMC for Global Model Evaluation (Pitt, Kim, Navarro
& Myung, 2006)

## Install

**This package is in heavy development. Use it at your own risk!**

```
devtools::install_github("lenarddome/psp")
```

## Philosophy

A big influence on this implementation is an instantiation of the Open Models
Initiative, [catlearn](https://github.com/ajwills72/catlearn).

Watch the talk of [Andy Wills: “The OpenModels project”](https://youtu.be/SfqkqEYagJU)
from Open Research Working Group (ORWG) virtual meeting 08/09/20.

The project's architecture is also influenced by [DEoptim](https://github.com/ArdiaD/DEoptim).
`DEoptim` implements a Differential Evolutionary Optimization algorithm for
model-fitting.

We are completely open-source and free. Anyone can contribute. If you would
like to raise an issue or contribute code, use Github, message or email me
(@lenarddome).

## Design [in development]

More about the architecture and coding styles will be added later.`

## Example

Here is an example, using a two parameter model. We want PSP to find 10 distinct
predefined regions.

```r
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

#' dummy polytope model to test the PSP function
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
        if (i %% 2 == 0) {
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
# the clusters, because psp_global will run parallel.
out <- psp_global(model, psp_control(lower = rep(0, 2),
                                   upper = rep(1, 2),
                                   init = rep(0.5, 2),
                                   radius = rep(0.25, 2),
                                   pop = 300,
                                   cluster_names = c("positions",
                                                     "euclidean"),
                                   iterations = 500))
```

This process produces us the following result:

```r
$ps_patterns

  1   2   3   4   5   6   7   8   9  10
300 344 317 306 359 358 307 396 416 397
```

In this case, psp_global stopped before it reached the 500th iteration, because
all regions reached at least 300 `pop`. We can also see that some regions have a
population larger than 300. This is because even though the sampling from that
regions stopped, new points can still be classed as members of those regions.

This is how it looks under the hood in real time:

![Youtube Video](https://youtu.be/xkfKJO2ViWI)

Each colour is a separate region.

## Notes for the curious

### Calculating Volume \[will not be included]

Not feasible to implement a method that generalizes to n-dimensional polyhedra
or convex polytope. There are already packages out there that can do it. I would
leave it for the user. The method of calculating the volume/area of each region
should be an explicit choice the modeller makes.

### BURN-IN \[will not be implemented]

If you have a decent starting point (e.g. parameters EXIT uses to produce inverse
base-rate effect, or ALCOVE best-fitting parameters for the Type I-VI problems),
burn-in is unnecessary.

I am also not sure why burn-in is necessary for parameter space partitioning.
It seems counter-intuitive to discard areas you explored in the parameter space
if you'd like to explore said parameter space.

One problem we might encounter is that *regions further away from our starting
jumping distribution will be under-sampled*. This could be avoided by increasing the number
of `iterations`, so the MCMC will sample long enough to adequately populate
those regions as well. One might also choose to decrease the radius to
sample from smaller areas surrounding the jumping distributions.

Resources to look through:

*   https://stats.stackexchange.com/questions/88819/mcmc-methods-burning-samples
*   http://users.stat.umn.edu/%7Egeyer/mcmc/burn.html
*   https://www.johndcook.com/blog/2016/01/25/mcmc-burn-in/
