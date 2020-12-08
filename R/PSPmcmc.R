# @param {function} fn function returning ordinal response
# @param {matrix} bounds parameter bounds
# @param {boolean} whether to accept negative value 
# @param {cluster-object} cl a cluster object vreated by parallel

PSPmcmc <- function(fn, bounds, pop, cl) {
    params <- matrix(
                runif(length(ncol(bounds)) * pop,
                      min = bounds[1, ], bounds[2, ]),
                ncol = ncol(bounds), byrow = TRUE)
    FUN <- match.fun(fn)
    evaluate <- parallel::parApply(cl, params, 1, function(x) {
                                       out <- FUN(x)
                                       return(c(x, out))})
    return(t(evaluate))
}
