# function tuning the behaviour of the parameter space partitioning
# see documentation
psp_control <- function(radius = 0.1, init, lower, upper,
                        pop = 400, cl = NULL,
                        param_names = NULL,
                        parallel = FALSE,
                        cluster_names = NULL,
                        export_objects = NULL,
                        export_libs = NULL,
                        iterations = 1000) {

    ## error functions
    if (length(upper) != length(lower)) {
        stop("Lower and upper boundaries have different lengths!")
    }

    if (is.vector(init) && length(init) != length(lower)) {
        stop(paste("init must be a vector of same",
                   "length as the number of parameters!"))
    } else if (is.matrix(init) && ncol(init) != length(lower)) {
        stop(paste("init must be a matrix with the same
                   number of columns as number of parameters!"))
    }

    ## set up hypersphere radius
    if (length(radius) == 1) {
        radius <- rep(radius, length(init))
    }

    ## name parameters
    if (is.null(param_names)) {
        param_names <- paste("parameter_", seq(length(init)), sep = "")
    }

    ## check if stopping rule is defined appropriately
    if (all(c(pop, iterations) == Inf)) {
        stop("You must set a stopping rule for the function by using either
             iterations or pop in PSPcontrol.")
    }

    ## check exports
    if (!is.null(cluster_names)) {
      print(paste("cluster_names is deprecated, please use",
                  "export_objects instead.\n",
                  "export_objects is overwritten by cluster_names."))
      export_objects <- cluster_names
    }

    ## construct output
    out <- list(radius = radius,
                pop = pop,
                cl = cl,
                init = init,
                lower = lower,
                upper = upper,
                parallel = parallel,
                param_names = param_names,
                export_objects = export_objects,
                export_libs = export_libs,
                iterations = iterations)

    return(out)
}

## A handy function to set up parallel environment without increasing
## cyclomatic complexity of the main psp_global
.parallelize <- function(parallel = FALSE, cl = NULL,
                        object_names = NULL, lib_names = NULL) {
    if (parallel == TRUE && is.null(cl)) {
        no_cores <- parallel::detectCores()
        cl <- parallel::makeCluster(no_cores)
    } else if (parallel == TRUE && !is.null(cl)) {
        cl <- parallel::makeCluster(cl)
    }

    # HACK: code is clumsy
    if (parallel == TRUE) {
        object_names <- c(object_names, "lib_names")
        parallel::clusterExport(cl, object_names, envir = environment())
        parallel::clusterEvalQ(cl, {
          sapply(lib_names,
                 FUN = function(name) library(name, character.only = TRUE))
        })
    }
    return(cl)
}

## Weisstein, Eric W. "Hypersphere Point Picking." From MathWorld.
## https://mathworld.wolfram.com/HyperspherePointPicking.html

# generate random distribution from the unit hypersphere relative to jumping distribution
.psp_hyper <- function(jump, radius) {
    ## perform simple checks for object types
    if (is.list(jump)) jump <- unlist(jump)
    if (!("numeric" %in% is(jump))) jump <- as.numeric(jump)
    ## generate a random distribution
    gauss <- rnorm(length(jump), mean = 0, sd = 1)
    ## sample points from unit hypersphere and scale it by radius
    points <- (1 / sum(sqrt(gauss ^ 2)) * gauss) *
        runif(1, min = 0, max = radius)
    ## add distance to jumping distribution
    points_interior <- points + jump
    return(points_interior)
}

## Parameter Space Partitioning

psp_global <- function(fn, control = psp_control(), ..., quiet = FALSE) {

    .Deprecated(
        new = "pspGlobal", package = "psp",
        msg = paste("This function is no longer maintained and is scheduled for removal.\nPlease use pspGlobal instead.")
    )

    ## declare all variables
    ctrl <- do.call(psp_control, as.list(control))
    radius <- ctrl$radius
    pop <- ctrl$pop
    init <- ctrl$init
    upper <- ctrl$upper
    lower <- ctrl$lower
    pnames <- ctrl$param_names
    ex_objects <- ctrl$export_objects
    ex_libs <- ctrl$export_libs

    ## set up parallel
    cl <- .parallelize(parallel = ctrl$parallel, cl = ctrl$cl,
                      object_names = ex_objects, lib_names = ex_libs)

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
    evaluate <- fun(parmat_current[1, seq(length(init))], ...)
    if (!is.null(dim(evaluate))) evaluate <- list(evaluate)

    ## create big parameter matrix
    parmat_big <- dota(cbind(parmat_current, evaluate, while_count))
    colnames(parmat_big) <- c(pnames, "pattern", "iteration")

    ## specify location of ordinal pattern in parmat_big
    loc <- colnames(parmat_big)[(length(init) + 1)]

    ## does the ordinal pattern have any dimensions?
    dimension <- any(length(unlist(evaluate)) > 1)

    while (!parameter_filled) {
        while_count <- while_count + 1
        ## construct new set of parameters to search
        new_points <-
            t(apply(parmat_current, 1,
                    function(x) {
                        .psp_hyper(jump = x, radius = radius)
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
           evaluate <- parallel::parApply(cl, new_points, 1, fun, ...),
           evaluate <- apply(new_points, 1, fun, ...))

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
        ## if all regions below population limit, keep sampling
        ## otherwise stop process
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
        ## is iteration limit reached, stop sampling
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
    return(output)
}
