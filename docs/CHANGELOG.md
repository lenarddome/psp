# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

## [Unreleased]

### Added

- Added a C++ implementation of the parameter space partitioning routine that will take over from `psp_global` and `psp_control`.

### Changed

- `psp_global` now has a Deprecated message. The function will be removed after we complete the development of `pspGlobal`.

### Removed

- `S3` class is removed due to redundancy and to avoid feature creep.

## v0.4.1-beta

### Changed

- Fix libraries not exporting to clusters.

## v0.4.0

### Added

- `psp_control` has separate arguments for objects vs. packages that it needs
to load into each core.

### Removed

- `cluster_names` is deprecated in `psp_control`, but retained for backwards
compatibility.
- Removed unnecessary error checks.

## v0.3.1

### Added

- :gift: `psp` can take additional arguments and pass it to `fn`

### Changed

- *fix* returns incorrect dimension attributes of ordinal pattern if it is in a list

## v0.2 pre-release

### Added

- :gift: `psp` can now handle ordinal patterns other than strings of characters, e.g. adjacency matrices, list of strings, …

### Changed

- :heavy_plus_sign: add `data.table` and `method` dependency
- add print method for new S3 `PSP` class

## v0.1

### First Official Stable Release

- stable 0.1 version release [available on CRAN](https://cran.r-project.org/package=psp)
- implements the parameter space partitioning algorithm described by Pitt, Kim, Navarro & Myung (2006)
