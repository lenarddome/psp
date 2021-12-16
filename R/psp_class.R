## General class for psp results
setClass("PSP", representation(
  ps_partitions = "data.table",
  ps_patterns = "table",
  ps_ordinal = "list"
))


## Set print methods for PSP class
setMethod(show, signature = "PSP",
          function(object) {
              all <- nrow(object$ps_partitions)
              cat(paste("\nEvaluated", all, "points.\n"))
              cat("\nFrequency of Patterns Discovered\n")
              print(object$ps_patterns)
          }
)

print.PSP <- function(object) {
    cat("PSP result:\n"); show(object)
}
