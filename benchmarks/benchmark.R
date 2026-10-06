# Benchmarks pspGlobal on a fixed set of workloads.
#
# Usage: Rscript benchmarks/benchmark.R [library path] [label]
# The library path selects which installed build of psp to benchmark, so two
# builds can be compared by running the script once for each.
# Prints one csv row per run.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 1) .libPaths(c(args[1], .libPaths()))
label <- if (length(args) >= 2) args[2] else "psp"
suppressMessages(library(psp))

## the model used in tests/testthat/test_psp_cpp.R
euclidean <- function(a, b) sqrt(sum((a - b)^2))
positions <- NULL
set.seed(7624)
for (i in seq_len(5)) positions <- cbind(positions, sample(500, 100))
test_model <- function(par) {
  areas <- NULL
  for (i in seq_along(par)) {
    range <- c(1, 0)
    if (i %% 2 == 0) range <- c(0, 1)
    areas <- cbind(areas, seq(range[1], range[2], length.out = 500)[positions[, i]])
  }
  apply(areas, 1, euclidean, b = par)
}
test_discretize <- function(distances) matrix(which.min(distances), 2, 2)
test_control <- list(
  iterations = 1000, population = 10, radius = 1,
  lower = rep(0, 5), upper = rep(1, 5),
  init = matrix(rep(seq(0, 1, length.out = 10), 5), nrow = 10, byrow = TRUE),
  parameter_names = c("a", "d", "z", "y", "x"), stimuli_names = as.character(seq(100)),
  dimensionality = 2, responses = 100
)

## a cheap model with `regions` Voronoi cells, so that the cost of pspGlobal
## itself dominates
voronoi <- function(regions, dimensions = 5) {
  set.seed(7624)
  centres <- t(matrix(runif(regions * dimensions), nrow = regions))
  list(
    model = function(par) colSums((centres - as.numeric(par))^2),
    discretize = function(distances) matrix(which.min(distances), 2, 2),
    control = function(iterations, population) list(
      iterations = iterations, population = population, radius = 0.3,
      lower = rep(0, dimensions), upper = rep(1, dimensions),
      init = matrix(0.5, nrow = 1, ncol = dimensions),
      parameter_names = paste0("p", seq_len(dimensions)),
      stimuli_names = paste0("s", seq_len(regions)),
      dimensionality = 2, responses = regions
    )
  )
}

run <- function(workload, model, discretize, control, seeds, save = FALSE) {
  for (seed in seeds) {
    set.seed(seed)
    path <- file.path(tempdir(), "psp_benchmark")
    time <- system.time(
      out <- pspGlobal(model, discretize, control, save = save, path = path, quiet = TRUE)
    )[["elapsed"]]
    cat(sprintf("\"%s\",\"%s\",%d,%.4f,%d,%d,%d,%d\n", label, workload, seed, time,
                out$iterations, dim(out$ordinal_patterns)[3],
                as.integer(sum(out$ordinal_counts)),
                as.integer(all(out$ordinal_counts >= control$population))))
  }
}

cat("\"build\",\"workload\",\"seed\",\"seconds\",\"iterations\",\"patterns\",\"evaluations\",\"filled\"\n")
run("test model, pop 10", test_model, test_discretize, test_control, 1:10)
v <- voronoi(100)
run("100 regions, pop 20, cap 1500", v$model, v$discretize, v$control(1500, 20), 1:5)
v <- voronoi(300)
run("300 regions, 100 iterations", v$model, v$discretize, v$control(100, 1e6), 1:3)
run("300 regions, 100 iterations, save", v$model, v$discretize, v$control(100, 1e6), 1:3,
    save = TRUE)
v <- voronoi(1000)
run("1000 regions, 100 iterations", v$model, v$discretize, v$control(100, 1e6), 1:3)
