# Pipeline for estimating Re in Switzerland

This pipeline processes linelist data, as gathered by the FOPH, and computes the reproductive number through time for Switzerland,
its cantons and greater regions, based on the incidence of case confirmations.
It relies on the `estimateR` package for computations.

## Installation
`estimateR` must be installed from GitHub with the R command (requires the devtools package):
`devtools::install_github("covid-19-Re/estimateR")`

## Use
The file `scripts/pipe/run_swiss_estimates.sh` runs the entire pipeline.
It assumes that the latest linelist data of interest is in the `data/raw/BAG` folder.
The folder paths can be modified easily in the various R scripts (usually at the very top of the script),
and in the `run_swiss_estimates.sh` script.

By default, results are stored in `data/results/aggregated`.

## Tip
The time required to execute all steps can be drastically reduced by parallelizing the Re calculation steps in
that script.
Each step in the for-loop in `run_swiss_estimates.sh` corresponds to the Re estimation on a particular region.
Different computing nodes can work in parallel on different regions to execute the code faster,
instead of doing them all in succession on a single computing node.
