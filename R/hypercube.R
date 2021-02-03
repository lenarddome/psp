# This function tests whether the PSP finds all ordinal patterns in the
# parameter space

source("PSPglobal.R")

#' dummy model using hypercubes to test the PSP function
#' The model takes in a set of coordinates, calculates its distance from all
#' all of available coordinates, then return closest region number
#'
#' @param x a vector of coordinates
#' @return The number of the region as character
#' @examples
#' model(runif(5))
model <- function(x) {
    foo <- seq(0, length(x), length.out = 200)
    region <- which.min(abs(sum(x) - foo))
    return(as.character(region))
}

# run Parameter Space Partitioning
out <- PSPglobal(model, PSPcontrol(lower = rep(0, 5),
                                   upper = rep(1, 5),
                                   init = rep(0.5, 5),
                                   radius = rep(0.25, 5),
                                   pop = 300,
                                   iterations = 500))

if (length(out[[2]]) == 100) {
    print(paste("Test is successful, as PSP found 100 out of 100 patterns."))
    print(out[[2]])
} else {
    print(paste("PSP did not find all patterns, pls increasing either the",
                "radius or the pop parameter. Alternatively, contact hacker."))
}
