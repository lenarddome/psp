# shared toy models for the pspGlobal tests

# Voronoi model: the unit hypercube is split into `regions` cells, and the
# ordinal pattern is the index of the cell centre closest to the parameters
voronoi_model <- function(regions, dimensions, seed = 7624) {
  set.seed(seed)
  centres <- t(matrix(runif(regions * dimensions), nrow = regions))
  list(
    model = function(par) colSums((centres - as.numeric(par))^2),
    discretize = function(distances) matrix(which.min(distances), 2, 2)
  )
}

voronoi_control <- function(regions, dimensions, iterations, population,
                            radius = 0.3, init = NULL) {
  if (is.null(init)) init <- matrix(0.5, nrow = 1, ncol = dimensions)
  list(
    iterations = iterations, population = population, radius = radius,
    lower = rep(0, dimensions), upper = rep(1, dimensions), init = init,
    parameter_names = paste0("p", seq_len(dimensions)),
    stimuli_names = paste0("s", seq_len(regions)),
    dimensionality = 2, responses = regions
  )
}

# reads the csv files written by pspGlobal(save = TRUE)
read_psp_output <- function(path) {
  read <- function(suffix) {
    out <- read.csv(paste0(path, suffix, ".csv"))
    out[, colnames(out) != "X", drop = FALSE] # drop trailing-comma column
  }
  list(parameters = read("_parameters"), continuous = read("_continuous"))
}
