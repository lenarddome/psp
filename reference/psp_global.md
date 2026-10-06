# Parameter Space Partitioning

An all-purpose implementation of the Parameter Space Partitioning MCMC
Algorithm described by Pitt, Kim, Navarro, Myung (2006).

## Usage

``` r
psp_global(fn, control = psp_control(), ..., quiet = FALSE)
```

## Arguments

- fn:

  The ordinal function. It should take a numeric vector (parameter set)
  as its argument, and return an ordinal response pattern as character
  (e.g. "A \> B"). NA values are not currently allowed.

- control:

  a list of control parameters, see `psp_control`

- ...:

  Additional arguments passed to `fn`.

- quiet:

  If `FALSE` (default), print the total number of patterns found up to
  the current iteration. If `TRUE`, do not print anything.

## Details

This function implements the Parameter Space Partitioning algorithm
desribed by Pitt et al. (2006). The algorithm is as follows:

0\. Initialize parameter space.

0\. Select first set of parameters, and evaluate the model on this set.
Its ordinal output will become the first ordinal pattern and the first
region in the parameter space.

1\. Pick a random jumping distribution from for each ordinal pattern
from the sampling region defined by a hypershere with a center of the
last recorded parameter set for a given pattern.

2\. Evaluate model on all new parameter sets.

3\. Record new patterns and their corresponding parameter sets. If the
parameter sets returns an already discovered pattern, add parameter set
to their records. Return to Step 1.

This process runs can run in parallel for each discovered pattern.

## Value

The output of function `psp` is a member of the `S3` class of `PSP`. A
`PSP` object is a list with the following items:

- ps_partitions:

  A `data.table` containing coordinates from the parameter space and
  their corresponding ordinal response pattern output by `fn`. Columns
  include (in this order): parameter coordinates, their ordinal pattern
  output by `fn`, the global iteration of the MCMC. Each row corresponds
  with the evaluation of a single set of parameters.

- ps_patterns:

  A table with the ordinal patterns discovered and the population of
  their corresponding region - the number of parameter sets discovered
  to produce the ordinal pattern.

- ps_ordinal:

  A list (if ordinal patterns are multidimensional objects) or character
  vector (if ordinal patterns are strings or other single values) with
  the ordinal patterns found. The place of the ordinal pattern
  corresponds to the names in ps_patterns.

## References

Pitt, M. A., Kim, W., Navarro, D. J., & Myung, J. I. (2006). Global
model analysis by parameter space partitioning. Psychological Review,
113(1), 57.

Weisstein, Eric W. "Hypersphere Point Picking." From MathWorld–A Wolfram
Web Resource. https://mathworld.wolfram.com/HyperspherePointPicking.html

## Examples

``` r

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
# the clusters, because PSPglobal is currently parallelized.
out <- psp_global(model, psp_control(lower = rep(0, 2),
                                   upper = rep(1, 2),
                                   init = rep(0.5, 2),
                                   radius = rep(0.25, 2),
                                   pop = 100,
                                   parallel = FALSE,
                                   iterations = 100))
#> Warning: This function is no longer maintained and is scheduled for removal.
#> Please use pspGlobal instead.
#> [1] "iteration [2]: found 1"
#> [1] "iteration [3]: found 1"
#> [1] "iteration [4]: found 1"
#> [1] "iteration [5]: found 1"
#> [1] "iteration [6]: found 1"
#> [1] "iteration [7]: found 1"
#> [1] "iteration [8]: found 1"
#> [1] "iteration [9]: found 1"
#> [1] "iteration [10]: found 2"
#> [1] "iteration [11]: found 2"
#> [1] "iteration [12]: found 2"
#> [1] "iteration [13]: found 3"
#> [1] "iteration [14]: found 3"
#> [1] "iteration [15]: found 3"
#> [1] "iteration [16]: found 3"
#> [1] "iteration [17]: found 3"
#> [1] "iteration [18]: found 3"
#> [1] "iteration [19]: found 3"
#> [1] "iteration [20]: found 3"
#> [1] "iteration [21]: found 3"
#> [1] "iteration [22]: found 3"
#> [1] "iteration [23]: found 3"
#> [1] "iteration [24]: found 3"
#> [1] "iteration [25]: found 3"
#> [1] "iteration [26]: found 3"
#> [1] "iteration [27]: found 3"
#> [1] "iteration [28]: found 3"
#> [1] "iteration [29]: found 3"
#> [1] "iteration [30]: found 4"
#> [1] "iteration [31]: found 5"
#> [1] "iteration [32]: found 5"
#> [1] "iteration [33]: found 5"
#> [1] "iteration [34]: found 6"
#> [1] "iteration [35]: found 6"
#> [1] "iteration [36]: found 6"
#> [1] "iteration [37]: found 6"
#> [1] "iteration [38]: found 6"
#> [1] "iteration [39]: found 6"
#> [1] "iteration [40]: found 6"
#> [1] "iteration [41]: found 6"
#> [1] "iteration [42]: found 6"
#> [1] "iteration [43]: found 6"
#> [1] "iteration [44]: found 6"
#> [1] "iteration [45]: found 6"
#> [1] "iteration [46]: found 6"
#> [1] "iteration [47]: found 6"
#> [1] "iteration [48]: found 6"
#> [1] "iteration [49]: found 6"
#> [1] "iteration [50]: found 6"
#> [1] "iteration [51]: found 6"
#> [1] "iteration [52]: found 6"
#> [1] "iteration [53]: found 6"
#> [1] "iteration [54]: found 6"
#> [1] "iteration [55]: found 6"
#> [1] "iteration [56]: found 6"
#> [1] "iteration [57]: found 7"
#> [1] "iteration [58]: found 7"
#> [1] "iteration [59]: found 7"
#> [1] "iteration [60]: found 7"
#> [1] "iteration [61]: found 7"
#> [1] "iteration [62]: found 7"
#> [1] "iteration [63]: found 7"
#> [1] "iteration [64]: found 7"
#> [1] "iteration [65]: found 7"
#> [1] "iteration [66]: found 7"
#> [1] "iteration [67]: found 7"
#> [1] "iteration [68]: found 7"
#> [1] "iteration [69]: found 7"
#> [1] "iteration [70]: found 7"
#> [1] "iteration [71]: found 7"
#> [1] "iteration [72]: found 7"
#> [1] "iteration [73]: found 7"
#> [1] "iteration [74]: found 7"
#> [1] "iteration [75]: found 7"
#> [1] "iteration [76]: found 7"
#> [1] "iteration [77]: found 7"
#> [1] "iteration [78]: found 7"
#> [1] "iteration [79]: found 7"
#> [1] "iteration [80]: found 7"
#> [1] "iteration [81]: found 7"
#> [1] "iteration [82]: found 7"
#> [1] "iteration [83]: found 7"
#> [1] "iteration [84]: found 7"
#> [1] "iteration [85]: found 7"
#> [1] "iteration [86]: found 7"
#> [1] "iteration [87]: found 7"
#> [1] "iteration [88]: found 7"
#> [1] "iteration [89]: found 7"
#> [1] "iteration [90]: found 7"
#> [1] "iteration [91]: found 7"
#> [1] "iteration [92]: found 7"
#> [1] "iteration [93]: found 7"
#> [1] "iteration [94]: found 7"
#> [1] "iteration [95]: found 7"
#> [1] "iteration [96]: found 7"
#> [1] "iteration [97]: found 7"
#> [1] "iteration [98]: found 7"
#> [1] "iteration [99]: found 7"
#> [1] "iteration [100]: found 7"

print(out)
#> $ps_partitions
#>              parameter_1       parameter_2 pattern iteration
#>                   <char>            <char>  <char>    <char>
#>   1:                 0.5               0.5       7         1
#>   2:   0.385234476140391 0.630369394799851       7         2
#>   3:   0.539346444367987 0.648396427418328       7         3
#>   4:   0.445801448746427 0.622185285611548       7         4
#>   5:   0.440660495597671 0.671269301583488       7         5
#>  ---                                                        
#> 521: 0.00723206679748385 0.181897542927365       3       100
#> 522:   0.538673679852089 0.088850500564849       6       100
#> 523:   0.545161555436551 0.115720181571233       6       100
#> 524:   0.455138646873899 0.351670142120917       2       100
#> 525:   0.433449147890542 0.384033113899427       2       100
#> 
#> $ps_patterns
#> pattern
#>  1  2  3  4  6  7  8 
#> 82 72 35 57 93 93 93 
#> 
#> $ps_ordinal
#> [1] "1" "2" "3" "4" "6" "7" "8"
#> 
```
