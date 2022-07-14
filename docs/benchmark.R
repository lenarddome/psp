library(psp)
library(ggplot2)
library(ggbeeswarm)
library(data.table)
library(plyr)
library(bench)
library(microbenchmark)
library(Rcpp)
sourceCpp("../src/pspGlobal.cpp")

# euclidean distance
euclidean <- function(a, b) sqrt(sum((a - b)^2))

# define center points for the 10 regions in a two-dimensional space
#positions <- NULL
#for (i in seq_len(5)) positions <- cbind(positions, sample(500, 1))

positions <- matrix(runif(5), nrow = 1)

## calculates distances and gives a non-sensical inequality matrix
model <-  function(par, legacy = FALSE) {
  if (legacy) {
    out <- paste(positions, collapse = "+")
  } else {
    out <- matrix(1, nrow = 2, ncol = 2)
  }
  return(out)
}

set.seed(7624)

rold <- function() {
  out <- psp_global(model, psp_control(lower = rep(0, 5),
                                     upper = rep(1, 5),
                                     init = rep(0.5, 5),
                                     radius = rep(0.25, 5),
                                     pop = Inf,
                                     iterations = 100),
                    legacy = TRUE)
  return(0)
}

cpp <- function() {
  outcpp <- pspGlobal(model, control = list(lower = rep(0, 5),
                                   upper = rep(1, 5),
                                   init = matrix(rep(0.5, 5), nrow = 1),
                                   radius = 0.25,
                                   population = 2147483647,
                                   param_names = paste("names", 1:5, sep = ""),
                                   iterations = 100))
  return(0)
}


benchPress <- function () {
  mbcpp <- microbenchmark(cpp(), rold(), times = 1000)
  return(mbcpp)
}

## measure other hardware requirements as well
frontSquat <-  function () {
  out <-bench::mark(cpp(), rold(), iterations = 1000)
  return(out)
}

cpp_benchmark <- benchPress()
cpp_frontsquat <-  frontSquat()

save(cpp_benchmark, file = "cpp_backsquat.RData")
save(cpp_frontsquat, file = "cpp_frontsquat.RData")

benchpress <- autoplot(cpp_frontsquat, "beeswarm")
benchpress + geom_boxplot(aes(group = expression, colour = "black"), width = 0.25) + ggthemes::theme_calc() + theme(legend.position = "none")

# load("benchmark.RData")
graph <- ggplot(cpp_benchmark, aes(y = expr, x = time, fill = expr))
graph <- graph + geom_violin() +
  geom_boxplot(fill = "grey", width = 0.15) +
  ylab("alogrithm implementation") + xlab("time (ms)") +
  geom_jitter(size = 0.25) + ggthemes::theme_calc()

ggsave(plot = graph, filename = "benchmark.pdf", units = "in", width = 12, height = 8)
ggsave(plot = graph, filename = "benchmark.png", units = "in", width = 8, height = 6)
