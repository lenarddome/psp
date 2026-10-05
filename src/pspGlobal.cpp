// Copyright 2022 <Lenard Dome> [legal/copyright]
// [[Rcpp::depends(RcppArmadillo)]]
#include <RcppArmadillo.h>
#include <charconv>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <limits>
#include <string>
#include <unordered_map>
#include <vector>

// std::to_chars for doubles needs libstdc++ 11 or libc++ on macOS 13.3 and later
#if defined(_LIBCPP_VERSION)
#if defined(_LIBCPP_AVAILABILITY_HAS_TO_CHARS_FLOATING_POINT) && \
    _LIBCPP_AVAILABILITY_HAS_TO_CHARS_FLOATING_POINT
#define PSP_HAS_TO_CHARS 1
#endif
#elif defined(__cpp_lib_to_chars)
#define PSP_HAS_TO_CHARS 1
#endif

using namespace Rcpp;
using namespace arma;

// utility functions
// Weisstein, Eric W. "Hypersphere Point Picking." From MathWorld.
// https://mathworld.wolfram.com/HyperspherePointPicking.html
// pick new jumping distributions from the unit hypersphere scaled by the radius
mat HyperPoints(int counts, int dimensions, double radius)
{
  // create a uniform distribution
  mat hypersphere = randn(counts, dimensions, distr_param(0, 1));
  colvec denominator = sum(square(hypersphere), 1);
  denominator = 1 / sqrt(denominator);
  // pick points from within unite hypersphere
  hypersphere = hypersphere.each_col() % denominator;
  // scale up values by r
  rowvec rad = randu<rowvec>(dimensions, distr_param(0.0, radius));
  hypersphere = hypersphere.each_row() % rad;
  return (hypersphere);
}

// constrain new jumping distributions within given parameter bounds
void ClampParameters(mat &jumping_distribution, const colvec &lower, const colvec &upper)
{
  for (uword i = 0; i < upper.n_elem; i++)
  {
    jumping_distribution.col(i).clamp(lower[i], upper[i]);
  }
}

// everything the evaluation loop reads and writes; plain data only, because an
// R error inside the loop jumps straight out of it without running destructors
struct EvaluationBatch
{
  SEXP model;
  SEXP discretize;
  const double *jumping; // rows x dimensions, column-major
  int rows;
  int dimensions;
  int responses;
  int dimensionality;
  double *continuous; // rows x responses, column-major
  double *ordinal;    // dimensionality x dimensionality x rows
};

// evaluates model and discretize on every row of the batch
// runs inside a single Rcpp::unwindProtect instead of one per R call,
// because every protected call costs a setjmp, which is a syscall on macOS
SEXP EvaluateBatch(void *data)
{
  const EvaluationBatch *batch = static_cast<EvaluationBatch *>(data);
  const int cells = batch->dimensionality * batch->dimensionality;
  SEXP model_call = PROTECT(Rf_lang2(batch->model, R_NilValue));
  SEXP discretize_call = PROTECT(Rf_lang2(batch->discretize, R_NilValue));
  for (int i = 0; i < batch->rows; i++)
  {
    SEXP parameters = PROTECT(Rf_allocVector(REALSXP, batch->dimensions));
    for (int k = 0; k < batch->dimensions; k++)
    {
      REAL(parameters)[k] = batch->jumping[i + k * batch->rows];
    }
    SETCADR(model_call, parameters);
    SEXP responses = PROTECT(Rf_eval(model_call, R_GlobalEnv));
    if (!Rf_isNumeric(responses))
    {
      Rf_error("model must return a numeric vector, not %s",
               Rf_type2char(TYPEOF(responses)));
    }
    if (Rf_xlength(responses) != batch->responses)
    {
      Rf_error("model returned %d values, but control$responses is %d",
               (int)Rf_xlength(responses), batch->responses);
    }
    responses = PROTECT(Rf_coerceVector(responses, REALSXP));
    for (int k = 0; k < batch->responses; k++)
    {
      batch->continuous[i + k * batch->rows] = REAL(responses)[k];
    }

    SETCADR(discretize_call, responses);
    SEXP pattern = PROTECT(Rf_eval(discretize_call, R_GlobalEnv));
    if (!Rf_isMatrix(pattern) || !Rf_isNumeric(pattern))
    {
      Rf_error("discretize must return a numeric matrix");
    }
    if (Rf_nrows(pattern) != batch->dimensionality ||
        Rf_ncols(pattern) != batch->dimensionality)
    {
      Rf_error("discretize returned a %d x %d matrix, but control$dimensionality is %d",
               Rf_nrows(pattern), Rf_ncols(pattern), batch->dimensionality);
    }
    pattern = PROTECT(Rf_coerceVector(pattern, REALSXP));
    std::memcpy(batch->ordinal + (R_xlen_t)i * cells, REAL(pattern), cells * sizeof(double));
    UNPROTECT(5);
  }
  UNPROTECT(2);
  return (R_NilValue);
}

// hash key of an ordinal matrix: two matrices share a key if they are identical,
// with -0 folded into 0 and every NaN folded into the same NaN
std::string PatternKey(const mat &pattern)
{
  std::string key(pattern.n_elem * sizeof(double), '\0');
  double *out = reinterpret_cast<double *>(&key[0]);
  for (uword i = 0; i < pattern.n_elem; i++)
  {
    out[i] = std::isnan(pattern[i]) ? std::numeric_limits<double>::quiet_NaN()
                                    : pattern[i] + 0.0;
  }
  return (key);
}

// all discovered ordinal patterns with their populations and the last
// parameters that produced them (the centres of the next jumping distributions)
struct PatternStore
{
  std::unordered_map<std::string, uword> index;
  std::vector<mat> patterns;
  std::vector<double> counts;
  std::vector<rowvec> centres;

  // registers every evaluation and returns the pattern id of each one
  uvec Update(const cube &ordinal, const mat &jumping)
  {
    uvec ids(ordinal.n_slices);
    for (uword i = 0; i < ordinal.n_slices; i++)
    {
      const mat &current = ordinal.slice(i);
      auto found = index.emplace(PatternKey(current), patterns.size());
      uword id = found.first->second;
      if (found.second)
      {
        patterns.push_back(current);
        counts.push_back(0);
        centres.push_back(jumping.row(i));
      }
      counts[id] += 1;
      centres[id] = jumping.row(i);
      ids(i) = id;
    }
    return (ids);
  }

  uvec Underpopulated(double population) const
  {
    std::vector<uword> out;
    for (uword k = 0; k < counts.size(); k++)
    {
      if (counts[k] < population)
        out.push_back(k);
    }
    return (conv_to<uvec>::from(out));
  }

  mat Centres(const uvec &which) const
  {
    mat out(which.n_elem, centres[0].n_elem);
    for (uword i = 0; i < which.n_elem; i++)
    {
      out.row(i) = centres[which(i)];
    }
    return (out);
  }

  cube Patterns() const
  {
    cube out(patterns[0].n_rows, patterns[0].n_cols, patterns.size());
    for (uword k = 0; k < patterns.size(); k++)
    {
      out.slice(k) = patterns[k];
    }
    return (out);
  }
};

// writes the shortest text that reads back as exactly the same double
// and returns the end of the written text; out needs room for 32 characters
char *FormatDouble(char *out, double value)
{
#ifdef PSP_HAS_TO_CHARS
  return (std::to_chars(out, out + 32, value).ptr);
#else
  return (out + std::snprintf(out, 32, "%.17g", value));
#endif
}

// create local csv file for storing coordinates
void CreateFile(std::ofstream &outFile, CharacterVector names, std::string path_to_file)
{
  outFile.open(path_to_file.c_str());
  outFile << "iteration,";
  for (R_xlen_t i = 0; i < names.size(); i++)
  {
    outFile << names[i] << ",";
  }
  outFile << "pattern,\n";
}

// writes rows to csv file
void WriteFile(std::ofstream &outFile, int iteration, const mat &evaluation, const uvec &ids)
{
  // each row is formatted into one buffer and written in a single call
  std::vector<char> line((evaluation.n_cols + 2) * 32);
  for (uword i = 0; i < evaluation.n_rows; i++)
  {
    char *end = line.data();
    end += std::snprintf(end, 32, "%d,", iteration);
    for (uword k = 0; k < evaluation.n_cols; k++)
    {
      end = FormatDouble(end, evaluation(i, k));
      *end++ = ',';
    }
    // add one as c++ starts from 0
    end += std::snprintf(end, 32, "%u,\n", (unsigned int)ids(i) + 1);
    outFile.write(line.data(), end - line.data());
  }
}

// [[Rcpp::export]]
List pspGlobal(Function model, Function discretize, List control, bool save = false,
               std::string path = ".", std::string extension = ".csv", bool quiet = false)
{
  // setup environment
  bool parameter_filled = false;
  int iteration = 0;

  // import thresholds from control
  int max_iteration = as<int>(control["iterations"]);
  int population = as<int>(control["population"]);

  const int kIntMax = std::numeric_limits<int>::max();
  const bool iteration_unbounded = (max_iteration == 0);
  const bool population_unbounded = (population == 0);

  if (iteration_unbounded && population_unbounded)
  {
    stop("A resonable threshold must be set by either adjusting iteration or population.");
  }

  if (iteration_unbounded)
  {
    max_iteration = kIntMax;
  }

  if (population_unbounded)
  {
    population = kIntMax;
  }

  double radius = as<double>(control["radius"]);
  mat init = as<mat>(control["init"]);

  colvec lower = as<colvec>(control["lower"]);
  colvec upper = as<colvec>(control["upper"]);
  int dimensions = init.n_cols;
  // do some basic error checks
  if (dimensions != (int)lower.n_elem || dimensions != (int)upper.n_elem)
  {
    stop("init, lower and upper must have the same length.");
  }
  int dimensionality = as<int>(control["dimensionality"]);
  int response_length = as<int>(control["responses"]);
  CharacterVector parameter_names = as<CharacterVector>(control["parameter_names"]);
  if (parameter_names.size() != dimensions)
  {
    stop("Length of param_names must equal to the number of dimensions");
  }
  CharacterVector stimuli_names = as<CharacterVector>(control["stimuli_names"]);

  // seed has to be set at the global R level
  // see Documentation about the sampling
  Rcpp::Environment base_env("package:base");
  Rcpp::Function set_seed_r = base_env["set.seed"];

  PatternStore store;
  cube ordinal;
  mat continuous;

  // evaluate jumping distributions
  auto evaluate = [&](const mat &jumping) {
    ordinal.set_size(dimensionality, dimensionality, jumping.n_rows);
    continuous.set_size(jumping.n_rows, response_length);
    EvaluationBatch batch = {model, discretize, jumping.memptr(),
                             (int)jumping.n_rows, dimensions, response_length,
                             dimensionality, continuous.memptr(), ordinal.memptr()};
    Rcpp::unwindProtect(&EvaluateBatch, &batch);
  };

  // evaluate first parameter sets
  mat jumping_distribution = init;
  evaluate(jumping_distribution);
  uvec match = store.Update(ordinal, jumping_distribution);
  uvec underpopulated = store.Underpopulated(population);

  std::ofstream parameters_file, continuous_file;
  if (save)
  {
    CreateFile(parameters_file, parameter_names, path + "_parameters" + extension);
    CreateFile(continuous_file, stimuli_names, path + "_continuous" + extension);
    WriteFile(parameters_file, 0, jumping_distribution, match);
    WriteFile(continuous_file, 0, continuous, match);
  }

  // run parameter space partitioning until parameter is filled
  while (!parameter_filled && underpopulated.n_elem > 0)
  {
    // update iteration
    iteration += 1;

    if (!quiet)
    {
      Rprintf("Iteration: [%i]\n", iteration);
    }

    // reset the seed
    int pool = as<int>(Rcpp::sample(10000000, 1));
    set_seed_r(pool);

    // generate new jumping distributions from ordinal patterns with counts < population
    jumping_distribution = HyperPoints(underpopulated.n_elem, dimensions, radius) +
                           store.Centres(underpopulated);
    ClampParameters(jumping_distribution, lower, upper);
    evaluate(jumping_distribution);

    // update ordinal patterns, their counts and centres
    match = store.Update(ordinal, jumping_distribution);
    underpopulated = store.Underpopulated(population);

    // write data to disk
    if (save)
    {
      WriteFile(parameters_file, iteration, jumping_distribution, match);
      WriteFile(continuous_file, iteration, continuous, match);
    }

    // check if either of the parameter_filled thresholds is reached
    if (iteration == max_iteration || underpopulated.n_elem == 0)
    {
      parameter_filled = true;
    }
  }

  // compile output including ordinal patterns and their frequencies
  return (Rcpp::List::create(
      Rcpp::Named("ordinal_patterns") = store.Patterns(),
      Rcpp::Named("ordinal_counts") = rowvec(store.counts),
      Rcpp::Named("iterations") = iteration));
}
