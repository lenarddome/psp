require(SphericalCubature)
require(parallel)

# control function
# radius can be a vector of values, but it is preferred if parameter distances
# are kept the same
PSPcontrol <- function(radius = 0.01, init = NULL, lower, upper,
                       pop = 400, negative = FALSE, cl = NULL) {

    ## error functions
    if (length(upper) != length(lower)) {
        stop("Lower and upper boundaries have different lengths!")
    }
    if (ctrl$init != NULL & length(ctrl$init) != length(lower)) {
        stop(paste("init must be either NULL or a vector of same",
                   "length as number of parameters!"))
    }
    if (radius > 1) {
        stop(("region cannot be more than one"))
    } else if (radius > 0.5) {
        warning(paste("region > 0.5\n",
                      "You sample more than half of the parameter space.\n",
                      "Consider defining a smaller region!", sep = ""))
    }
    # set up parallel
    if (is.empty(cl)) {
        no_cores <- parallel::detectCores() - 1
        cl <- parallel::makeCluster(no_cores)
    } else {
        cl <- parallel::makeCluster(cl)
    }
    out <- list(radius = radius,
                pop = pop,
                negative = negative,
                cl = cl,
                init = init,
                lower = lower,
                upper = upper)
    return(out)
}

# generate points in the current state from points in the pervious chain
# converts polar to Cartesian and adds it to the jumping distribution
# second row in out is omitted as the second row is only a residual
PSPsample <-function(init, bounds, radius) {
    phi <- matrix(runif(length(init), min = 0, max = 2 * pi),
                  byrow = TRUE,
                  nrow = 1)
    r <- rep(radius, length(init))
    out <- SphericalCubature::polar2rect(r, phi)
    return(init + out[1, ])
}

# @param {function} fn function returning ordinal response
# @param {matrix} params new points - parameter matrix
# @param {boolean} whether to accept negative value
# @param {cluster-object} cl a cluster object vreated by parallel

PSPmcmc <- function(fn, params, negative, cl) {
    FUN <- match.fun(fn)
    evaluate <- parallel::parApply(cl, params, 1, function(x) {
                                       out <- FUN(x)
                                       return(c(x, out))})
    return(t(evaluate))
}

## Parameter Space Partitioning  ------------------------------------------

## fn = function outputting ordinal response
## lower, upper = lower and upper boundaries for parameters
## control = parameters tuning PSP behaviour
## sampling = the sampling method
## currently aiming to implement mcmc or volesti::direct_sampling
PSPglobal <- function(fn, control = PSPcontrol()) {

    ## declare all variables
    ctrl <- do.call(PSPcontrol, as.list(control))
    radius <- ctrl$radius
    pop <- ctrl$pop
    if (length(radius) == 1) {
        radius <- rep(radius, param_n)
    }
    init <- ctrl$init

    ## define ordinal function
    FUN <- match.fun(fn)

    # miscalleneous variables
    current <- 1
    parameter_filled <- FALSE
    parmat_current <- NULL
    parmat_big <- NULL
    ordinal_big <- NULL

    ## set first parameter set and ordinal pattern
    if (init == NULL) {
        init <- colMeans(rbind(upper, lower))
    }
    parmat_current <- matrix(c(init, 1), nrow = 1)
    evaluate <- FUN(parmat_current[1, seq(length(init))])
    ordinal_big <- type.convert(cbind(pattern = evaluate, # ordinal pattern
                                      region = 1,         # region ID
                                      pop = 1))           # current population size

    while (!parameter_filled) {
        # construct new set of parameters to search
        new_points <- t(apply(parmat_current, 1,
                              function(x) {
                                  PSPsample(init = x[1:length(lower)],
                                            radius = radius)
                              }))
        evaluate <- PSPmcmc(FUN, new_points, negative, cl)
        current <- current + 1

    }
}
