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
cube OrdinalCompare(cube discovered, cube predicted) {
  cube drawer(discovered);
  mat index(predicted.n_slices, discovered.n_slices);
  // carry out the comparisons
  for (int x = 0; x < predicted.n_slices; x++) {
    mat current = predicted.slice(x);
    for (int y = 0; y < discovered.n_slices; y++) {
      mat base = discovered.slice(y);
      umat result = (base == current);
      index(x, y) =  all(any(result == 0));
    }
    if (all(index.row(x) == 1)) {
      cube update = join_slices(drawer, current);
      drawer = update;
    }
  }
  return(drawer);
}

// returns the last evaluated parameters in all chains in the MCMC
mat LastEvaluatedParameters(cube discovered, cube predicted, mat jumping, mat centers) {
  mat parameters(centers);
  mat index(predicted.n_slices, discovered.n_slices);
  // create index matrix
  for (uword x = 0; x < predicted.n_slices; x++) {
    mat current = predicted.slice(x);
    for (uword y = 0; y < discovered.n_slices; y++) {
      mat base = discovered.slice(y);
      umat result = (base == current);
      index(x, y) =  all(any(result == 0));
    }
    if (all(index.row(x) == 1)) {
      //  if there is a new region, appeng params to centers
      parameters.insert_rows(parameters.n_rows, jumping.row(x));
    } else if (any(index.row(x) == 0)) {
      // if there is an old region in predicted, update center
      parameters.rows(find(index.row(x) == 0, 1, "last")) = jumping.row(x);
    }
    // replace old centers with new ones
  }
  return(parameters);
}

// count ordinal patterns
rowvec CountOrdinal(cube updated_ordinal, cube predicted, rowvec counts) {
  mat index(updated_ordinal.n_slices, predicted.n_slices);
  rowvec new_counts = counts;
  new_counts.resize(updated_ordinal.n_slices);
  Rcout <<  new_counts << std::endl;
  for (int x = 0; x < updated_ordinal.n_slices; x++) {
    mat current = updated_ordinal.slice(x);
    for (int y = 0; y < predicted.n_slices; y++) {
      mat base = predicted.slice(y);
      umat result = (base == current);
      index(x, y) =  all(any(result == 0));
    }
    if (!all(index.row(x) == 1)) {
      new_counts[x] += 1;
    }
  }
  return(new_counts);
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
               std::string path = ".", bool quiet = false) {
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

  colvec lower = as<colvec>(control["lower"]);
  colvec upper = as<colvec>(control["upper"]);
  int dimension = init.n_elem;
  // do some basic error checks
  if (dimension != lower.n_elem || dimension != upper.n_elem {
    stop("init, lower and upper must have the same length.");
  }
  mat jumping_distribution(init); // the parameter sets to be evaluated
  mat last_eval(init); // the last evaluated parameter set for each ordinal pattern
  rowvec counts; // keeps track of the population of ordinal regions
  cube ordinal; // stores all evaluations of fn on jumping_distribution
  cube storage; //  stores all unique ordinal patterns

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
  int stimuli = output.n_rows;
  // add output to storage
  storage = join_slices(storage, output)
  delete[] output;

  // run parameter space partitioning until parameter is filled
  while (parameter_filled) {
    // update iteration
    iteration += 1;

    // generate new jumping distributions from ordinal patterns with counts < population
    jumping_distribution = HyperPoints(last_eval.n_rows, dimensions, radius);
    jumping_distribution = ClampParameters(jumping_distribution, lower, upper);
    jumping_distribution += last_evaluated;

    cube ordinal(stimuli, stimuli, jumping_distribution.n_rows);
    // evaluate jumping distributions
    for (uword i = 0; i < jumping_distribution.n_rows; i++) {
      mat evaluate = model(jumping_distribution.row(i));
      ordinal.slice(i) = evaluate;
    }
    // compare ordinal patterns to stored ones and update list
    last_eval = LastEvaluatedParameters(storage, ordinal, jumping_distribution, last_eval);
    storage = OrdinalCompare(storage, ordinal);
    // update counts of ordinal patterns
    counts = CountOrdinal(storage, ordinal, counts);
    // write data to disk
    outFile << "\n";

    // print information about iteration
    if (!quiet) {
      Rcout << "Iteration:" << iteration << std::endl;
    }
    // check if parameter_filled threshold is reached
    if (iteration == threshold || all(counts > population)) {
      parameter_filled = TRUE
    }
  }


  out = Rcpp::List::create(
    Rcpp::Named("ordinal_counts") = counts,
    Rcpp::Named("ordinal_patterns") = storage);

  // compile output including ordinal patterns and their frequencies
  return(out)
}
