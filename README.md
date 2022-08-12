# PSP

[![R-CMD-check](https://github.com/lenarddome/psp/actions/workflows/main.yml/badge.svg)](https://github.com/lenarddome/psp/actions/workflows/main.yml)
[![](https://cranlogs.r-pkg.org/badges/grand-total/psp)](https://cran.r-project.org/package=psp)
![GitHub release (latest SemVer including pre-releases)](https://img.shields.io/github/v/release/lenarddome/psp?include_prereleases)
![CRAN/METACRAN](https://img.shields.io/cran/v/psp)
![CRAN/METACRAN](https://img.shields.io/cran/l/psp)

Parameter Space Partitioning MCMC for Global Model Evaluation (Pitt, Kim, Navarro & Myung, 2006).

[CRAN page of psp](https://CRAN.R-project.org/package=psp)

To cite package ‘psp’ in publications use:

  Lenard Dome and Andy Wills (2021). psp: Parameter Space Partitioning MCMC for Global Model Evaluation. R package version 0.1. https://CRAN.R-project.org/package=psp

A BibTeX entry for LaTeX users is

```
  @Manual{,
    title = {psp: Parameter Space Partitioning MCMC for Global Model Evaluation},
    author = {Lenard Dome and {Andy Wills}},
    year = {2021},
    note = {R package version 0.1},
    url = {https://CRAN.R-project.org/package=psp},
  }
```

## Support

<a href="https://www.buymeacoffee.com/lenarddome" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-yellow.png" alt="Buy Me A Coffee" height="57"></a>

## Install

For the stable version

```r
install.packages("psp")
```

For the developmental version:

```r
devtools::install_github("lenarddome/psp")
```

## About `psp`

- [A short intro and manual](https://lenarddome.github.io/software/psp/)
- [A brief blog post](https://www.andywills.info/2021-06-23-psp/)

## Philosophy

A big influence on this implementation is an instantiation of the Open Models
Initiative, [catlearn](https://github.com/ajwills72/catlearn).
Watch the talk of [Andy Wills: “The OpenModels project”](https://youtu.be/SfqkqEYagJU) from Open Research Working Group (ORWG) virtual meeting 08/09/20.

The project's architecture is also influenced by [DEoptim](https://github.com/ArdiaD/DEoptim).
`DEoptim` implements a Differential Evolutionary Optimization algorithm formodel-fitting.

We are completely open-source and free. Anyone can contribute. If you would like to raise an issue or contribute code, use Github, message or email me (@lenarddome).

## Code Style

We use [Google’s R Style Guide](https://google.github.io/styleguide/Rguide.html) with some extra caveats:

- Do not use `roxygen`. Write your documentation from scratch as an Rdocumentation file. It is desirable to avoid writing test units for converting your comments to documentation.
- We have a 100 characters per line policy. You are still encouraged to keep line lengths to 80 characters, but sometimes going over 80 can be better than the alternative.
- Use TODO, FIXME, HACK, BUG, WARNING, NOTE comments for code that is temporary, a short-term solution, or good-enough but not perfect.
  - TODO comments must adhere to the following format: `## TODO: change this to use matrix operations`.
- Use spaces!
  - Good practice: `if (makeup == TRUE) list(variable = runif(100), id = rep(letters, 5)[1:100])`.
  - Bad practice: `if(makeup==TRUE) list(variable=runif(100),id=rep(letters,5)[1:100])`.
- Do not number your files. File naming conventions are pretty straightforward:
  - Files are prefixed by their relation to groups of functions. For example, the prefix `psp` means that the file contains function relevant for the parameter space partitioning routines.
  - Files use camelCase.
  - File names must not contain spaces.
- Apply the same conventions to C++ code as well. While we do not militantly adhere to this, study [Google's C++ Style Guide](https://google.github.io/styleguide/cppguide.html).