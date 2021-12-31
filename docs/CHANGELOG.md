# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

## [Unreleased]

### Added

- :gift: `psp` can take additional arguments and pass it to `fn`

### Changed

- *fix* returns incorrect dimension attributes of ordinal pattern if it is in a list

## v0.2 pre-release

### Added

- :gift: `psp` can now handle ordinal patterns other than strings of characters, e.g. adjacency matrices, list of strings, ...

### Changed

- :heavy_plus_sign: add `data.table` and `method` dependency
- add print method for new S3 `PSP` class

## v0.1

### First Official Stable Release

- stable 0.1 version release [available on CRAN](https://cran.r-project.org/package=psp)
- implements the parameter space partitioning algorithm described by Pitt, Kim, Navarro & Myung (2006)
