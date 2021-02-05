# reproduce alcove PSP from paper
PSPnosof94alcove <- function(params = c(6.33,0.011)) {
    require(catlearn)
    out <- nosof94bnalcove(c(params, 0.409, 0.179))
    out_order <- aggregate(out, by = list(out$type), mean)
    return(paste(out_order[order(out_order$error), ]$type, collapse = ""))
}

ctrl <- PSPcontrol(lower = rep(10^(-10), 2),
           upper = c(20, 6),
           init = c(6.33, 0.011),
           radius = c(1, 1))


######## TO REMOVE LATER

library(plotly)
library(gganimate)
library(cowplot)
library(viridis)

gg <- ggplot(parmat_big, aes(x = X1, y = X2, colour = as.factor(X3))) +
    geom_point(size = 0.5, alpha = 0.85) +
    theme_cowplot() +
    xlab("c - specificity constant") +
    ylab("phi - decision constant ") +
    theme(legend.position = "none") +
    scale_colour_viridis_d()

gg <- gg + transition_time(iterations) + shadow_mark(past = T, future = F)

animate(gg, nframes = 1000,
        renderer = gifski_renderer("file1.gif"),
        width = 30, height = 10, units = "cm", res = 600)
