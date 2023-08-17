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
mat HyperPoints(int counts, int dimensions, double radius) {
  // create a uniform distribution
  mat hypersphere = randn(counts, dimensions, distr_param(0, 1) );
  colvec denominator = sum(square(hypersphere), 1);
  denominator = 1 / sqrt(denominator);
  // pick points from within unite hypersphere
  hypersphere = hypersphere.each_col() % denominator;
  // scale up values by r
  rowvec rad = randu<rowvec>(dimensions, distr_param(0.0, radius));
  hypersphere = hypersphere.each_row() % rad;
  return(hypersphere);
}

// constrain new jumping distributions within given parameter bounds
mat ClampParameters(mat jumping_distribution, colvec lower, colvec upper) {
  for (int i = 0; i < upper.n_elem; i++) {
    jumping_distribution.col(i).clamp(lower[i], upper[i]);
  }
  return(jumping_distribution);
}

// returns the unique slices of a cube (a 3D array) 
uvec FindUniqueSlices(cube predictions) {
  vec predictions_filter(predictions.n_slices, fill::zeros);
  // filter the same predictions
  for (uword x = 0; x < predictions.n_slices; x++) {
    vec current = vectorise( predictions.slice(x) );
    for (uword y = x + 1; y < predictions.n_slices; y++) {
      vec base = vectorise( predictions.slice(y) );
      uvec result = (base == current);
      if (all(result == 1)) predictions_filter(x) += 1;
    }
  }
  // remove multiple predictions for the comparisons
  uvec inclusion = find( predictions_filter == 0 );
  return(inclusion);
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
      index(x, y) =  any(vectorise(result) == 0);
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
  mat index(discovered.n_slices, predicted.n_slices);
  // create index matrix
  for (uword x = 0; x < discovered.n_slices; x++) {
    mat current = discovered.slice(x);
    for (uword y = 0; y < predicted.n_slices; y++) {
      mat base = predicted.slice(y);
      umat result = (base == current);
      index(x, y) =  any(vectorise(result) == 0);
    }
    if (all(index.row(x))) {
      //  if there is a new region, appeng params to centers
      parameters.insert_rows(parameters.n_rows, jumping.rows( find(index.row(x) == 1, 1, "last") ));
    } else {
      // if there is an old region in predicted, update center
      parameters.row(x) = jumping.rows( find(index.row(x) == 0, 1, "last") );
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
  for (uword x = 0; x < updated_ordinal.n_slices; x++) {
    mat current = updated_ordinal.slice(x);
    for (uword y = 0; y < predicted.n_slices; y++) {
      mat base = predicted.slice(y);
      umat result = (base == current);
      if (all(vectorise(result) == 1)) {
        new_counts[x] += 1;
      }
    }
  }
  return(new_counts);
}

// match jumping distributions to ordinal ordinal_patterns
// returns a column uvec of slice IDs corresponding to each set in jumping_distribution
vec MatchJumpDists(cube updated_ordinal, cube predicted) {
  mat index(updated_ordinal.n_slices, predicted.n_slices);
  vec matches(predicted.n_slices);
  for (uword x = 0; x < updated_ordinal.n_slices; x++) {
    mat current = updated_ordinal.slice(x);
    for (uword y = 0; y < predicted.n_slices; y++) {
      mat base = predicted.slice(y);
      umat result = (base == current);
      if (all(vectorise(result) == 1)) {
        matches(y) = x;
      }
    }
  }
  return(matches + 1); // add one as c++ starts from 0
}

// create local csv file for storing coordinates
void CreateFile(CharacterVector names, std::string path_to_file) {
  std::ofstream outFile(path_to_file.c_str());
  outFile << "iteration,";
  for (uword i = 0; i < names.size(); i++) {
    outFile << names[i];
    outFile << + ",";
  }
  outFile << "pattern,\n";
}

// writes rows to csv file
void WriteFile(int iteration, mat evaluation, vec matches,
  std::string path_to_file) {
  // open file stream connection
  std::ofstream outFile(path_to_file.c_str(), std::ios::app);
  int rows = evaluation.n_rows;
  int columns = evaluation.n_cols;
  for (uword i = 0; i < rows; i++) {
    outFile << iteration;
    outFile << ",";
    for (uword k = 0; k < columns; k++) {
      outFile << evaluation(i, k);
      outFile << ",";
    }
    outFile << matches(i);
    outFile << ",\n";
  }
}

// [[Rcpp::export]]
List pspGlobal(Function model, Function discretize, List control, bool save = false,
               std::string path = ".", std::string extension = ".csv", bool quiet = false) {
  // setup environment
  bool parameter_filled = false;
  int iteration = 0;
  uvec underpopulated = { 0 };

  // import thresholds from control
  int max_iteration = as<int>(control["iterations"]);
  int population = as<int>(control["population"]);

  if (!max_iteration) {
    max_iteration = datum::inf;
  }

  if (!population) {
    population =  datum::inf;
  }

  if (population == datum::inf && max_iteration == datum::inf) {
    stop("A resonable threshold must be set by either adjusting iteration or population.");
  }

  double radius  = as<double>(control["radius"]);
  mat init = as<mat>(control["init"]);

  colvec lower = as<colvec>(control["lower"]);
  colvec upper = as<colvec>(control["upper"]);
  int dimensions = init.n_cols;
  // do some basic error checks
  if (dimensions != lower.n_elem || dimensions != upper.n_elem) {
    stop("init, lower and upper must have the same length.");
  }
  int dimensionality = as<int>(control["dimensionality"]);
  int response_length = as<int>(control["responses"]);
  rowvec counts(1, fill::ones);  // keeps track of the population of ordinal regions
  cube filtered; // stores all unique predictions
  cube storage;  //  stores all unique ordinal patterns
  CharacterVector parameter_names = as<CharacterVector>(control["parameter_names"]);
  if (parameter_names.size() != dimensions) {
    stop("Length of param_names must equal to the number of dimensions");
  }
  CharacterVector stimuli_names = as<CharacterVector>(control["stimuli_names"]);
  List out;

  // seed has to be set at the global R level
  // see Documentation about the sampling
  Rcpp::Environment base_env("package:base");
  Rcpp::Function set_seed_r = base_env["set.seed"];

  // evaluate first parameter sets
  mat last_eval = init;
  mat jumping_distribution = init;
  mat continuous(jumping_distribution.n_rows, response_length);


  // create first ordinal storage
  cube ordinal(dimensionality, dimensionality, jumping_distribution.n_rows);


  // evaluate jumping distributions
  for (uword i = 0; i < jumping_distribution.n_rows; i++) {
    NumericVector probabilities = model(jumping_distribution.row(i));
    NumericMatrix teatime = discretize(probabilities);
    const rowvec& responses = as<rowvec>(probabilities);
    continuous.row(i) = responses;
    const mat& evaluate = as<mat>(teatime);
    ordinal.slice(i) = evaluate;
  }

  // compare ordinal patterns to stored ones and update list
  uvec include = FindUniqueSlices(ordinal);

  // update last evaluated parameters
  last_eval = LastEvaluatedParameters(storage, ordinal.slices(include),
                                      jumping_distribution.rows(include),
                                      last_eval);

  storage = OrdinalCompare(storage, ordinal.slices(include));
  counts = CountOrdinal(storage, ordinal, counts);

  ////////////////////////////////////////////////////////////////

  if (save) {
    vec match = MatchJumpDists(storage, ordinal);
    CreateFile(parameter_names, path + "_parameters" + extension);
    CreateFile(stimuli_names, path + "_continuous" + extension);
    WriteFile(0, jumping_distribution, match, path + "_parameters" + extension);
    WriteFile(0, continuous, match, path + "_continuous" + extension);
  }

  // run parameter space partitioning until parameter is filled
  while (!parameter_filled) {
    // update iteration
    iteration += 1;

    if (!quiet) {
      Rprintf("Iteration: [%i]\n", iteration);
    }

    // reset the seed
    int pool =  as<int>(Rcpp::sample(10000000, 1));
    set_seed_r(pool); 

    // generate new jumping distributions from ordinal patterns with counts < population
    mat jumping_distribution = HyperPoints(underpopulated.n_elem,
                                           dimensions, radius);
    jumping_distribution = jumping_distribution + last_eval.rows(underpopulated);
    jumping_distribution = ClampParameters(jumping_distribution, lower, upper);
    // allocate cube for ordinal predictions
    ordinal.resize(dimensionality, dimensionality, jumping_distribution.n_rows);
    continuous.resize(jumping_distribution.n_rows, response_length);

    // evaluate jumping distributions
    for (uword i = 0; i < jumping_distribution.n_rows; i++) {
      NumericVector probabilities = model(jumping_distribution.row(i));
      NumericMatrix teatime = discretize(probabilities);
      const rowvec& responses = as<rowvec>(probabilities);
      continuous.row(i) = responses;
      const mat& evaluate = as<mat>(teatime);
      ordinal.slice(i) = evaluate;
    }

    // compare ordinal patterns to stored ones and update list
    uvec include = FindUniqueSlices(ordinal);

    // update last evaluated parameters
    last_eval = LastEvaluatedParameters(storage, ordinal.slices(include),
                                        jumping_distribution.rows(include),
                                        last_eval);

    storage = OrdinalCompare(storage, ordinal.slices(include));

    // update counts of ordinal patterns
    counts = CountOrdinal(storage, ordinal, counts);
    underpopulated = find( counts < population );

    // write data to disk
    if (save) {
      // index locations of currently found patterns in storage
      vec match = MatchJumpDists(storage, ordinal);
      WriteFile(iteration, jumping_distribution, match, path + "_parameters" + extension);
      WriteFile(iteration, continuous, match, path + "_continuous" + extension);
    }

    // check if either of the parameter_filled thresholds is reached
    if (iteration == max_iteration || underpopulated.n_elem == 0) {
      parameter_filled = TRUE;
    }
  }

  // compile output including ordinal patterns and their frequencies
  out = Rcpp::List::create(
    Rcpp::Named("ordinal_patterns") = storage,
    Rcpp::Named("ordinal_counts") = counts,
    Rcpp::Named("iterations") = iteration);

  return(out);
}
