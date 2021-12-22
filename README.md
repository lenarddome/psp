# PSP

[![R-CMD-check](https://github.com/lenarddome/psp/actions/workflows/main.yml/badge.svg)](https://github.com/lenarddome/psp/actions/workflows/main.yml)
[![](https://cranlogs.r-pkg.org/badges/grand-total/psp)](https://cran.r-project.org/package=psp)
![CRAN/METACRAN](https://img.shields.io/cran/v/psp)
![CRAN/METACRAN](https://img.shields.io/cran/l/psp)

Parameter Space Partitioning MCMC for Global Model Evaluation (Pitt, Kim, Navarro
& Myung, 2006).

[CRAN page of psp](https://CRAN.R-project.org/package=psp)

To cite package ‘psp’ in publications use:

  Lenard Dome and Andy Wills (2021). psp: Parameter Space Partitioning
  MCMC for Global Model Evaluation. R package version 0.1.
  https://CRAN.R-project.org/package=psp

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

## Philosophy

A big influence on this implementation is an instantiation of the Open Models
Initiative, [catlearn](https://github.com/ajwills72/catlearn).

Watch the talk of [Andy Wills: “The OpenModels project”](https://youtu.be/SfqkqEYagJU)
from Open Research Working Group (ORWG) virtual meeting 08/09/20.

The project's architecture is also influenced by [DEoptim](https://github.com/ArdiaD/DEoptim).
`DEoptim` implements a Differential Evolutionary Optimization algorithm for
model-fitting.

We are completely open-source and free. Anyone can contribute. If you would
like to raise an issue or contribute code, use Github, message or email me
(@lenarddome).

## Design [in development]

More about the architecture and coding styles will be added later.

## Commit emoji convention

- :memo: Add comment or doc
- :gift: New feature.
- :bug: Bug fix.
- :bomb: Breaking compatibility.
- :white_check_mark: Write test.
- :fire: Remove something.
- :beer: I'm happy like reduced code complexity.
- :bookmark: Release/Version tag.
- :construction: Release candidate.
- :heavy_plus_sign: Add dependency.
- :heavy_minus_sign: Remove dependency.

## About `psp`

- [A short intro and manual](https://lenarddome.github.io/software/psp/)
- [A brief blog post](https://www.andywills.info/2021-06-23-psp/)
