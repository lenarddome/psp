# PSP

Parameter Space Partitioning MCMC for Global Model Evaluation

## TODO

1. [priority] implement stopping criterion (each region is sampled n times)
2. [done][priority] 2D model test unit
3. [essential] describe the process mathematically
4. [done][optional] nonoverlapping hypercube model: evaluate which cube the sampled coordinates belong

## PSPglobal

Partition Parameter Space according to input parameters.

## PSPvolume [will not be included]

Calculate volume of the polytope partitions as defined by PSPglobal.
Probably will depend on [volesti](https://cran.r-project.org/web/packages/volesti/index.html)

### REPORT 2021-01-27T12:39:54+0000

Not feasible to implement a method that generalizes to n-dimensional polyhedra
or convex polytope. Leave it for the user. The method of calculating the
volume/area of each region should be an analysis choice.

## BURN-IN [will not be implemented]

If you have a decent starting point (params EXIT uses to produce IBRE),
burn-in might be unnecessary.

I am also not sure why burn-in is necessary for parameter space partitioning.
This option might be optional, but it seems counterintuitive to discard areas
you explored in the parameter space if you'd like to explore said parameter
space.

Resources to look through:
* https://stats.stackexchange.com/questions/88819/mcmc-methods-burning-samples
* http://users.stat.umn.edu/%7Egeyer/mcmc/burn.html
* https://www.johndcook.com/blog/2016/01/25/mcmc-burn-in/
