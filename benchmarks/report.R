# Builds the benchmark report for the website from the results in
# benchmarks/results and the page template benchmarks/report.html.
#
# Usage: Rscript benchmarks/report.R
# Writes pkgdown/assets/benchmarks/index.html, which pkgdown copies to the site.
#
# To re-measure, install each build of psp into its own library, then for each:
#   Rscript benchmarks/benchmark.R <library> <label> | tail -n +2 >> benchmarks/results/workloads.csv
#   Rscript benchmarks/experiments.R <library> <label> overhead,save[,discovery]
# using the labels below, and update `measured` to match the machine.

library(jsonlite)

results <- file.path("benchmarks", "results")
read <- function(name) read.csv(file.path(results, paste0(name, ".csv")))
med <- function(x) as.numeric(median(x))

old_build <- "1.0.5"
new_build <- "cf77c56"
measured <- list(
  machine = "Apple M2 Pro, 10 cores, 16 GB, macOS 27.0.1",
  r = "4.6.1, single-threaded",
  compiler = "Apple clang 21.0.0, -O2",
  packages = "Rcpp 1.1.2, RcppArmadillo 15.6.0.1",
  date = "5 October 2026"
)

## time per run
workloads <- read("workloads")
workload_rows <- list(
  list(key = "test model, pop 10", label = "Test-suite model",
       detail = "100 regions, 5 parameters, population 10"),
  list(key = "100 regions, pop 20, cap 1500", label = "100 regions",
       detail = "cheap model, population 20, cap 1,500"),
  list(key = "300 regions, 100 iterations", label = "300 regions",
       detail = "cheap model, 100 iterations"),
  list(key = "300 regions, 100 iterations, save", label = "300 regions, saving",
       detail = "the same with save = TRUE"),
  list(key = "1000 regions, 100 iterations", label = "1,000 regions",
       detail = "cheap model, 100 iterations")
)
runs <- function(build, key) workloads[workloads$build == build & workloads$workload == key, ]
workload_data <- lapply(workload_rows, function(w) {
  list(label = w$label, detail = w$detail, seeds = nrow(runs(new_build, w$key)),
       old = med(runs(old_build, w$key)$seconds), new = med(runs(new_build, w$key)$seconds))
})
capped <- list(old = med(runs(old_build, workload_rows[[2]]$key)$evaluations),
               new = med(runs(new_build, workload_rows[[2]]$key)$evaluations))

## time per evaluation with a near-free model
overhead <- read("overhead")
overhead_data <- lapply(c(old_build, "fe188ef", "ee4e8b7", new_build), function(b) {
  d <- overhead[overhead$build == b, ]
  list(label = b, mono = b != old_build, old = b == old_build, value = med(d$framework_us),
       total = med(d$total_us), callbacks = med(d$callbacks_us), evaluations = med(d$evaluations))
})

## cost of saving
save <- read("save")
save_rows <- list(
  list(build = old_build, label = "1.0.5", detail = "ostream, 6 digits", old = TRUE),
  list(build = "fe188ef", label = "fe188ef", detail = "ostream, 15 digits", old = FALSE),
  list(build = "ee4e8b7", label = "ee4e8b7", detail = "ostream, 15 digits", old = FALSE),
  list(build = new_build, label = "cf77c56, to_chars", detail = "exact, shortest form", old = FALSE),
  list(build = "cf77c56-fallback", label = "cf77c56, fallback", detail = "exact, %.17g", old = FALSE)
)
save_data <- lapply(save_rows, function(s) {
  d <- save[save$build == s$build, ]
  list(label = s$label, detail = s$detail, old = s$old, value = med(d$save_us), mb = med(d$mb))
})

## regions found
discovery <- read("discovery")
discovery_data <- lapply(c(old_build, new_build), function(b) {
  d <- discovery[discovery$build == b, ]
  list(label = if (b == old_build) "1.0.5" else "1.0.6", old = b == old_build,
       runs = lapply(seq_len(nrow(d)), function(i) list(
         seed = d$seed[i], regions = d$regions[i], evaluations = d$evaluations[i],
         iterations = d$iterations[i], filled = isTRUE(as.logical(d$filled[i])))),
       median = list(regions = med(d$regions), evaluations = med(d$evaluations)))
})

## headline figures
figures <- list(
  list(label = "Time per evaluation, near-free model",
       value = sprintf("%.1f µs", overhead_data[[4]]$total),
       from = sprintf("was %.0f µs in 1.0.5", overhead_data[[1]]$total)),
  list(label = "100-region run",
       value = sprintf("%.3f s", workload_data[[2]]$new),
       from = sprintf("was %.1f s, stopped at the cap", workload_data[[2]]$old)),
  list(label = "Cost of saving, per evaluation",
       value = sprintf("%.0f µs", save_data[[4]]$value),
       from = sprintf("was %.0f µs in 1.0.5", save_data[[1]]$value))
)

## measured separately: an instrumented copy of 1.0.5 on a 300-region model,
## and 30 seeds per setting on the 50-region discovery model
centres <- list(
  list(iterations = 3, patterns = 19, rows = 32, correct = 10),
  list(iterations = 5, patterns = 26, rows = 56, correct = 15),
  list(iterations = 10, patterns = 48, rows = 167, correct = 25),
  list(iterations = 25, patterns = 145, rows = 920, correct = 92),
  list(iterations = 100, patterns = 300, rows = 7890, correct = 300)
)
settings <- list(
  list(label = "1 start, population 10, radius 0.3", found = "45–50, median 49", all = 11, evals = 665),
  list(label = "10 random starts, population 10", found = "44–50, median 49", all = 8, evals = 649),
  list(label = "1 start, population 30", found = "49–50, median 50", all = 29, evals = 1908),
  list(label = "1 start, population 10, radius 0.5", found = "48–50, median 50", all = 24, evals = 874),
  list(label = "10 random starts, population 30", found = "49–50, median 50", all = 27, evals = 1874),
  list(label = "3 pooled runs of 10 starts, population 10", found = "49–50, median 50", all = 29, evals = 1957)
)
environment <- list(
  c("Machine", measured$machine),
  c("R", measured$r),
  c("Compiler", measured$compiler),
  c("Packages", measured$packages),
  c("Builds", paste("1.0.5 (b055424) and the three code commits merged in pull request #6;",
                    "the fallback build is cf77c56 compiled for macOS 11")),
  c("Date", measured$date)
)
definitions <- list(
  c("Test-suite model", "the model from tests/testthat/test_psp_cpp.R: distances to 100 points, 5 parameters",
    "population 10, radius 1, cap 1,000, 10 starting points, 10 seeds"),
  c("100 regions", "cheap Voronoi model: squared distance to 100 random centres, 5 parameters",
    "population 20, radius 0.3, cap 1,500, one start at 0.5, 5 seeds"),
  c("300 and 1,000 regions", "the same cheap model with 300 or 1,000 centres",
    "100 iterations, population never reached, radius 0.3, 3 seeds"),
  c("Overhead", "returns its parameters; discretize bins them into 1,024 grid cells",
    "150 iterations, 3 repeats"),
  c("Discovery", "cheap Voronoi model, 50 centres, 3 parameters",
    "population 10, radius 0.3, cap 500, 30 seeds")
)

data <- list(
  figures = figures, workloads = workload_data, overhead = overhead_data,
  callbacks_us = med(overhead$callbacks_us), save = save_data, discovery = discovery_data,
  centres = centres, settings = settings, environment = environment, definitions = definitions,
  capped = capped,
  footer = sprintf("psp 1.0.6 benchmarks · measured %s · data and scripts in benchmarks/ on GitHub",
                   measured$date)
)

template <- readLines(file.path("benchmarks", "report.html"), warn = FALSE, encoding = "UTF-8")
page <- sub("/*DATA*/null", toJSON(data, auto_unbox = TRUE, digits = 6), template, fixed = TRUE)
out <- file.path("pkgdown", "assets", "benchmarks", "index.html")
dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
writeLines(page, out, useBytes = TRUE)
cat("wrote", out, "\n")
