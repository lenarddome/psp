// Copyright 2022 <Lenard Dome> [legal/copyright]
// [[Rcpp::depends(RcppArmadillo)]]
#include <RcppArmadillo.h>
#include <fstream>

// [[Rcpp::depends(RcppArmadillo)]]
using namespace Rcpp;
using namespace arma;

// utility functions
// Weisstein, Eric W. "Hypersphere Point Picking." From MathWorld.
// https://mathworld.wolfram.com/HyperspherePointPicking.html
// pick new jumping distributions from the unit hypersphere scaled by the radius
mat HyperPoints(int counts, int dimensions, rowvec radius) {
  mat hypersphere;
  // create a uniform distribution
  hypersphere.randu(counts, dimensions);
  colvec denominator = sum(hypersphere, 1);
  denominator = 1 / denominator;
  // pick points from within unite hypersphere
  hypersphere = hypersphere.each_col() % denominator;
  // scale up values by r
  hypersphere = hypersphere.each_row() % radius;
  return(hypersphere);
}

// constrain new jumping distributions within given parameter bounds
mat ClampParameters(mat jumping_distribution, colvec lower, colvec upper) {
  for (int i = 0; i < upper.n_elem; i++) {
    jumping_distribution.col(i).clamp(lower[i], upper[i]);
  }
  return(jumping_distribution);
}

// compare two cubes of inequality matrices
// returns the complete list of unique ordinal matrices
// [[Rcpp::export]]
cube OrdinalCompare(cube discovered, cube predicted) {
  cube ordinal(discovered);
  // carry out the comparisons
  for (int x = 0; x < predicted.n_slices; x++) {
    mat current = predicted.slice(x);
    for (int y = 0; y < discovered.size(); y++) {
      if (current != discovered.slice(y)) {
        ordinal.insert_slices(ordinal.n_slices, current);
      }
    }
  }
  return(ordinal);
}

// count ordinal patterns
// if ordinal pattern is output TRUE from .OrdinalStorage
// add 1 to its count
rowvec CountOrdinal(cube discovered, cube predicted, vec counts) {
}

// writes rows to csv file
void WriteFile(int iteration, mat evaluation, int dimension,
  std::string path_to_file) {
  // open file stream connection
  std::ofstream outFile(path_to_file.c_str());
  int rows = evaluation.n_rows;
  int columns = dimension + 1;
  for (uword i = 0; i < rows; i++) {
    outFile << i + ",";
    for (uword k = 0; k < columns; k++) {
      outFile << evaluation[i, k] + ",";
    }
    outFile << "\n";
  }
  // close file connection
  outFile.close();
}

// [[Rcpp::export]]
List pspGlobal(std::string fn, List control, std::string filename,
               std::string path, bool quiet = false) {
  // call the ordinal function used for evaluation parameters
  try {
    Environment env = Environment::global_env();
    Function model = env[fn];
  }

  catch (...) {
    Rcout << "ERROR: ordinal function " << fn << " need to be loaded into global_env" << std::endl;
  }

  // setup environment

  bool parameter_filled = false;
  int iteration = 0;

  int max_iteration = as<int>(control["iterations"]);
  if (!max_iteration) {
    max_iteration = datum::inf;
  }

  int population = as<int>(control["population"]);
  if (!population) {
    population =  datum::inf;
  }

  if (population == datum::inf && max_iteration == datum::inf) {
    stop("A resonable threshold must be set by either adjusting iteration or population.")
  }

  rowvec radius  = as<colvec>(control["radius"]);
  rowvec  init = as<colvec>(control["init"]);
  mat jumping_distribution(init);
  colvec lower = as<colvec>(control["lower"]);
  colvec upper = as<colvec>(control["upper"]);
  int dimension = init.n_elem;
  // do some basic error checks
  if (dimension != lower.n_elem || dimension != upper.n_elem {
    stop("init, lower and upper must have the same length.");
  }

  mat output;
  rowvec counts;
  cube ordinal;
  cube storage;

  CharacterVector names = as<CharacterVector>(control["param_names"]);

  List out;

  // setup file and create headers
  std::ofstream outFile(path + filename);
  outFile << "iteration,";
  for (uword i = 0; i < dimensions; i++) {
    outFile << names[i] + ",";
  }
  outFile << names + ",pattern\n";
  // close file connection
  outFile.close();

  // evaluate first parameter set
  mat output = model(init);
  ordinal.insert_slices(0, output);
  // add output to storage
  storage.insert_slices(output);
  delete[] output;

  while (parameter_filled) {
    // update iteration
    iteration += 1;

    // generate new jumping distributions from ordinal patterns with counts < population
    jumping_distribution = HyperPoints(jumping_distribution.n_rows, dimensions, radius);
    jumping_distribution = ClampParameters(jumping_distribution, lower, upper);

    // evaluate jumping distributions
    for (uword i = 0; i < jumping_distribution.n_rows; i++) {
      mat evaluate = model(jumping_distribution.row(i));
      ordinal.slice(i) = evaluate;
    }
    // compare ordinal patterns to stored ones
    // update list of ordinal patterns
    if (!new) {
      /* code here */
    }
    // update counts of ordinal patterns
    // write data to disk
    outFile << "\n";

    // print information about iteration
    if (!quiet) {
      Rcout << "Iteration:" << iteration << std::endl;
    }
  }


  out = Rcpp::List::create(
    Rcpp::Named("ordinal_counts") = counts,
    Rcpp::Named("ordinal_patterns") = storage);

  // compile output including ordinal patterns and their frequencies
  return(out)
}
