# This function tests whether the PSP finds all ordinal patterns in the
# parameter space

source("PSPglobal.R")

# https://stackoverflow.com/questions/15367565/creating-hypercube-in-r-for-any-dim-d
# https://stackoverflow.com/users/980833/josh-obrien

#' hypercube formula by Josh O'Brien
#'
#' @param dim Integer specifying the dimensions of the hypercube.
#' @param ticks Integer, specifying the number of regions.
#' @return hypercube coordinates in an n-dimensional space.
#' @examples
#' hypercube(2, 10)
#' hypercube(5, 20)
hypercube <- function(dim, ticks) {
    do.call(expand.grid,
            replicate(dim, seq(0, 1, length.out = ticks), simplify = FALSE))
}

#' dummy model using hypercubes to test the PSP function
#' The model takes in a set of coordinates, calculates its distance from all
#' all of available coordinates, then return closest region number
#'
#' @param x a vector of 5 coordinates
#' @return The number of the region as character
#' @examples
#' model(runif(5))
model <- function(x) {
    cube <- hypercube(5, 20)
    test <- cbind(cube, region = rep(1:ticks, each = ticks))
    colnames(test) <- NULL
    region_index <- which.min(rowSums(abs(x - as.matrix(test[, 1:dim]))))
    region <- test[region_index, dim + 1]
    return(as.character(region))
}

# run Parameter Space Partitioning
out <- PSPglobal(model, PSPcontrol(lower = rep(0, 5),
                                   upper = rep(1, 5),
                                   init = rep(0.5, 5),
                                   radius = rep(0.1, 5),
                                   cluster_names = c("hypercube"),
                                   pop = 200))

if (length(out[[2]]) == 20) {
    print(paste("Test is successful, as PSP found 20 out of 20 patterns."))
    print(out[[2]])
} else {
    print(paste("PSP did not find all patterns, pls increasing either the",
                "radius or the pop parameter. Alternatively, contact hacker."))
}

### Create a graph for fun

library(scatterplot3d)

regs <- hypercube(3, 10)
regs <- cbind(regs, rep(1:10, each = 10))
colnames(regs) <- c("x", "y", "z", "group")
s3d <- with(regs, scatterplot3d(x, y, z, color = as.factor(group),
                                angle = 45, pch = 19))

model <- function(x) {
    cube <- hypercube(3, 5)
    test <- cbind(cube, region = rep(1:ticks, each = ticks))
    colnames(test) <- NULL
    region_index <- which.min(rowSums(abs(x - as.matrix(test[, 1:dim]))))
    region <- test[region_index, dim + 1]
    return(as.character(region))
}

out <- PSPglobal(model, control = PSPcontrol(lower = rep(0,3),
                                             upper = rep(1, 3),
                                             init = rep(0.5, 3),
                                             radius = rep(0.1, 3),
                                             cluster_names = c("hypercube"),
                                             pop = 200))

matr <- out[[1]]

colnames(matr) <- c("x", "y", "z", "group", "iterations")

pdf("scatter3D.pdf")
s3d <- with(matr, scatterplot3d(x, y, z, color = as.factor(group), pch = 19,
                                angle = -45))
s3d
dev.off()
