# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Our versioning convenvtions are based on [Semantic Versioning](https://semver.org/).

## [Unreleased]

- 69ed02814ca5a53f773ce13f2ad8faf441ec05c6 :ambulance: continuous model output is not updated after first iteration
- 67fa59df93853e9a786286ee2024fb2ef9b1babe :memo: update package documentation to fix typo

## v1.0.0

This release introduces breaking changes to the API.

- 6d51dcef6af95699fd0064585dfd6b6745b90807 :boom: separated model evaluation functions from discretization functions
- 6d51dcef6af95699fd0064585dfd6b6745b90807 :sparkles: allowed to save model outputs (continuous variables) to disk
- d407392b9bc2f909e5f086790235ba50645537a6 :sparkles: allowed to define multiple starting points for the sampling

## v0.5.8

### Added

- c75d02f2ab9bc76a23502e807717d029be39608f :sparkles: Added a C++ implementation of the parameter space partitioning routine that will take over from `psp_global` and `psp_control`.

### Changed

- b52126debbc25f88c6c41d12810aaedeab23771c :wastebasket: `psp_global` now has a Deprecated message. The function will be removed after we complete the development of `pspGlobal`.
- 358eee7897a9fe3371ebba101f20baad6214609d :bug: fix global R seed interfering with random sampling
- 56935439c4cbc4ba69b62f5ccfb5702c52e8f1d7 🐛 fix pspGlobal recruiting unique inequality matrices more than once
- 56935439c4cbc4ba69b62f5ccfb5702c52e8f1d7 7648f47fd3081f2837af2556c12c476b15916bd3 🐛 fix population parameters having no effects
- 3b3bd0d9da4f27d2ae7cd42432522c2f0d928a46 🚸 pspGlobal outputs maximum iterations run
- 8ee7247eccc1a474d799404e775096f77ece623e :children_crossing: NA values are not allowed in model outputs

### Removed

- c0f5f92e3ffb5753be9357725cea82767eee6936 🔥 `S3` class is removed due to redundancy and to avoid feature creep.

## v0.4.1-beta

### Changed

- f396c774f79ab46a9d70632c4b2b67c052fc221c Fix libraries not exporting to clusters.

## v0.4.0

### Added

- 66d13b0d349a3040b4f58be90dafaa30eac5ed6c :sparkles: `psp_control` has separate arguments for objects vs. packages that it needs
to load into each core.

### Removed

- 66d13b0d349a3040b4f58be90dafaa30eac5ed6c :fire: `cluster_names` is deprecated in `psp_control`, but retained for backwards
compatibility.
- 73dd987dd3d564edf1026a45d5dee8bc98804614 :fire: Removed unnecessary error checks.

## v0.3.1

### Added

- b11d87578ce9a4f7ac9d8e53a5275c38d06c1810 :gift: `psp` can take additional arguments and pass it to `fn`

### Changed

- 6ec1c821dcb6468cd8b632d9b538450201ab00db :bug: returns incorrect dimension attributes of ordinal pattern if it is in a list

## v0.2 pre-release

### Added

- 96db5820032d750bb3b2d0177e47a53fe0114082 :gift: `psp` can now handle ordinal patterns other than strings of characters, e.g. adjacency matrices, list of strings, …
- dd968df2400bc5c4a95d528c61a0b7f50cd447b1 :sparkles: make printing optional

### Changed

- 96db5820032d750bb3b2d0177e47a53fe0114082 :heavy_plus_sign: add `data.table` and `method` dependency
- 7f104e70763210aebf34e8eea3912ae1f077d1da add print method for new S3 `PSP` class

## v0.1

### First Official Stable Release

- stable 0.1 version release [available on CRAN](https://cran.r-project.org/package=psp)
- implements the parameter space partitioning algorithm described by Pitt, Kim, Navarro & Myung (2006)
