# Benchmarks

psp 1.0.6 fixes the sampler’s centre bookkeeping and removes almost all
of the time
[`pspGlobal()`](https://lenarddome.com/psp/reference/pspGlobal.md)
spends outside your model. This page measures each change against 1.0.5
on the same machine. The results and the scripts that produced them are
in
[`benchmarks/`](https://github.com/lenarddome/psp/tree/main/benchmarks)
on GitHub.

Time per evaluation, near-free model

1.5 µs

was 58 µs in 1.0.5

100-region run

0.012 s

was 10.5 s, stopped at the cap

Cost of saving, per evaluation

13 µs

was 64 µs in 1.0.5

## Time per run

Each workload ran 3 to 10 times with different seeds; dots show the
median wall-clock time of one complete
[`pspGlobal()`](https://lenarddome.com/psp/reference/pspGlobal.md) run.
The cheap toy models make the package’s own overhead visible. With the
test-suite model, most of the time is the model itself.

Median seconds per run, log scale

1.0.51.0.6

The 100-region run in 1.0.5 never filled its regions and stopped at the
1,500-iteration cap; 1.0.6 fills them and stops on its own.

Show the data

| Workload            | Seeds | 1.0.5 (s) | 1.0.6 (s) | Speed-up |
|:--------------------|------:|----------:|----------:|---------:|
| Test-suite model    |    10 |     0.427 |     0.243 |     1.8× |
| 100 regions         |     5 |    10.549 |     0.012 |   879.1× |
| 300 regions         |     3 |     0.463 |     0.221 |     2.1× |
| 300 regions, saving |     3 |     1.706 |     0.555 |     3.1× |
| 1,000 regions       |     3 |     4.719 |     1.872 |     2.5× |

## Where the overhead went

To isolate the package’s own cost, this test uses a model that does
almost nothing: it returns its parameters, and `discretize` bins them
into 1,024 grid cells. Calling those two R functions from a plain R loop
takes 1.4 µs per evaluation, marked by the vertical line. Anything to
the right of it is time
[`pspGlobal()`](https://lenarddome.com/psp/reference/pspGlobal.md) adds.
From `ee4e8b7` on, the remaining gap is within measurement noise.

Time per evaluation with a near-free model, log scale

Median of 3 runs of 150 iterations each, about 1,024 patterns. The
difference column subtracts two timings, so values near zero are noise.

Show the data

| Build | Evaluations | Total per evaluation (µs) | R calls alone (µs) | Difference (µs) |
|:---|---:|---:|---:|---:|
| 1.0.5 | 118,735 | 57.91 | 1.39 | 56.50 |
| fe188ef | 134,468 | 2.17 | 1.47 | 0.70 |
| ee4e8b7 | 134,468 | 1.49 | 1.49 | 0.02 |
| cf77c56 | 134,468 | 1.54 | 1.43 | 0.14 |

The three code commits:

- `fe188ef` fix: one hash-table pass replaces five pairwise loops over
  every stored pattern, and fixes the centre bug.
- `ee4e8b7` perf: one error-protected block per iteration instead of one
  per R call, which removes two `setjmp` system calls per call on macOS.
- `cf77c56` perf: `std::to_chars` for saved csv rows. It only affects
  `save = TRUE`, shown below.

## The centre bug

Each region is explored from the last point that produced its pattern.
In 1.0.5, `LastEvaluatedParameters` added a row for every stored pattern
that was *not* seen in an iteration, instead of for every new one. Rows
then stopped lining up with patterns, and new regions were explored from
a point in another region.

The table comes from an instrumented copy of 1.0.5 on a 300-region
model. For each iteration count, it shows how many stored centres
actually produce their own pattern.

| Iterations | Patterns found | Centre matrix rows | Centres that produce their own pattern |
|---:|---:|---:|---:|
| 3 | 19 | 32 | 10 of 19 (53%) |
| 5 | 26 | 56 | 15 of 26 (58%) |
| 10 | 48 | 167 | 25 of 48 (52%) |
| 25 | 145 | 920 | 92 of 145 (63%) |
| 100 | 300 | 7,890 | 300 of 300 (100%) |

Wrong centres cost model evaluations, and sometimes stopped a run from
finishing at all. On the 100-region workload, every 1.0.5 run hit its
1,500-iteration cap with regions still unfilled, after a median of
14,396 model evaluations. 1.0.6 filled every region after a median of
2,235.

## Saving to disk

With `save = TRUE`, every evaluation writes its parameters and its model
outputs, here 300 values, to csv. 1.0.5 wrote 6 significant digits;
1.0.6 writes the shortest text that reads back as exactly the same
number. Fast formatting with `std::to_chars` needs macOS 13.3 or later,
or libstdc++ 11 or later. Other platforms fall back to `%.17g`, which is
exact but slower.

Full precision has two costs. The files are 2.7 times larger than
1.0.5’s 6-digit files (140 MB against 51 MB in this workload). Without
`std::to_chars`, saving is also 47% slower than in 1.0.5.

Extra time per evaluation with save = TRUE (µs)

300 regions, 100 iterations, median of 3 seeds. The save cost is the run
time with saving minus the same seeded run without it.

Show the data

| Build | Formatting | Saving adds (µs per evaluation) | Files (MB) |
|:---|:---|---:|---:|
| 1.0.5 | ostream, 6 digits | 64.4 | 51.5 |
| fe188ef | ostream, 15 digits | 110.7 | 129.7 |
| ee4e8b7 | ostream, 15 digits | 111.4 | 129.7 |
| cf77c56, to_chars | exact, shortest form | 13.4 | 140.2 |
| cf77c56, fallback | exact, %.17g | 94.3 | 144.4 |

## Finding regions

Faster is only useful if the search still finds the regions. These are
30 runs per build on a 50-region model with 3 parameters, population 10,
radius 0.3 and a 500-iteration cap. 1.0.6 finds slightly more regions
per run, with about a quarter of the model evaluations.

Regions found per run, out of 50

1.0.51.0.6

Model evaluations per run

1.0.51.0.6

One dot per seed, grouped to the nearest 100. Hollow dots are runs that
hit the 500-iteration cap without filling every region: 29 of 30 runs in
1.0.5, 0 of 30 in 1.0.6.

Show the data

| Build | Seed | Regions | Evaluations | Iterations | Filled |
|:------|-----:|--------:|------------:|-----------:|:-------|
| 1.0.5 |    1 |      48 |         816 |         81 | yes    |
| 1.0.5 |    2 |      49 |       3,246 |        500 | no     |
| 1.0.5 |    3 |      45 |       2,103 |        500 | no     |
| 1.0.5 |    4 |      49 |       3,071 |        500 | no     |
| 1.0.5 |    5 |      45 |       1,566 |        500 | no     |
| 1.0.5 |    6 |      49 |       2,325 |        500 | no     |
| 1.0.5 |    7 |      47 |       3,947 |        500 | no     |
| 1.0.5 |    8 |      48 |       2,396 |        500 | no     |
| 1.0.5 |    9 |      45 |       2,661 |        500 | no     |
| 1.0.5 |   10 |      50 |       1,278 |        500 | no     |
| 1.0.5 |   11 |      50 |       3,626 |        500 | no     |
| 1.0.5 |   12 |      47 |       4,054 |        500 | no     |
| 1.0.5 |   13 |      46 |       2,968 |        500 | no     |
| 1.0.5 |   14 |      47 |       2,256 |        500 | no     |
| 1.0.5 |   15 |      47 |       3,391 |        500 | no     |
| 1.0.5 |   16 |      48 |       1,403 |        500 | no     |
| 1.0.5 |   17 |      49 |       1,757 |        500 | no     |
| 1.0.5 |   18 |      49 |       2,233 |        500 | no     |
| 1.0.5 |   19 |      41 |       3,710 |        500 | no     |
| 1.0.5 |   20 |      44 |       2,265 |        500 | no     |
| 1.0.5 |   21 |      43 |       3,397 |        500 | no     |
| 1.0.5 |   22 |      38 |       1,977 |        500 | no     |
| 1.0.5 |   23 |      43 |       3,637 |        500 | no     |
| 1.0.5 |   24 |      49 |       1,846 |        500 | no     |
| 1.0.5 |   25 |      49 |       2,781 |        500 | no     |
| 1.0.5 |   26 |      38 |       3,790 |        500 | no     |
| 1.0.5 |   27 |      50 |       1,291 |        500 | no     |
| 1.0.5 |   28 |      49 |       1,846 |        500 | no     |
| 1.0.5 |   29 |      46 |       4,070 |        500 | no     |
| 1.0.5 |   30 |      50 |       1,814 |        500 | no     |
| 1.0.6 |    1 |      50 |         673 |         61 | yes    |
| 1.0.6 |    2 |      49 |         699 |         70 | yes    |
| 1.0.6 |    3 |      50 |         659 |         53 | yes    |
| 1.0.6 |    4 |      50 |         703 |         92 | yes    |
| 1.0.6 |    5 |      49 |         684 |         89 | yes    |
| 1.0.6 |    6 |      48 |         652 |         57 | yes    |
| 1.0.6 |    7 |      48 |         619 |         49 | yes    |
| 1.0.6 |    8 |      50 |         676 |         61 | yes    |
| 1.0.6 |    9 |      50 |         662 |         60 | yes    |
| 1.0.6 |   10 |      47 |         620 |         53 | yes    |
| 1.0.6 |   11 |      49 |         667 |         54 | yes    |
| 1.0.6 |   12 |      47 |         652 |         64 | yes    |
| 1.0.6 |   13 |      49 |         631 |         60 | yes    |
| 1.0.6 |   14 |      49 |         652 |         54 | yes    |
| 1.0.6 |   15 |      48 |         673 |         72 | yes    |
| 1.0.6 |   16 |      49 |         690 |         77 | yes    |
| 1.0.6 |   17 |      49 |         631 |         57 | yes    |
| 1.0.6 |   18 |      47 |         695 |        140 | yes    |
| 1.0.6 |   19 |      49 |         610 |         55 | yes    |
| 1.0.6 |   20 |      49 |         620 |         55 | yes    |
| 1.0.6 |   21 |      47 |         556 |         53 | yes    |
| 1.0.6 |   22 |      48 |         640 |         59 | yes    |
| 1.0.6 |   23 |      47 |         578 |         51 | yes    |
| 1.0.6 |   24 |      48 |         674 |         73 | yes    |
| 1.0.6 |   25 |      44 |         592 |         70 | yes    |
| 1.0.6 |   26 |      47 |         628 |         52 | yes    |
| 1.0.6 |   27 |      46 |         611 |         82 | yes    |
| 1.0.6 |   28 |      47 |         613 |         66 | yes    |
| 1.0.6 |   29 |      47 |         676 |         60 | yes    |
| 1.0.6 |   30 |      49 |         662 |         61 | yes    |

PSP never guarantees finding every region. It only finds regions it can
reach before every found region is full. The settings below change that,
measured on the same model with 30 seeds each.

| Settings | Regions found per run | Runs that found all 50 | Median evaluations |
|:---|:---|---:|---:|
| 1 start, population 10, radius 0.3 | 45–50, median 49 | 11 of 30 | 665 |
| 10 random starts, population 10 | 44–50, median 49 | 8 of 30 | 649 |
| 1 start, population 30 | 49–50, median 50 | 29 of 30 | 1,908 |
| 1 start, population 10, radius 0.5 | 48–50, median 50 | 24 of 30 | 874 |
| 10 random starts, population 30 | 49–50, median 50 | 27 of 30 | 1,874 |
| 3 pooled runs of 10 starts, population 10 | 49–50, median 50 | 29 of 30 | 1,957 |

Raising `population` helps most. A larger `radius` is cheaper, but in a
real model it can jump over small regions. Pooling independent runs is a
useful completeness check: if a second run finds a pattern the first
missed, the first wasn’t complete. The
[tutorial](https://lenarddome.com/psp/articles/tutorial.md) shows how.

## How this was measured

| Environment |  |
|:---|:---|
| Machine | Apple M2 Pro, 10 cores, 16 GB, macOS 27.0.1 |
| R | R 4.6.1, single-threaded |
| Compiler | Apple clang 21.0.0, -O2 |
| Packages | Rcpp 1.1.2, RcppArmadillo 15.6.0.1 |
| Builds | 1.0.5 (b055424) and the three code commits merged in pull request \#6; the fallback build is cf77c56 compiled for macOS 11 |
| Date | 5 October 2026 |

| Workload | Model | Settings |
|:---|:---|:---|
| Test-suite model | the model from tests/testthat/test_psp_cpp.R: distances to 100 points, 5 parameters | population 10, radius 1, cap 1,000, 10 starting points, 10 seeds |
| 100 regions | cheap Voronoi model: squared distance to 100 random centres, 5 parameters | population 20, radius 0.3, cap 1,500, one start at 0.5, 5 seeds |
| 300 and 1,000 regions | the same cheap model with 300 or 1,000 centres | 100 iterations, population never reached, radius 0.3, 3 seeds |
| Overhead | returns its parameters; discretize bins them into 1,024 grid cells | 150 iterations, 3 repeats |
| Discovery | cheap Voronoi model, 50 centres, 3 parameters | population 10, radius 0.3, cap 500, 30 seeds |

Times are single-threaded
[`system.time()`](https://rdrr.io/r/base/system.time.html) elapsed
seconds with `quiet = TRUE`, and each build ran in its own R process.
Commits `ee4e8b7` and `cf77c56` produce bit-identical samples to
`fe188ef` for the same seed, so their differences are pure speed. 1.0.5
samples differently because of the bug fixes.

All numbers come from one machine. Linux and Windows were not measured;
the `setjmp` saving in `ee4e8b7` is mostly specific to macOS. To
re-measure, install each build of psp into its own library and run, for
each one:

``` sh
Rscript benchmarks/benchmark.R <library> <label> | tail -n +2 >> benchmarks/results/workloads.csv
Rscript benchmarks/experiments.R <library> <label> overhead,save,discovery
```

Then rebuild the website; this page reads `benchmarks/results/` when it
is built.
