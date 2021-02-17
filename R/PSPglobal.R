# function tuning the behaviour of the parameter space partitioning
# see documentation
PSPcontrol <- function(radius = 0.01, init = NULL, lower, upper,
                       pop = 400, cl = NULL,
                       param_names = NULL,
                       cluster_names = NULL,
                       iterations = 1000) {

    ## error functions
    if (length(upper) != length(lower)) {
        stop("Lower and upper boundaries have different lengths!")
    }
    if (!is.null(init) & length(init) != length(lower)) {
        stop(paste("init must be either NULL or a vector of same",
                   "length as number of parameters!"))
    }
    if (length(init) < 1 | is.null(init)) {
        init <- colMeans(rbind(upper, lower))
        cat(paste("First jumping distribution is set to ",
                  "the midpoint between lower and upper bounds:\n",
                  paste(init, collapse = ","), sep = ""))
    }
    if (!is.null(param_names)) {
        if (length(param_names) != length(init)) {
        stop("param_names and init must have equal length")
        }
    }
    ## set up hypersphere radius
    if (length(radius) == 1) {
        radius <- rep(radius, length(init))
    }
    ## set up parallel
    if (is.null(cl)) {
        no_cores <- parallel::detectCores()
        cl <- parallel::makeCluster(no_cores)
    } else {
        cl <- parallel::makeCluster(cl)
    }
    ## name parameters
    if (is.null(param_names)) {
        param_names <- paste("parameter_", seq(length(init)), sep = "")
    }
    # export functions to parallel clusters
    if (!is.null(cluster_names)) {
        out <- sapply(cluster_names, exists, simplify = TRUE)
        if (!all(out)) {
            stop(paste("You need to load ", names(which(out == FALSE)),
                       " to your global environment.", sep = ""))
        }
    }
    if (is.null(pop)) {
        pop <- Inf
        print(paste("Option pop is set to Inf. Stopping rule",
                    "is defined by global iterations."))
    }
    if (is.null(iterations)) {
        iterations <- Inf
        print(paste("Option iterations is set to Inf. Stopping rule is
                    defined by pop."))
    }
    if (all(c(pop, iterations) == Inf)) {
        stop("You must set a stopping rule for the function by using either
             iterations or pop in PSPcontrol.")
    }
    out <- list(radius = radius,
                pop = pop,
                cl = cl,
                init = init,
                lower = lower,
                upper = upper,
                param_names = param_names,
                cluster_names = cluster_names,
                iterations = iterations)
    return(out)
}

## Weisstein, Eric W. "Hypersphere Point Picking." From
## MathWorld--A Wolfram Web Resource.
## https://mathworld.wolfram.com/HyperspherePointPicking.html

#' generate random distribution from the unit hypersphere relative to 0
#' scale it by the user-defined radius, then add it to the jumping distribution
#'
#' @param init Matrix of coordinates serving as a jumping distribution
#' @param radius The radius of the hypersphere defining the sampling region
#' @return Matrix of randomly sampled points within the unit sphere
PSPhyper <- function(init, radius) {
    gauss <- rnorm(length(init), mean = 0, sd = 1)
    points <- (1 / sum(sqrt(gauss ^ 2)) * gauss) *
        runif(1, min = 0, max = radius)
    points_interior <- points + init
    return(points_interior)
}

## Parameter Space Partitioning  ------------------------------------------

PSPglobal <- function(fn, control = PSPcontrol()) {

    ## declare all variables
    ctrl <- do.call(PSPcontrol, as.list(control))
    radius <- ctrl$radius
    pop <- ctrl$pop
    init <- ctrl$init
    upper <- ctrl$upper
    lower <- ctrl$lower
    cl <- ctrl$cl
    pnames <- ctrl$param_names
    cnames <- ctrl$cluster_names
    parallel::clusterExport(cl, cnames,
                            envir = environment())

    ## define ordinal function
    FUN <- match.fun(fn)

    ## miscellaneous variables
    parameter_filled <- FALSE
    parmat_current <- NULL
    parmat_big <- NULL
    while_count <- 1

    ## set first parameter set and ordinal pattern
    parmat_current <- matrix(init, nrow = 1)
    evaluate <- FUN(parmat_current[1, seq(length(init))])
    parmat_big <- type.convert(data.frame(cbind(parmat_current, evaluate,
                                                while_count,
                                                deparse.level = 0)),
                               as.is = TRUE)

    while (!parameter_filled) {
        while_count <- while_count + 1
        ## construct new set of parameters to search
        new_points <- t(apply(parmat_current, 1,
                              function(x) {
                                  PSPhyper(init = x[seq_len(length(init))],
                                           radius = radius)
                              }))
        ## constrain parameters within bounds
        for (i in seq(length(init))) {
            cbounds <- new_points[, i]
            cbounds[cbounds > upper[i]] <- upper[i]
            cbounds[cbounds < lower[i]] <- lower[i]
            new_points[, i] <- cbounds
        }
        # evaluate new_points and record ordinal patterns
        evaluate <- parallel::parApply(cl, new_points, 1, FUN)
        ordinal <- type.convert(cbind(new_points, evaluate, while_count,
                                      deparse.level = 0),
                                as.is = TRUE)
        ## compare stored and currently produced ordinal responses
        ## index new regions and update population
        parmat_big <- rbind(parmat_big, data.frame(ordinal))
        new_dist <- table(parmat_big[, length(init) + 1])
        new_index <- which(new_dist < pop)
        if (length(new_index) > 0) {
            parmat_current <- NULL
            for (i in names(new_dist)) {
                tmp <- parmat_big[parmat_big[, length(init) + 1] == i,
                                  seq(length(init))]
                parmat_current <- rbind(parmat_current,
                                        matrix(as.numeric(tail(tmp, 1)),
                                              nrow = 1))
            }
        } else {
            parameter_filled <- TRUE
        }
        # print is only for debugging as of 2021-01-27T13:08:40+0000
        print(paste("iteration [", while_count, "]: found ",
                    length(table(parmat_big[, length(init) + 1])),
                    sep = ""))
        if (while_count == ctrl$iterations) parameter_filled <- TRUE
    }
    parallel::stopCluster(cl)
    ordinal_size <- table(parmat_big[, length(init) + 1])
    colnames(parmat_big) <- c(pnames, "pattern", "iteration")
    return(list("ps_partitions" = parmat_big,
                "ps_patterns" = ordinal_size))
}
