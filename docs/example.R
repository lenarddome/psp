library(psp)
library(data.table)
library(gganimate)
library(ggplot2)
library(ggthemes)
library(viridis)

#' euclidean distance
#'
#' @param a vector coordinate 1
#' @param b vector coordinate 2
#' @return euclidean distance between coordinates
euclidean <- function(a, b) sqrt(sum((a - b)^2))

# define center points for the 10 regions in a two-dimensional space
positions <- NULL
for (i in seq_len(2)) positions <- cbind(positions, sample(500, 50))

#' dummy polytope model to test the PSP function
#' The model takes in a set of coordinates, calculates its distance from all
#' all of available coordinates, then return closest region number.
#' This model generalizes to n-dimensions
#'
#' @param x a vector of coordinates
#' @return The number of the region as character
#' @examples
#' model(runif(5))
model <- function(par) {
    areas <- NULL
    for (i in seq_along(par)) {
        range <- c(1, 0)
        if (i %% 2 == 0) {
            range <- c(0, 1)
        }
        areas <- cbind(areas,
                    seq(range[1], range[2], length.out = 500)[positions[, i]])
    }
    dist <- apply(areas, 1, function(x) euclidean(par, x))
    return(as.character(which.min(dist)))
}

# run Parameter Space Partitioning with some default settings
out <- psp_global(model, psp_control(lower = rep(0, 2),
                                   upper = rep(1, 2),
                                   init = rep(0.5, 2),
                                   radius = rep(0.10, 2),
                                   pop = Inf,
                                   parallel = TRUE,
                                   cluster_names = c("positions",
                                                     "euclidean"),
                                   iterations = 1000))

dta <- data.table(out$ps_partitions)

plot <- ggplot(dta, aes(x = parameter_1, y = parameter_2,
                        colour = as.factor(pattern))) +
    geom_point() +
    theme_par() +
    theme(legend.position = "none") +
    scale_colour_viridis_d(option = "A")

ggsave("psp_cover.png")

animated <- plot + transition_manual(cumulative = TRUE, frames = iteration) +
  labs(title = "Iteration: {current_frame}")

anim_save(filename = "figures/test.png", animation = animated,
          renderer = file_renderer())
