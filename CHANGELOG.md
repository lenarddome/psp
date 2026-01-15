# Changelog

## 1.0.5 - 2026-01-15


- [e60c3b3](https://github.com/lenarddome/psp/commit/e60c3b3f5c770a5c95267294c12a761c5abbf707) [4ac2b01](https://github.com/lenarddome/psp/commit/4ac2b013ed85d158c2cb1f1de03e6113c4ce1fac) :ambulance: Fix Armadillo helper edge cases in `pspGlobal` to avoid null subviews and undefined behavior.
- [84d0b19](https://github.com/lenarddome/psp/commit/84d0b19482a6b56033ec52a278248e064dd5d3c5) :alien: Modernize tests by removing deprecated `testthat::context()` usage. 
- [97cf4e9](https://github.com/lenarddome/psp/commit/97cf4e92dbf52dc2a5dc24edf45422c5e46f63f2) :green_heart: Keep `src/Makevars` minimal (linking LAPACK/BLAS/FLIBS only).

# v1.0.2

- 69ed02814ca5a53f773ce13f2ad8faf441ec05c6 :ambulance: continuous model output is not updated after the first iteration
- 67fa59df93853e9a786286ee2024fb2ef9b1babe :memo: update package documentation to fix typo

## Disclaimer

This is the last feature update from me. If you want to add new features, please get in touch (@lenarddome).
# v.1.0.0

This is the **latest stable version** available from CRAN; see package [page](https://cran.r-project.org/package=psp).

# Added since v0.5.8:

The current version introduces API-breaking changes to the package. For a full list of feature changes since the latest CRAN release, see [CHANGELOG](https://github.com/lenarddome/psp/blob/main/docs/CHANGELOG.md).

- 6d51dcef6af95699fd0064585dfd6b6745b90807 :boom: separated model evaluation functions from discretization functions
- 6d51dcef6af95699fd0064585dfd6b6745b90807 :sparkles: allowed to save model outputs (continuous variables) to disk
- d407392b9bc2f909e5f086790235ba50645537a6 :sparkles: allowed to define multiple starting points for the sampling

# v0.5.8

- c75d02f2ab9bc76a23502e807717d029be39608f :sparkles: Added a C++ implementation of the parameter space partitioning routine that will take over from `psp_global` and `psp_control`.
- b52126debbc25f88c6c41d12810aaedeab23771c :wastebasket: `psp_global` now has a Deprecated message. The function will be removed after we complete the development of `pspGlobal`.
- 358eee7897a9fe3371ebba101f20baad6214609d :bug: fix global R seed interfering with random sampling
- 56935439c4cbc4ba69b62f5ccfb5702c52e8f1d7 🐛 fix pspGlobal recruiting unique inequality matrices more than once
- 56935439c4cbc4ba69b62f5ccfb5702c52e8f1d7 7648f47fd3081f2837af2556c12c476b15916bd3 🐛 fix population parameters having no effects
- 3b3bd0d9da4f27d2ae7cd42432522c2f0d928a46 🚸 pspGlobal outputs maximum iterations run
- 8ee7247eccc1a474d799404e775096f77ece623e :children_crossing: NA values are not allowed in model outputs
- c0f5f92e3ffb5753be9357725cea82767eee6936 🔥 `S3` class is removed due to redundancy and to avoid feature creep.