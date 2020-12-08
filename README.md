# globalqfme

Global and Qualitative Formal Model Evaluations


```R
set up parameter space
define first region

while (parameter space is not filled) {
    loop through regions (pick region)
        sample from parameter space
        use polar coordinates
        loop through each region chain output in given state in paralell
            pick parameters that produce ordinally different response
                are there new ordinal responses:
                    yes: define regions around new parameters
                    no: sample convolutionally for each region
        check if each parameter has been sampled from their boundaries
        is parameter space filled:
            yes -> then set while condition to false
            no -> then set while condition to true
    }
```

## PSPglobal

Partition Parameter Space according to input parameters.

Sampling method will probably depend on adaptMCMC

## PSPvolume

Calculate volume of polytope partitions as defined by PSPglobal.
Probably will depend on [volesti](https://cran.r-project.org/web/packages/volesti/index.html)

## PSPcontrol

# TODO

1. [v1] what is the stopping criterion?
2. [v1] how do you know that the parameter space is filled up?
3. [v2] parellelization
4. [!H] replicate figure 5 plus table 1
