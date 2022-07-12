library(psp)
library(ggplot2)
library(data.table)
library(plyr)
library(microbenchmark)
library(Rcpp)
sourceCpp("../src/pspGlobal.cpp")

# euclidean distance
euclidean <- function(a, b) sqrt(sum((a - b)^2))

# define center points for the 10 regions in a two-dimensional space
positions <- NULL
for (i in seq_len(5)) positions <- cbind(positions, sample(500, 10))

## calculates distances and gives a non-sensical inequality matrix
model <-  function(par, legacy = FALSE) {
  areas <- NULL
  for (i in seq_along(par)) {
      range <- c(1, 0)
      if (i %% 2 == 0) {
          range <- c(0, 1)
      }
      areas <- cbind(areas, seq(range[1], range[2], length.out = 500)[positions[, i]])
  }
  distances <- outer(as.matrix(par), as.matrix(areas), Vectorize(euclidean))
  converted <- plyr::alply(distances, 3)
  summed <- unlist(plyr::alply(distances, 3, sum, expand = FALSE))
  out <- converted[[which.min(summed)]]
  if (legacy) {
    out <- paste(positions[which.min(summed),], collapse = "")
  } else {
    out <- matrix(which.min(summed), nrow = 2, ncol = 2)
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
                                     iterations = 1000),
                    legacy = TRUE)
}

cpp <- function() {
  outcpp <- pspGlobal(model, control = list(lower = rep(0, 5),
                                   upper = rep(1, 5),
                                   init = matrix(rep(0.5, 5), nrow = 1),
                                   radius = 0.25,
                                   population = 2147483647,
                                   param_names = paste("names", 1:5, sep = ""),
                                   iterations = 1000),
                 save = TRUE, path = "./benchmark.csv")
}


benchPress <- function () {
  mbcpp <- microbenchmark(cpp(), rold())
  return(mbcpp)
}

cpp_benchmark <- benchPress()
save(cpp_benchmark, file = "benchmark.RData")
# load("benchmark.RData")
graph <- ggplot(cpp_benchmark, aes(y = expr, x = time/1e9, fill = expr))
graph <- graph + geom_violin() + geom_boxplot(fill = "grey", width = 0.15) + geom_jitter(size = 0.25) + ggthemes::theme_calc()
ggsave(plot = graph, filename = "benchmark.pdf", units = "in", width = 12, height = 8)