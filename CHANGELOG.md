# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a
Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased](https://github.com/lenarddome/psp/compare/v1.0.6...HEAD)

## [1.0.6](https://github.com/lenarddome/psp/compare/v1.0.5...v1.0.6) - 2026-10-06

Sampling results differ from 1.0.5 for the same seed, because the fixes
below change the path the sampler takes.

### Added

- A package website at <https://lenarddome.com/psp/>, built with pkgdown
  and deployed to GitHub Pages, with a tutorial that partitions the
  parameter space of prospect theory and a benchmark report comparing
  1.0.6 to 1.0.5.
- The benchmark results and the scripts that produce them in
  `benchmarks/`.
- A recipe that partitions ALCOVE’s parameter space on the six Shepard,
  Hovland and Jenkins (1961) problems, following Pitt et al. (2006),
  with the scripts and saved results it reads in
  `vignettes/articles/alcove/`.
- `benchmarks/benchmark.R` for comparing the speed of two builds of the
  package.
- Tests for the sampler’s invariants (centres, counts, saved output,
  pattern identity, control validation) and for the contract with
  `model` and `discretize`.

### Changed

- The [`pspGlobal()`](https://lenarddome.com/psp/reference/pspGlobal.md)
  documentation cites the published version of g-distance (Dome & Wills,
  2025, *Psychological Review*) instead of the preprint.
- `pspGlobal` matches ordinal patterns with a hash table in a single
  pass instead of five pairwise comparison loops over every stored
  pattern, and no longer copies the stored patterns on every iteration.
- `model` and `discretize` are called through one error-protected block
  per iteration instead of one per call, which removes two `setjmp`
  system calls per evaluation on macOS.
- Output files are opened once per run instead of on every write, and
  each row is written in a single call.
- Saved csv values are formatted with `std::to_chars` where the compiler
  supports it (macOS 13.3 or later, libstdc++ 11 or later), which makes
  writing them about 5 times faster than in 1.0.5. Other platforms use
  `%.17g`, which is about 45% slower than 1.0.5 because it writes full
  precision.
- `model` output of the wrong length or type, and `discretize` output
  that is not a `dimensionality` x `dimensionality` numeric matrix, now
  stop with a message that names the problem instead of an Armadillo
  error.

### Fixed

- New ordinal patterns were sampled from the wrong centre:
  `LastEvaluatedParameters` appended rows for stored patterns that were
  not seen instead of for new patterns, so up to half of the newly
  discovered regions were explored from a point in another region. Each
  pattern’s centre is now the last parameter set that produced it.
- The first ordinal pattern was counted one extra time.
- The first iteration only proposed from the first pattern instead of
  from every underpopulated pattern found by `init`.
- Identical ordinal patterns containing `NaN` were stored as a new
  pattern on every evaluation.
- Saved csv files rounded parameters and model outputs to 6 significant
  digits; they are now written with full double precision, which makes
  the files about 2.7 times larger.

## [1.0.5](https://github.com/lenarddome/psp/compare/v1.0.2...v1.0.5) - 2026-01-15

### Changed

- Modernize tests by removing deprecated
  [`testthat::context()`](https://testthat.r-lib.org/reference/context.html)
  usage
  ([84d0b19](https://github.com/lenarddome/psp/commit/84d0b19482a6b56033ec52a278248e064dd5d3c5)).
- Keep `src/Makevars` minimal, linking LAPACK, BLAS and FLIBS only
  ([97cf4e9](https://github.com/lenarddome/psp/commit/97cf4e92dbf52dc2a5dc24edf45422c5e46f63f2)).

### Fixed

- Armadillo helper edge cases in `pspGlobal` that caused null subviews
  and undefined behaviour
  ([e60c3b3](https://github.com/lenarddome/psp/commit/e60c3b3f5c770a5c95267294c12a761c5abbf707),
  [4ac2b01](https://github.com/lenarddome/psp/commit/4ac2b013ed85d158c2cb1f1de03e6113c4ce1fac)).

## [1.0.2](https://github.com/lenarddome/psp/compare/v1.0.0...v1.0.2) - 2024-07-24

This is the last feature update from me. If you want to add new
features, please get in touch (@lenarddome).

### Fixed

- Continuous model output was not updated after the first iteration
  ([69ed028](https://github.com/lenarddome/psp/commit/69ed02814ca5a53f773ce13f2ad8faf441ec05c6)).
- Typo in the package documentation
  ([67fa59d](https://github.com/lenarddome/psp/commit/67fa59df93853e9a786286ee2024fb2ef9b1babe)).

## [1.0.0](https://github.com/lenarddome/psp/compare/v0.5.8...v1.0.0) - 2023-08-17

Released on [CRAN](https://cran.r-project.org/package=psp). This version
introduces API-breaking changes. For a full list of feature changes
since the previous CRAN release, see
[docs/CHANGELOG.md](https://github.com/lenarddome/psp/blob/main/docs/CHANGELOG.md).

### Added

- Model outputs (continuous variables) can be saved to disk
  ([6d51dce](https://github.com/lenarddome/psp/commit/6d51dcef6af95699fd0064585dfd6b6745b90807)).
- Multiple starting points can be defined for the sampling
  ([d407392](https://github.com/lenarddome/psp/commit/d407392b9bc2f909e5f086790235ba50645537a6)).

### Changed

- **Breaking:** model evaluation functions are separated from
  discretization functions
  ([6d51dce](https://github.com/lenarddome/psp/commit/6d51dcef6af95699fd0064585dfd6b6745b90807)).

## [0.5.8](https://github.com/lenarddome/psp/compare/v0.5.6-beta...v0.5.8) - 2022-08-16

### Added

- A C++ implementation of the parameter space partitioning routine,
  `pspGlobal`, that will take over from `psp_global` and `psp_control`
  ([c75d02f](https://github.com/lenarddome/psp/commit/c75d02f2ab9bc76a23502e807717d029be39608f)).
- `pspGlobal` returns the number of iterations run
  ([3b3bd0d](https://github.com/lenarddome/psp/commit/3b3bd0d9da4f27d2ae7cd42432522c2f0d928a46)).

### Changed

- NA values are not allowed in model outputs
  ([8ee7247](https://github.com/lenarddome/psp/commit/8ee7247eccc1a474d799404e775096f77ece623e)).

### Deprecated

- `psp_global` now shows a deprecation message. It will be removed once
  `pspGlobal` is complete
  ([b52126d](https://github.com/lenarddome/psp/commit/b52126debbc25f88c6c41d12810aaedeab23771c)).

### Removed

- The `S3` class, to avoid redundancy and feature creep
  ([c0f5f92](https://github.com/lenarddome/psp/commit/c0f5f92e3ffb5753be9357725cea82767eee6936)).

### Fixed

- The global R seed interfered with random sampling
  ([358eee7](https://github.com/lenarddome/psp/commit/358eee7897a9fe3371ebba101f20baad6214609d)).
- `pspGlobal` recruited unique inequality matrices more than once
  ([5693543](https://github.com/lenarddome/psp/commit/56935439c4cbc4ba69b62f5ccfb5702c52e8f1d7)).
- Population parameters had no effect
  ([5693543](https://github.com/lenarddome/psp/commit/56935439c4cbc4ba69b62f5ccfb5702c52e8f1d7),
  [7648f47](https://github.com/lenarddome/psp/commit/7648f47fd3081f2837af2556c12c476b15916bd3)).
