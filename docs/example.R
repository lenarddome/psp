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
for (i in seq_len(2)) positions <- cbind(positions, sample(500, 100))

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

set.seed(1)
rold <- function() {
  out <- psp_global(model, psp_control(lower = rep(0, 2),
                                     upper = rep(1, 2),
                                     init = rep(0.5, 2),
                                     radius = rep(0.10, 2),
                                     pop = Inf,
                                     iterations = 100),
                    legacy = TRUE)
}

cpp <- function() {
  outcpp <- pspGlobal(model, control = list(lower = rep(0, 2),
                                   upper = rep(1, 2),
                                   init = matrix(rep(0.5, 2), nrow = 1),
                                   radius = 0.10,
                                   population = 2147483647,
                                   param_names = paste("names", 1:2, sep = ""),
                                   iterations = 100),
                 save = TRUE, path = "./benchmark.csv")
}

benchPress <- function () {
  mbcpp <- microbenchmark(cpp(), rold())
  return(mbcpp)
}

cpp_benchmark <- benchPress()

graph <- ggplot2::autoplot(cpp_benchmark)
ggsave(plot = graph, filename = "benchmark.pdf", units = in, width = 10, height = 12)


test <- fread("benchmark.csv")
ggplot(test, aes(x = names1, y = names2, color = pattern)) +
  geom_point()

ggplot(out$ps_partitions, aes(x = parameter_1, y = parameter_2, color = pattern)) +
  geom_point()
