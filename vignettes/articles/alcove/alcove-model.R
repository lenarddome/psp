# ALCOVE on the six Shepard, Hovland and Jenkins (1961) problems, wrapped for
# pspGlobal(). Shared by the recipe and by run-alcove.R, which produces the
# results the recipe reads.

library(catlearn)

## ---- parameters
# the four parameters, in the order pspGlobal() passes them, with the ranges
# Pitt, Kim, Navarro and Myung (2006) used; the lower bounds are kept above 0
# because slpALCOVE() rejects a learning rate of exactly 0
alcove_parameters <- data.frame(
  name  = c("c", "phi", "lw", "la"),
  lower = c(0.01, 0.01, 0.001, 0.001),
  upper = c(20, 6, 0.2, 0.2)
)

## ---- training
# the eight stimuli, three binary dimensions each
alcove_stimuli <- cbind(c(0, 0, 0), c(0, 0, 1), c(0, 1, 0), c(0, 1, 1),
                        c(1, 0, 0), c(1, 0, 1), c(1, 1, 0), c(1, 1, 1))

# one training sequence per problem type: 16 blocks of the 8 stimuli for each
# simulated learner, in an order fixed by `seed`
alcove_training <- function(learners = 5, seed = 7624) {
  do.call(rbind, lapply(1:6, function(type) {
    nosof94train(type, blocks = 16, absval = -1, subjs = learners, seed = seed)
  }))
}

## ---- mapping
# pspGlobal() searches the unit hypercube, so a single radius suits every
# parameter; this maps a point of it onto ALCOVE's parameter ranges
to_alcove <- function(unit) {
  setNames(alcove_parameters$lower + unit * (alcove_parameters$upper - alcove_parameters$lower),
           alcove_parameters$name)
}

## ---- curves
# returns the error rate of each problem type in each block: 6 x 16 values
alcove_curves <- function(unit, training) {
  p <- to_alcove(unit)
  state <- list(colskip = 4, r = 1, q = 1, alpha = rep(1 / 3, 3), w = array(0, dim = c(2, 8)),
                h = alcove_stimuli, c = p[["c"]], phi = p[["phi"]], lw = p[["lw"]], la = p[["la"]])
  prob <- slpALCOVE(state, training)$p
  correct <- ifelse(training[, "t1"] == 1, prob[, 1], prob[, 2])
  error <- tapply(1 - correct, list(block = training[, "blk"], type = training[, "cond"]), mean)
  as.vector(error)   # type I blocks 1-16, then type II, ...
}

## ---- weak-order
# the weak order of the six types by mean error: sort them, and start a new
# group wherever the gap to the next type is larger than `gap`. Returns the
# 6 x 6 matrix of group comparisons (1: row type is harder than column type)
weak_order <- function(curves, gap = 0.025) {
  error <- colMeans(matrix(curves, nrow = 16))
  sorted <- order(error)
  group <- integer(6)
  group[sorted] <- cumsum(c(1, diff(error[sorted]) > gap))
  sign(outer(group, group, "-"))
}

## ---- describe
# writes a weak order the usual way, easiest first: "I < II < (III, IV, V) < VI"
describe_order <- function(pattern) {
  types <- c("I", "II", "III", "IV", "V", "VI")
  rank <- rowSums(pattern > 0)   # how many types each type is harder than
  groups <- split(types, rank)
  groups <- groups[order(as.numeric(names(groups)))]
  paste(sapply(groups, function(g) if (length(g) > 1) paste0("(", paste(g, collapse = ", "), ")") else g),
        collapse = " < ")
}
