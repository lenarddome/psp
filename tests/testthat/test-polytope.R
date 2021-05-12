# set seed
set.seed(7624)
# region centres
positions <- NULL
for (i in seq_len(5)) positions <- cbind(positions, sample(500, 100))


#' dummy model using polytope to test the PSP function
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
                       seq(range[1], range[2],
                           length.out = 500)[positions[, i]])
    }
    dist <- apply(areas, 1, function(x) sqrt(sum((par - x)^2)))
    return(as.character(which.min(dist)))
}

# run Parameter Space Partitioning
out <- psp_global(model, psp_control(lower = rep(0, 4),
                                     upper = rep(1, 4),
                                     init = rep(0.5, 4),
                                     radius = rep(0.25, 4),
                                     pop = 300,
                                     parallel = FALSE,
                                     iterations = 300))

test_that("PSP finds all 100 regions in a 5 parameter model",
          {expect_equal(length(out[[2]]), 100)
          })
