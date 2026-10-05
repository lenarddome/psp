# contract between pspGlobal and the user-supplied model and discretize functions

callback_control <- function() {
  list(
    iterations = 2, population = 100, radius = 0.1,
    lower = c(0, 0), upper = c(1, 1), init = matrix(0.5, 1, 2),
    parameter_names = c("a", "b"), stimuli_names = c("a", "b"),
    dimensionality = 2, responses = 2
  )
}

test_that("model receives a plain numeric vector of parameters", {
  seen <- list()
  pspGlobal(
    model = function(par) {
      seen[[length(seen) + 1]] <<- par
      c(1, 2)
    },
    discretize = function(x) matrix(1, 2, 2),
    control = callback_control(), quiet = TRUE
  )
  expect_length(seen, 3)
  for (par in seen) {
    expect_type(par, "double")
    expect_null(attributes(par))
    expect_length(par, 2)
  }
})

test_that("discretize receives model output as doubles", {
  seen <- NULL
  out <- pspGlobal(
    model = function(par) c(1L, 2L),
    discretize = function(x) {
      seen <<- x
      matrix(1L, 2, 2)
    },
    control = callback_control(), quiet = TRUE
  )
  expect_identical(seen, c(1, 2))
  expect_identical(out$ordinal_patterns[, , 1], matrix(1, 2, 2))
})

test_that("errors raised by model and discretize reach the caller", {
  expect_error(
    pspGlobal(function(par) stop("model broke"), function(x) matrix(1, 2, 2),
              callback_control(), quiet = TRUE),
    "model broke"
  )
  expect_error(
    pspGlobal(function(par) c(1, 2), function(x) stop("discretize broke"),
              callback_control(), quiet = TRUE),
    "discretize broke"
  )
})

test_that("an error in a later iteration also reaches the caller", {
  calls <- 0
  expect_error(
    pspGlobal(
      model = function(par) {
        calls <<- calls + 1
        if (calls > 1) stop("failed on call ", calls)
        c(1, 2)
      },
      discretize = function(x) matrix(1, 2, 2),
      control = callback_control(), quiet = TRUE
    ),
    "failed on call 2"
  )
})

test_that("model output of the wrong length or type is rejected", {
  expect_error(
    pspGlobal(function(par) c(1, 2, 3), function(x) matrix(1, 2, 2),
              callback_control(), quiet = TRUE),
    "responses"
  )
  expect_error(
    pspGlobal(function(par) c("a", "b"), function(x) matrix(1, 2, 2),
              callback_control(), quiet = TRUE),
    "numeric"
  )
})

test_that("discretize output that is not a dimensionality-sized matrix is rejected", {
  expect_error(
    pspGlobal(function(par) c(1, 2), function(x) c(1, 2, 3, 4),
              callback_control(), quiet = TRUE),
    "matrix"
  )
  expect_error(
    pspGlobal(function(par) c(1, 2), function(x) matrix(1, 3, 3),
              callback_control(), quiet = TRUE),
    "dimensionality"
  )
})
