# behavioural guarantees of the pspGlobal sampler

test_that("every evaluation is counted exactly once", {
  set.seed(1)
  init <- matrix(runif(9), nrow = 3)
  out <- pspGlobal(
    model = function(par) as.numeric(par),
    discretize = function(x) matrix(1, 2, 2),
    control = list(
      iterations = 5, population = 1000, radius = 0.1,
      lower = rep(0, 3), upper = rep(1, 3), init = init,
      parameter_names = c("a", "b", "c"), stimuli_names = c("a", "b", "c"),
      dimensionality = 2, responses = 3
    ),
    quiet = TRUE
  )
  # 3 starting points + 1 proposal for the single pattern in each of 5 iterations
  expect_equal(as.numeric(out$ordinal_counts), 8)
})

test_that("the first iteration proposes from every pattern found at the start", {
  path <- file.path(tempdir(), "psp_first_iteration")
  vor <- voronoi_model(regions = 50, dimensions = 3)
  set.seed(2)
  init <- matrix(runif(30), nrow = 10)
  out <- pspGlobal(vor$model, vor$discretize,
    voronoi_control(50, 3, iterations = 1, population = 1000, init = init),
    save = TRUE, path = path, quiet = TRUE
  )
  saved <- read_psp_output(path)$parameters
  start_patterns <- length(unique(saved$pattern[saved$iteration == 0]))
  expect_equal(sum(saved$iteration == 1), start_patterns)
})

test_that("each proposal is within radius of the last point in its region", {
  path <- file.path(tempdir(), "psp_centres")
  radius <- 0.1
  vor <- voronoi_model(regions = 30, dimensions = 3)
  set.seed(3)
  out <- pspGlobal(vor$model, vor$discretize,
    voronoi_control(30, 3, iterations = 30, population = 15, radius = radius),
    save = TRUE, path = path, quiet = TRUE
  )
  saved <- read_psp_output(path)$parameters
  params <- as.matrix(saved[, c("p1", "p2", "p3")])
  # replay the chain: proposals in iteration t come from the underpopulated
  # patterns after iteration t - 1, in pattern order, each centred on the last
  # point that produced that pattern
  for (t in seq_len(max(saved$iteration))) {
    history <- saved$iteration < t
    counts <- table(factor(saved$pattern[history], levels = seq_len(max(saved$pattern))))
    sources <- which(counts > 0 & counts < 15)
    proposals <- which(saved$iteration == t)
    expect_equal(length(proposals), length(sources))
    if (length(proposals) != length(sources)) next
    centres <- t(sapply(sources, function(k) {
      params[max(which(history & saved$pattern == k)), ]
    }))
    expect_lte(max(abs(params[proposals, , drop = FALSE] - centres)), radius + 1e-9)
  }
})

test_that("sampler fills every discovered region before the iteration cap", {
  vor <- voronoi_model(regions = 50, dimensions = 3)
  set.seed(4)
  out <- pspGlobal(vor$model, vor$discretize,
    voronoi_control(50, 3, iterations = 500, population = 10),
    quiet = TRUE
  )
  expect_lt(out$iterations, 500)
  expect_true(all(out$ordinal_counts >= 10))
})

test_that("saved files record full-precision values and correct pattern ids", {
  path <- file.path(tempdir(), "psp_saved")
  vor <- voronoi_model(regions = 20, dimensions = 3)
  set.seed(5)
  out <- pspGlobal(vor$model, vor$discretize,
    voronoi_control(20, 3, iterations = 10, population = 1000),
    save = TRUE, path = path, quiet = TRUE
  )
  saved <- read_psp_output(path)
  params <- as.matrix(saved$parameters[, c("p1", "p2", "p3")])
  continuous <- as.matrix(saved$continuous[, paste0("s", seq_len(20))])
  expect_equal(nrow(params), sum(out$ordinal_counts))
  for (i in seq_len(nrow(params))) {
    expect_equal(continuous[i, ], vor$model(params[i, ]), tolerance = 1e-12,
                 ignore_attr = TRUE)
    expect_equal(vor$discretize(vor$model(params[i, ])),
                 out$ordinal_patterns[, , saved$parameters$pattern[i]],
                 ignore_attr = TRUE)
  }
})

test_that("saved parameters and model outputs keep full double precision", {
  # 1 + 20 * eps prints as 1 at 15 significant digits, 20 units in the last place off
  values <- c(1 + 20 * .Machine$double.eps, 1 / 3, pi * 1e5)
  path <- file.path(tempdir(), "psp_exact")
  pspGlobal(
    model = function(par) values,
    discretize = function(x) matrix(1, 2, 2),
    control = list(
      iterations = 1, population = 1000, radius = 0.1,
      lower = rep(0, 3), upper = rep(2, 3), init = matrix(values[1:3] / 1e5, 1, 3),
      parameter_names = c("a", "b", "c"), stimuli_names = c("a", "b", "c"),
      dimensionality = 2, responses = 3
    ),
    save = TRUE, path = path, quiet = TRUE
  )
  saved <- read_psp_output(path)
  # R's own parser can be one or two units in the last place off on some platforms
  ulps <- function(x, y) abs(x - y) / (.Machine$double.eps * abs(y))
  expect_lte(max(ulps(unlist(saved$parameters[1, c("a", "b", "c")]), values / 1e5)), 2)
  for (i in seq_len(nrow(saved$continuous))) {
    expect_lte(max(ulps(unlist(saved$continuous[i, c("a", "b", "c")]), values)), 2)
  }
})

test_that("stored ordinal patterns are unique and counted", {
  vor <- voronoi_model(regions = 40, dimensions = 3)
  set.seed(6)
  out <- pspGlobal(vor$model, vor$discretize,
    voronoi_control(40, 3, iterations = 20, population = 1000),
    quiet = TRUE
  )
  patterns <- apply(out$ordinal_patterns, 3, paste, collapse = ",")
  expect_false(any(duplicated(patterns)))
  expect_equal(length(out$ordinal_counts), length(patterns))
})

test_that("negative zero and zero are the same ordinal pattern", {
  out <- pspGlobal(
    model = function(par) as.numeric(par),
    discretize = function(x) matrix(if (x[1] > 0.5) -0 else 0, 2, 2),
    control = list(
      iterations = 10, population = 1000, radius = 0.5,
      lower = 0, upper = 1, init = matrix(c(0.2, 0.8), ncol = 1),
      parameter_names = "a", stimuli_names = "a",
      dimensionality = 2, responses = 1
    ),
    quiet = TRUE
  )
  expect_equal(dim(out$ordinal_patterns)[3], 1)
})

test_that("identical patterns containing NaN are the same ordinal pattern", {
  out <- pspGlobal(
    model = function(par) as.numeric(par),
    discretize = function(x) matrix(c(1, NaN, NaN, 1), 2, 2),
    control = list(
      iterations = 5, population = 1000, radius = 0.1,
      lower = 0, upper = 1, init = matrix(0.5),
      parameter_names = "a", stimuli_names = "a",
      dimensionality = 2, responses = 1
    ),
    quiet = TRUE
  )
  expect_equal(dim(out$ordinal_patterns)[3], 1)
  expect_equal(as.numeric(out$ordinal_counts), 6)
})

test_that("invalid control settings are rejected", {
  vor <- voronoi_model(regions = 5, dimensions = 2)
  ctrl <- voronoi_control(5, 2, iterations = 0, population = 0)
  expect_error(pspGlobal(vor$model, vor$discretize, ctrl, quiet = TRUE), "threshold")
  ctrl <- voronoi_control(5, 2, iterations = 5, population = 5)
  ctrl$upper <- 1
  expect_error(pspGlobal(vor$model, vor$discretize, ctrl, quiet = TRUE), "same length")
  ctrl <- voronoi_control(5, 2, iterations = 5, population = 5)
  ctrl$parameter_names <- "p1"
  expect_error(pspGlobal(vor$model, vor$discretize, ctrl, quiet = TRUE), "param_names")
})
