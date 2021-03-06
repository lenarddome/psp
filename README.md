# PSP

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


## About `psp`

- [A short intro and manual](https://lenarddome.github.io/software/psp/)
- [A brief blog post](https://www.andywills.info/2021-06-23-psp/)
