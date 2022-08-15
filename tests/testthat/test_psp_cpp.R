context('pspGlobal')
euclidean <- function(a, b) sqrt(sum((a - b)^2))

# define center points for the 10 regions in a two-dimensional space
positions <- NULL
# set seed
set.seed(7624)
for (i in seq_len(5)) positions <- cbind(positions, sample(500, 100))

## calculates distances and gives a non-sensical inequality matrix
model <-  function(par, legacy = FALSE) {
  areas <- NULL
  for (i in seq_along(par)) {
      range <- c(1, 0)
      if (i %% 2 == 0) {
          range <- c(0, 1)
      }
      areas <- cbind(areas, seq(range[1], range[2], length.out = 500)[positions[, i]])
  }
  distances <- apply(areas, 1, euclidean, b = par)

  if (legacy) {
    out <- as.character(which.min(distances))
  } else {
    out <- matrix(which.min(distances), nrow = 2, ncol = 2)
  }
  return(out)
}

out2 <- pspGlobal(model = model,
                 control = list(iterations = 1000,
                                population = 30,
                                radius = 1,
                                lower = rep(0, 5),
                                upper = rep(1, 5),
                                init = rep(0.5, 5),
                                param_names = c('a', 'd', 'z', 'y', 'x'),
                                quiet = FALSE))

test_that("PSP finds all 100 regions in a 5 parameter model", {
              expect_equal(dim(out2$ordinal_pattern)[3], 100)
          })

test_that("", {
  expect_true(out2$iterations < 1000)
  }
)

test_that("Unique unequality matrices only recruited once", {
  expect_true(all(!(table(out2$ordinal_patterns) > 4)))
  }
)

out3 <- pspGlobal(model = model,
                 control = list(iterations = 100,
                                population = 30000,
                                radius = 1,
                                lower = rep(0, 5),
                                upper = rep(1, 5),
                                init = rep(0.5, 5),
                                param_names = c('a', 'd', 'z', 'y', 'x'),
                                quiet = FALSE))

test_that("PSP iteration threshold", {
  expect_true(out3$iterations == 100)
  }
)
