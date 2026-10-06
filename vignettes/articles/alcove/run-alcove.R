# Runs the PSP analysis of ALCOVE that the ALCOVE recipe reads. It takes
# a while, so the recipe does not run it. Run it from the package root:
#   Rscript vignettes/articles/alcove/run-alcove.R
# By default it runs every stage; to run some of them, list them in
# ALCOVE_STAGES, for example ALCOVE_STAGES=learners. The stages write their
# results next to this file:
#   psp       psp-run.csv.gz      every parameter set the main PSP run evaluated
#   uniform   uniform.csv.gz      parameter sets sampled evenly, for region sizes
#   learners  learners.csv        patterns with 5 and with 20 simulated learners
#                                 (needs uniform.csv.gz)
#   orders    trial-orders.csv    patterns found by PSP with other trial orders
#   volume    volumes.csv         region volumes estimated as in Pitt et al. (2006)
#                                 (needs psp-run.csv.gz)
# Each stage also records its settings and timing in run-info.csv.

library(psp)
source(file.path("vignettes", "articles", "alcove", "alcove-model.R"))
out_dir <- file.path("vignettes", "articles", "alcove")
types <- c("I", "II", "III", "IV", "V", "VI")
stages <- strsplit(Sys.getenv("ALCOVE_STAGES", "psp,uniform,learners,orders"), ",")[[1]]

discretize <- function(curves) weak_order(curves, gap = 0.025)
control <- list(
  lower = rep(0, 4), upper = rep(1, 4),
  radius = 0.15,
  population = 50,
  iterations = 2000,
  parameter_names = alcove_parameters$name,
  stimuli_names = paste0(rep(types, each = 16), "_", rep(1:16, 6)),
  dimensionality = 6,
  responses = 96
)
training <- alcove_training(learners = 5, seed = 7624)
model <- function(par) alcove_curves(par, training)

# each evaluation reduced to its parameters, the mean error of each type and
# its weak order
summarise_curves <- function(unit, curves) {
  means <- t(apply(curves, 1, function(x) colMeans(matrix(x, nrow = 16))))
  colnames(means) <- paste0("error_", types)
  data.frame(t(apply(unit, 1, to_alcove)), means,
             order = apply(curves, 1, function(x) describe_order(weak_order(x))))
}
write_gz <- function(data, name) {
  con <- gzfile(file.path(out_dir, name), "w")
  write.csv(data, con, row.names = FALSE)
  close(con)
}
record <- function(stage, ...) {
  path <- file.path(out_dir, "run-info.csv")
  row <- data.frame(stage = stage, ...)
  info <- if (file.exists(path)) read.csv(path) else row[0, ]
  info <- info[info$stage != stage, , drop = FALSE]
  write.csv(merge(info, row, all = TRUE), path, row.names = FALSE)
  cat(stage, ":", paste(names(row)[-1], unlist(row[-1]), collapse = ", "), "\n")
}

# the even sample: the same 4,000 points every time
set.seed(1)
unit <- matrix(runif(4 * 4000), ncol = 4)

if ("psp" %in% stages) {
  set.seed(2026)
  control$init <- matrix(runif(4 * 20), ncol = 4)
  path <- file.path(tempdir(), "alcove")
  time <- system.time(
    result <- pspGlobal(model, discretize, control, save = TRUE, path = path, quiet = TRUE)
  )[["elapsed"]]
  evaluated <- read.csv(paste0(path, "_parameters.csv"))
  curves <- as.matrix(read.csv(paste0(path, "_continuous.csv"))[, control$stimuli_names])
  write_gz(cbind(iteration = evaluated$iteration,
                 summarise_curves(as.matrix(evaluated[, alcove_parameters$name]), curves)),
           "psp-run.csv.gz")
  record("psp", seconds = time, iterations = result$iterations,
         evaluations = sum(result$ordinal_counts), patterns = dim(result$ordinal_patterns)[3])
}

if ("uniform" %in% stages) {
  time <- system.time(curves <- t(apply(unit, 1, model)))[["elapsed"]]
  write_gz(summarise_curves(unit, curves), "uniform.csv.gz")
  record("uniform", seconds = time, evaluations = nrow(unit))
}

if ("learners" %in% stages) {
  # the first 500 points of the even sample again, with 20 simulated learners
  training20 <- alcove_training(learners = 20, seed = 7624)
  time <- system.time(
    curves20 <- t(apply(unit[1:500, ], 1, function(par) alcove_curves(par, training20)))
  )[["elapsed"]]
  uniform <- read.csv(file.path(out_dir, "uniform.csv.gz"))
  write.csv(data.frame(learners_5 = uniform$order[1:500],
                       learners_20 = apply(curves20, 1, function(x) describe_order(weak_order(x)))),
            file.path(out_dir, "learners.csv"), row.names = FALSE)
  record("learners", seconds = time, evaluations = 500)
}

if ("orders" %in% stages) {
  # the main PSP run again, with four other trial orders
  start <- Sys.time()
  orders <- do.call(rbind, lapply(c(11, 22, 33, 44), function(seed) {
    training <- alcove_training(learners = 5, seed = seed)
    model <- function(par) alcove_curves(par, training)
    set.seed(seed)
    control$init <- matrix(runif(4 * 20), ncol = 4)
    out <- pspGlobal(model, discretize, control, quiet = TRUE)
    data.frame(trial_order = seed, order = apply(out$ordinal_patterns, 3, describe_order),
               parameter_sets = as.vector(out$ordinal_counts), iterations = out$iterations)
  }))
  write.csv(orders, file.path(out_dir, "trial-orders.csv"), row.names = FALSE)
  record("orders", seconds = as.numeric(difftime(Sys.time(), start, units = "secs")))
}

if ("volume" %in% stages) {
  # Pitt et al. (2006): sample each region with its own Metropolis chain whose
  # target is uniform on the region (a step is accepted only if it produces
  # the region's pattern), fit an ellipsoid to the chain from its mean and
  # covariance, then correct the ellipsoid's volume by the share of points
  # drawn uniformly inside it that produce the pattern (hit-or-miss Monte
  # Carlo; Appendix B). Volumes are on the unit hypercube, so they are shares
  # of the parameter space.
  start <- Sys.time()
  run <- read.csv(file.path(out_dir, "psp-run.csv.gz"))
  unit_run <- sweep(sweep(as.matrix(run[, alcove_parameters$name]), 2, alcove_parameters$lower), 2,
                    alcove_parameters$upper - alcove_parameters$lower, "/")
  d <- ncol(unit_run)
  unit_ball <- pi^(d / 2) / gamma(d / 2 + 1)
  pattern_of <- function(par) describe_order(discretize(model(par)))
  in_ball <- function(n) {
    direction <- matrix(rnorm(n * d), ncol = d)
    direction / sqrt(rowSums(direction^2)) * runif(n)^(1 / d)
  }
  burn_in <- 200
  kept <- 400
  draws <- 200
  set.seed(3)
  volumes <- do.call(rbind, lapply(unique(run$order), function(o) {
    points <- unit_run[run$order == o, , drop = FALSE]
    # start from the region's point nearest its median
    current <- points[which.min(rowSums(sweep(points, 2, apply(points, 2, median))^2)), ]
    radius <- 0.05
    chain <- matrix(NA, burn_in + kept, d)
    accepted <- logical(burn_in + kept)
    for (step in seq_len(burn_in + kept)) {
      proposal <- current + radius * in_ball(1)[1, ]
      accepted[step] <- all(proposal >= 0 & proposal <= 1) && pattern_of(proposal) == o
      if (accepted[step]) current <- proposal
      chain[step, ] <- current
      # during burn-in, adapt the radius towards 20-25% acceptance
      if (step <= burn_in && step %% 20 == 0) {
        rate <- mean(accepted[(step - 19):step])
        radius <- radius * if (rate < 0.2) 0.7 else if (rate > 0.25) 1.4 else 1
      }
    }
    sample <- chain[(burn_in + 1):(burn_in + kept), , drop = FALSE]
    covariance <- cov(sample)
    if (qr(covariance)$rank < d) {
      return(data.frame(order = o, acceptance = mean(accepted[-(1:burn_in)]), ellipsoid = NA,
                        hits = NA, draws = NA, volume = NA))
    }
    ellipsoid <- unit_ball * (d + 2)^(d / 2) * sqrt(det(covariance))
    inside <- sweep(in_ball(draws) %*% chol((d + 2) * covariance), 2, colMeans(sample), "+")
    in_bounds <- rowSums(inside < 0 | inside > 1) == 0   # outside the bounds is always a miss
    hit <- rep(FALSE, draws)
    hit[in_bounds] <- apply(inside[in_bounds, , drop = FALSE], 1, pattern_of) == o
    data.frame(order = o, acceptance = mean(accepted[-(1:burn_in)]), ellipsoid = ellipsoid,
               hits = sum(hit), draws = draws, volume = ellipsoid * mean(hit))
  }))
  write.csv(volumes, file.path(out_dir, "volumes.csv"), row.names = FALSE)
  record("volume", seconds = as.numeric(difftime(Sys.time(), start, units = "secs")),
         evaluations = length(unique(run$order)) * (burn_in + kept + draws))
}
