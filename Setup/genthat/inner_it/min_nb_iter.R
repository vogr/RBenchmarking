#!/usr/bin/env Rscript

# The loop should take at least MIN_LOOP_TIME and iterate
# at least MIN_INNER_IT times. This is to make sure that the loop
# takes long enough to be measured by rebench, and that the warmup
# happens in the first outer-iteration, no matter how long the
# inner-iteration is.


# Note: we are voluntarily avoiding isolation in this script to make
# the process faster. With isolated runs, the library would need to
# be source()-d for every script, triggering compilations.
# Without isolation, the compiled versions of the functions are
# kept between runs, making the warmup process much faster.
# Ideally, the hot iteration time should not be very different.

MIN_LOOP_TIME = 200 #ms
MIN_INNER_IT = 10

argv <- commandArgs(trailingOnly=TRUE)

if (length(argv) != 1) {
  cat("min_nb_iter.R <benchmark_dir.R>\n")
  cat("\n")
  stop("Incorrect number of arguments")
}

BENCHMARK_DIR <- normalizePath(argv[[1]])

required_iterations_for <- function(benchmark) {

  env <- new.env(parent=globalenv())
  env$benchmark <- benchmark

  message("Processing ", benchmark)
  
  capture.output(
    with(env, {
      source(benchmark)
      # Warmup
      for (i in 1:MIN_INNER_IT) {
        function_to_run()
      }

      # Count number of required interations
      n_it <- 0
      t0 <- Sys.time()

      for (i in 1:MIN_INNER_IT) {
        function_to_run()
        n_it <- n_it + 1
      }
      while ( (Sys.time() - t0) * 1000 < MIN_LOOP_TIME) {
        function_to_run()
        n_it <- n_it + 1
      }
    })
  )

  env$n_it
}

benchmarks <- list.files(BENCHMARK_DIR, "*.R", recursive=TRUE)

# Running the testfiles can create files.
setwd(tempdir())

for (b in benchmarks) {
  try({
    n_it <- required_iterations_for(file.path(BENCHMARK_DIR, b))
    cat(paste0(b, ",", n_it,"\n"))
  })
}
