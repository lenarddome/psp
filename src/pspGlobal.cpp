// [[Rcpp::depends(RcppArmadillo)]]
#include <RcppArmadillo.h>

// [[Rcpp::depends(RcppArmadillo)]]
using namespace Rcpp;
using namespace arma;

// utility functions
// Weisstein, Eric W. "Hypersphere Point Picking." From MathWorld.
// https://mathworld.wolfram.com/HyperspherePointPicking.html
// pick new jumping distributions from within the unit hypersphere scaled by the radius
mat .HyperPoints(mat jumping_distribution, colvec radius) {
}

// constrain new jumping distributions within given parameter bounds
mat .ClampParameters() {
}

// compare two inequality matrices
vec .OrdinalCompare() {
}

// store ordinal patterns in lists
List .OrdinalStorage() {
}

// count ordinal patterns
vec .CountOrdinal() {
}

// pspControl does a bunch of error catching and manipulations to set up
// the environment for pspGlobal.
// [[Rcpp::export]]
List pspControl(List control) {

}

// [[Rcpp::export]]
List pspGlobal(std::string fn, List control, std::string filename,
               std::string path, bool load = false, bool quiet = false) {

  // call the ordinal function used for evaluation parameters
  // TODO: error catching is important here
  try {
    Environment env = Environment::global_env();
    Function model = env[fn];
  } 

  catch (...) {
    Rcout << "ERROR: ordinal function fn need to be loaded into global_env" << std::endl;
  }

  // setup environment
  List control_setup = pspControl(control);

  bool parameter_filled = false;
  int iteration = 0;
  int max_iteration = as<int>(setup["iterations"]); 

  // evaluate first parameter set

  while(parameter_filled) {

    // update iteration
    iteration += 1;

    // generate new jumping distributions
    // evaluate jumping distributions
    // compare ordinal patterns to stored ones
    // update list of ordinal patterns
    // update counts of ordinal patterns
    // write data to disk
    // TODO: do this according to https://www.gormanalysis.com/blog/reading-and-writing-csv-files-with-cpp/
    
    // print information about iteration
    if (!quiet) {
      Rcout << "Iteration:" << iteration << std::endl;
    }
  }

  // compile output including ordinal patterns and their frequencies
  return(out)
}
