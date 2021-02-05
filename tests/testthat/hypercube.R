context("PSPglobal")

# euclidean distance
euclidean <- function(a, b) sqrt(sum((a - b)^2))

# region centers
positions <- NULL
for (i in seq_len(5)) positions <- cbind(positions, sample(500, 100))

#' dummy model using hypercubes to test the PSP function
#' The model takes in a set of coordinates, calculates its distance from all
#' all of available coordinates, then return closest region number
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

# run Parameter Space Partitioning
out <- PSPglobal(model, PSPcontrol(lower = rep(0, 10),
                                   upper = rep(1, 10),
                                   init = rep(0.5, 10),
                                   radius = rep(0.15, 10),
                                   pop = 200,
                                   cluster_names = c("positions",
                                                     "euclidean"),
                                   iterations = 500))

test_that("PSP finds all 100 regions in a 5 parameter model",
          {expect_equal(length(out[[2]]), 100)
})
