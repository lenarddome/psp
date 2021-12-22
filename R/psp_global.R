# function tuning the behaviour of the parameter space partitioning
# see documentation
psp_control <- function(radius = 0.1, init = NULL, lower, upper,
                        pop = 400, cl = NULL,
                        param_names = NULL,
                        parallel = FALSE,
                        cluster_names = NULL,
                        iterations = 1000) {

    ## error functions
    if (length(upper) != length(lower)) {
        stop("Lower and upper boundaries have different lengths!")
    }

    if (!is.null(init)) {
        if (is.vector(init) && length(init) != length(lower)) {
            stop(paste("init must be either NULL or a vector of same",
                       "length as the same number of parameters!"))
        } else if (is.matrix(init) && ncol(init) != length(lower)) {
            stop(paste("init must be either NULL or a matrix with the same
                       number of columns as number of parameters!"))
        }
    }

    ## set up hypersphere radius
    if (length(radius) == 1) {
        radius <- rep(radius, length(init))
    }
    ## name parameters

    if (is.null(param_names)) {
        param_names <- paste("parameter_", seq(length(init)), sep = "")
    }
    # export functions to parallel clusters
    if (!is.null(cluster_names)) {
        out <- sapply(cluster_names, exists, simplify = TRUE)
        if (!all(out)) {
            stop(paste("You need to load ",
                       paste(names(which(out == FALSE)), collapse = ", "),
                       " to your global environment.", sep = ""))
        }
    }
    ## check if stopping rule is defined appropriately
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
                parallel = parallel,
                param_names = param_names,
                cluster_names = cluster_names,
                iterations = iterations)
    return(out)
}

## A handy function to set up parallel environment without increasing
## cyclomatic complexity of the main psp_global
parallelize <- function(parallel = FALSE, cl = NULL, names = NULL) {
    if (parallel == TRUE && is.null(cl)) {
        no_cores <- parallel::detectCores()
        cl <- parallel::makeCluster(no_cores)
    } else if (parallel == TRUE && !is.null(cl)) {
        cl <- parallel::makeCluster(cl)
    }

    parallel::clusterExport(cl, names, envir = environment())
    return(cl)
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
psp_hyper <- function(jump, radius) {
    if (!("numeric" %in% is(jump))) jump <- as.numeric(jump)
    gauss <- rnorm(length(jump), mean = 0, sd = 1)
    points <- (1 / sum(sqrt(gauss ^ 2)) * gauss) *
        runif(1, min = 0, max = radius)
    points_interior <- points + jump
    return(points_interior)
}

## Parameter Space Partitioning

psp_global <- function(fn, control = psp_control(), quiet = FALSE) {

    ## declare all variables
    ctrl <- do.call(psp_control, as.list(control))
    radius <- ctrl$radius
    pop <- ctrl$pop
    init <- ctrl$init
    upper <- ctrl$upper
    lower <- ctrl$lower
    pnames <- ctrl$param_names
    cnames <- ctrl$cluster_names

    ## set up parallel
    cl <- parallelize(parallel = ctrl$parallel, cl = ctrl$cl, names = cnames)

    ## define ordinal function
    fun <- match.fun(fn)
    dota <- data.table::data.table

    ## miscellaneous variables
    parameter_filled <- FALSE
    parmat_current <- NULL
    parmat_big <- NULL
    while_count <- 1

    ## set first parameter set and ordinal pattern
    parmat_current <- matrix(init, nrow = 1)
    evaluate <- fun(parmat_current[1, seq(length(init))])
    if (!is.null(dim(evaluate))) evaluate <- list(evaluate)

    ## create big parameter matrix
    parmat_big <- dota(cbind(parmat_current, evaluate, while_count))
    colnames(parmat_big) <- c(pnames, "pattern", "iteration")

    ## specify location of ordinal pattern in parmat_big
    loc <- colnames(parmat_big)[(length(init) + 1)]

    ## does the ordinal pattern have any dimensions?
    dimension <- any(dim(parmat_big[, loc, with = FALSE]) > 1)

    while (!parameter_filled) {
        while_count <- while_count + 1
        ## construct new set of parameters to search
        new_points <-
            t(apply(parmat_current, 1,
                    function(x) {
                        psp_hyper(jump = x, radius = radius)
                    }))

        ## constrain parameters within bounds
        for (i in seq(length(init))) {
            cbounds <- new_points[, i]
            cbounds[cbounds > upper[i]] <- upper[i]
            cbounds[cbounds < lower[i]] <- lower[i]
            new_points[, i] <- cbounds
        }

        # evaluate new_points and record ordinal patterns
        ifelse(ctrl$parallel,
           evaluate <- parallel::parApply(cl, new_points, 1, fun), # parallel
           evaluate <- apply(new_points, 1, fun))                  # no parallel

        ## save new results with points
        ordinal <- dota(cbind(new_points, evaluate, while_count))
        parmat_big <- rbind(parmat_big, ordinal, use.names = FALSE)

        ## compare stored and currently produced ordinal responses
        if (dimension) {
            ## in case ordinal pattern is not a string but has dims
            pats <- unlist(parmat_big[, loc, with = FALSE], recursive = FALSE)
            mapping <- match(pats, unique(pats))
            new_dist <- table(mapping)
        } else {
            ## if ordinal pattern is a single string
            new_dist <- table(unlist(parmat_big[, loc, with = FALSE]))
            mapping <- unlist(parmat_big[, loc, with = FALSE])
        }

        ## index regions
        new_index <- which(new_dist < pop)
        ## if all regions below population limit
        if (length(new_index) > 0) {
            parmat_current <- NULL
            for (i in names(new_dist)) {
                ## which(mapping == i) breaks prev sims
                tmp <- tail(parmat_big[which(mapping == i)], 1)
                parmat_current <-
                    rbind(parmat_current,
                          tmp[, seq_len(length(init)), with = FALSE])
            }
        } else {
            parameter_filled <- TRUE
        }
        ## print information about the current iteration
        if (!quiet) {
        print(paste("iteration [", while_count, "]: found ",
                    length(unique(mapping)), sep = ""))
        }
        if (while_count == ctrl$iterations) parameter_filled <- TRUE
    }
    ## close parallel workplaces
    if (ctrl$parallel == TRUE) parallel::stopCluster(cl)
    ## depending on dims of ordinal pattern compile output
    if (dimension) {
        pats <- unlist(parmat_big[, loc, with = FALSE], recursive = FALSE)
        mapping <- match(pats, unique(pats))
        ordinal_size <- table(mapping, deparse.level = 0)
        output <- list("ps_partitions" = parmat_big,
                       "ps_patterns" = ordinal_size,
                       "ps_ordinal" = unique(pats))
    } else {
        ordinal_size <-
            table(parmat_big[, loc, with = FALSE], deparse.level = 0)
        output <- list("ps_partitions" = parmat_big,
                       "ps_patterns" = ordinal_size,
                       "ps_ordinal" = names(ordinal_size))
    }
    attr(output, "class") <- "PSP"
    return(output)
}
