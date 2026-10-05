# Runs the experiments behind the benchmarks article that benchmark.R does not
# cover: the time pspGlobal adds per evaluation, the cost of save = TRUE, and
# how many regions a run finds.
#
# Usage: Rscript benchmarks/experiments.R <library path> <label> <experiments> [output directory]
# <experiments> is a comma-separated subset of overhead,save,discovery.
# Rows are appended to overhead.csv, save.csv and discovery.csv in the output
# directory (default benchmarks/results).

args <- commandArgs(trailingOnly = TRUE)
.libPaths(c(args[1], .libPaths()))
suppressMessages(library(psp))
build <- args[2]
experiments <- strsplit(args[3], ",")[[1]]
out_dir <- if (length(args) >= 4) args[4] else file.path("benchmarks", "results")

emit <- function(name, rows) {
  path <- file.path(out_dir, paste0(name, ".csv"))
  write.table(cbind(build = build, rows), path, sep = ",", row.names = FALSE,
              col.names = !file.exists(path), append = file.exists(path))
}

## a cheap model with `regions` Voronoi cells
voronoi <- function(regions, dimensions) {
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

## overhead: a near-free model, so any time not spent calling it is pspGlobal's
if ("overhead" %in% experiments) {
  d <- 5
  w <- 4^(0:(d - 1))
  model <- function(par) as.numeric(par)
  discretize <- function(x) matrix(sum(floor(x * 3.999) * w), 2, 2)
  ctrl <- list(
    iterations = 150, population = 1e9, radius = 0.3,
    lower = rep(0, d), upper = rep(1, d), init = matrix(0.5, 1, d),
    parameter_names = paste0("p", 1:d), stimuli_names = paste0("s", 1:d),
    dimensionality = 2, responses = d
  )
  for (rep in 1:3) {
    set.seed(rep)
    time <- system.time(out <- pspGlobal(model, discretize, ctrl, quiet = TRUE))[["elapsed"]]
    n <- sum(out$ordinal_counts)
    # the same number of calls to model and discretize from a plain R loop
    points <- matrix(runif(d * n), ncol = d)
    calls <- system.time(
      for (i in seq_len(n)) discretize(model(points[i, , drop = FALSE]))
    )[["elapsed"]]
    emit("overhead", data.frame(
      rep = rep, evaluations = n, patterns = dim(out$ordinal_patterns)[3],
      total_us = 1e6 * time / n, callbacks_us = 1e6 * calls / n,
      framework_us = 1e6 * (time - calls) / n
    ))
  }
}

## save: extra cost of save = TRUE with 300 model outputs per evaluation
if ("save" %in% experiments) {
  v <- voronoi(300, 5)
  ctrl <- v$control(100, 1e6)
  path <- file.path(tempdir(), "psp_experiments_save")
  for (seed in 1:3) {
    set.seed(seed)
    with_save <- system.time(
      out <- pspGlobal(v$model, v$discretize, ctrl, save = TRUE, path = path, quiet = TRUE)
    )[["elapsed"]]
    set.seed(seed)
    without <- system.time(pspGlobal(v$model, v$discretize, ctrl, quiet = TRUE))[["elapsed"]]
    n <- sum(out$ordinal_counts)
    files <- paste0(path, c("_parameters.csv", "_continuous.csv"))
    emit("save", data.frame(
      seed = seed, evaluations = n, save_us = 1e6 * (with_save - without) / n,
      total_us = 1e6 * with_save / n, mb = sum(file.size(files)) / 1e6
    ))
  }
}

## discovery: regions found by 30 runs on a 50-region model
if ("discovery" %in% experiments) {
  v <- voronoi(50, 3)
  ctrl <- v$control(500, 10)
  for (seed in 1:30) {
    set.seed(seed)
    time <- system.time(out <- pspGlobal(v$model, v$discretize, ctrl, quiet = TRUE))[["elapsed"]]
    emit("discovery", data.frame(
      seed = seed, seconds = time, iterations = out$iterations,
      regions = dim(out$ordinal_patterns)[3], evaluations = sum(out$ordinal_counts),
      filled = all(out$ordinal_counts >= 10)
    ))
  }
}
