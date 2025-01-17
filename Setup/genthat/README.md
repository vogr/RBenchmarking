# Extracting the function calls from packages with genthat

## Usage

### Automated, with the container

``` console
# 1. Modifiy packages.txt as wanted

# 2. Create the docker image
docker build -t extract-testcases-img .

# 3. Install the packages inside the container and extract the function calls
#    to /tmp/testcases
mkdir -p /tmp/testcases
docker run --rm --mount type=bind,src=/tmp/testcases,dst=/opt/testcases extract-testcases-img
```

You can now copy the testcases you want to keep inside `Benchmarks/genthat-CRAN/generated`

In the Docker container, the following scripts will be run:

1. install_genthat.R and install_pkgs.R: install genthat, some dependancies and the selected packages in the container, with their source so that they can be analyzed by genthat.
2. extract_testcases.R: create the `.R` files from the packages selected in packages.txt (and exclude the files that fail to run with GNU-R)
3. record_retv.R: run each test once with R with a known random seed, record the return value, and save the seed and the return value to a `.ext` file (also exclude the files that fail to run with GNU-R)
4. check_against_recorded_retv.sh: run the tests with GNU-R using the harness.r file. In that case the R session is restarted between each test (so that the state is not preserved between the different tests), and the function is called several time (so that if the return value also depends on the number of time the function was called, it is excluded).


The files that fail to run with GNU-R can be larger in step 4 than in step 3 and 2: if the package has an internal state, the state will be preserved between the generation of the tests, and some tests will fail with an error if they are run from scratch, when this state is not identical. For instance: for the `prodlim` pkg, genthat generates test files that it can run, but that fail to run on their own because they expect `new.pdf` to have been called in the past.

### Manually, with more control

```
GENTHAT_CRAN="$HOME/genthat-cran"

# Install dependancy and packages
./install_genthat.R
./install_pkgs.R ./packages.txt "$GENTHAT_CRAN/MRAN-lib" "$GENTHAT_CRAN/MRAN-src"

# Extract the testcases
./extract_testcases.R ./packages.txt "$GENTHAT_CRAN/MRAN-lib" "$GENTHAT_CRAN/MRAN-src" "$GENTHAT_CRAN/testcases" 16

# Optionnaly: keep only one test per function
# (OR: do it after `record_retv` to avoid failing testcases, but record_retv
# will be much slower)
./pick_one_testcase.sh "$GENTHAT_CRAN/testcases" "$GENTHAT_CRAN/testcases_selected"

# Record the return values
./record_retv.R "$GENTHAT_CRAN/testcases_selected" 16

# Optionnaly: check if the return value is stable over several iterations
./check_against_recorded_retv.sh "../../Benchmarks/genthat-CRAN/harness.r" "$GENTHAT_CRAN/testcases_selected"

# Optionnaly: count the number of extracted tests
./count_tests.sh "$GENTHAT_CRAN/testcases_selected"
```


Additionnaly, you should run the script in `inner_it/` to set once (and save for future use) the number of time each testcase will be run. It aims to run enough inner_iterations so that each outer_iteration takes 200ms. See the README.md in this directory for details.

## Debugging

You can open a shell inside the container without running the main command using:

```
docker run --rm --mount type=bind,src=/tmp/testcases,dst=/opt/testcases extract-testcases bash

# run the main command inside the container
root@cd742d5ad0ac:/# /opt/setup-scripts/container/run.sh
```

## Reproducibility

Reproducibility is assured by the use of MRAN: the packages are always installed from the same CRAN snapshot,
and the version of R used is fixed (3.6.2).

## TODO:

Unify base image for test extraction and for running the benchmarks: in both it is necessary to install the R
packages. It would make sense to have a common base with R + the CRAN packages installed, instead of installing
the packages independently in both containers.
