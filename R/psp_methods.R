## Set print methods for PSP class
print.PSP <- function(x, ...) {
              all <- nrow(x$ps_partitions)
              cat("\nFrequency of Patterns Discovered:\n")
              print(x$ps_patterns)
              cat(paste("\nEvaluated", all, "points. Found",
                        length(unique(x$ps_ordinal)), "unique patterns."))
}
