hypercube <- function(d, coord = c(0, 1))
    do.call(expand.grid, replicate(d, coord, simplify = FALSE))
