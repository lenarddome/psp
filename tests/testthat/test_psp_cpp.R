context('pspGlobal')
euclidean <- function(a, b) sqrt(sum((a - b)^2))

# define center points for the 10 regions in a two-dimensional space
positions <- NULL
# set seed
set.seed(7624)
for (i in seq_len(5)) positions <- cbind(positions, sample(500, 100))

## calculates distances and gives a non-sensical inequality matrix
model <-  function(par) {
  areas <- NULL
  for (i in seq_along(par)) {
      range <- c(1, 0)
      if (i %% 2 == 0) {
          range <- c(0, 1)
      }
      areas <- cbind(areas, seq(range[1], range[2], length.out = 500)[positions[, i]])
  }
  distances <- apply(areas, 1, euclidean, b = par)
  return(distances)
}

discretize <- function(distances, legacy = FALSE) {
  if (legacy) {
    out <- as.character(which.min(distances))
  } else {
    out <- matrix(which.min(distances), nrow = 2, ncol = 2)
  }
  return(out)
}

out2 <- pspGlobal(model = model, discretize = discretize,
                 control = list(iterations = 1000,
                                population = 10,
                                radius = 1,
                                lower = rep(0, 5),
                                upper = rep(1, 5),
                                init = matrix(rep(seq(0, 1, length.out = 10), 5), nrow = 10, byrow = TRUE),
                                parameter_names = c('a', 'd', 'z', 'y', 'x'),
                                stimuli_names = as.character(seq(100)),
                                dimensionality = 2,
                                responses = 100),
                                quiet = FALSE, save = FALSE)

test_that("PSP finds all 100 regions in a 5 parameter model", {
              expect_equal(dim(out2$ordinal_pattern)[3], 100)
          })

test_that("PSP population terminates algorithm before iteration cap reached", {
  expect_true(out2$iterations < 1000)
  }
)

test_that("Part 1: Unique unequality matrices only recruited once", {
  expect_true(all(!(table(out2$ordinal_patterns) > 4)))
  }
)

foo <- lapply(seq(dim(out2$ordinal_patterns)[3]), function(x) out2$ordinal_patterns[ , , x])

test_that("Part 2: PSP only recruits items once", {
    expect_equal(dim(out2$ordinal_patterns)[3], length(foo))
  }
)


out3 <- pspGlobal(model = model, discretize = discretize,
                 control = list(iterations = 100,
                                population = 30000,
                                radius = 1,
                                lower = rep(0, 5),
                                upper = rep(1, 5),
                                init = matrix(rep(seq(0, 1, length.out = 10), 5), nrow = 10, byrow = TRUE),
                                parameter_names = c('a', 'd', 'z', 'y', 'x'),
                                stimuli_names = as.character(seq(100)),
                                dimensionality = 2,
                                responses = 100),
                                quiet = FALSE, save = FALSE)

test_that("PSP iteration threshold terminates algorithm succesfully", {
  expect_true(out3$iterations == 100)
  }
)
