library(psp)
library(data.table)
library(plyr)
library(microbenchmark)

# euclidean distance
euclidean <- function(a, b) sqrt(sum((a - b)^2))

# define center points for the 10 regions in a two-dimensional space
positions <- NULL
for (i in seq_len(2)) positions <- cbind(positions, sample(500, 4) / 500)

## calculates distances and gives a non-sensical inequality matrix
model <-  function(par, legacy = FALSE) {
  distances <- outer(as.matrix(par), as.matrix(positions), Vectorize(euclidean))
  converted <- plyr::alply(distances, 3)
  summed <- unlist(plyr::alply(distances, 3, sum, expand = FALSE))
  distance_matrix <- dist(summed, diag = TRUE)
  distance_matrix[distance_matrix < 0.5] <- -1
  distance_matrix[distance_matrix < 1.0 & distance_matrix > 0.5] <- 0
  distance_matrix[distance_matrix > 1.0] <- 1
  if (legacy) {
    distance_matrix <- data.frame(as.matrix(distance_matrix))
  } else {
    distance_matrix <- as.matrix(distance_matrix)
  }
  distance_matrix[!upper.tri(distance_matrix)] <- NA
  return(distance_matrix)
}

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
                                   radius = rep(0.10, 2),
                                   population = 1000000,
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
